/*
 * Kobold2D™ --- http://www.kobold2d.org
 *
 * Copyright (c) 2010-2011 Steffen Itterheim.
 * Released under MIT License in Germany (LICENSE-Kobold2D.txt).
 */

#import "GameLayer.h"
#import "Vehicle.h"
#import "CCSprite+SpriteSize.h"

#define PTM_RATIO 32.0f
#define FLOOR_HEIGHT    50.0f
#define TORQUE_ADJUSTMENT 50
#define MAX_TORQUE 1000

CCSprite *projectile;
CCSprite *block;
CGRect firstrect;
CGRect secondrect;
NSMutableArray *blocks = [[NSMutableArray alloc] init];

// UIKit Gestures
UIRotationGestureRecognizer *rotateGesture;
UIPanGestureRecognizer *threeFingerGesture;


@interface GameLayer (PrivateMethods)
- (void) enableBox2dDebugDrawing;
- (void) addSomeJoinedBodies:(CGPoint)pos;
- (void) addNewSpriteAt:(CGPoint)p;
- (b2Vec2) toMeters:(CGPoint)point;
- (CGPoint) toPixels:(b2Vec2)vec;
@end

@implementation GameLayer

- (id)init
{
    if ((self = [super init]))
    {
        CCLOG(@"%@ init", NSStringFromClass([self class]));
        rotateGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self
                                                                  action:@selector(handleRotateGesture:)];
        threeFingerGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                     action:@selector(handleThreeFingers:)];
        [threeFingerGesture setMinimumNumberOfTouches:3];
        [threeFingerGesture setMaximumNumberOfTouches:3];

        [[[CCDirector sharedDirector] view] addGestureRecognizer:rotateGesture];
        [[[CCDirector sharedDirector] view] addGestureRecognizer:threeFingerGesture];

        // Construct a world object, which will hold and simulate the rigid bodies.
        b2Vec2 gravity = b2Vec2(0.0f, -10.0f);
        world = new b2World(gravity);
        world->SetAllowSleeping(YES);
        //world->SetContinuousPhysics(YES);

        //create an object that will check for collisions
        contactListener = new ContactListener();
        world->SetContactListener(contactListener);

        glClearColor(0.1f, 0.0f, 0.2f, 1.0f);

        CGSize screenSize = [CCDirector sharedDirector].winSize;


        //Raise to floor height
        b2Vec2 lowerLeftCorner =b2Vec2(0,FLOOR_HEIGHT/PTM_RATIO);

        //Raise to floor height, extend to end of game area
        b2Vec2 lowerRightCorner = b2Vec2(screenSize.width * 2.0f / PTM_RATIO, FLOOR_HEIGHT / PTM_RATIO);

        //No change
        b2Vec2 upperLeftCorner = b2Vec2(0,screenSize.height * 2.0f / PTM_RATIO);

        //Extend to end of game area.
        b2Vec2 upperRightCorner =b2Vec2(screenSize.width * 2.0f / PTM_RATIO, screenSize.height * 2.0f / PTM_RATIO);

        // Define the static container body, which will provide the collisions at screen borders.
        b2BodyDef screenBorderDef;
        screenBorderDef.position.Set(0, 0);
        screenBorderBody = world->CreateBody(&screenBorderDef);
        b2EdgeShape screenBorderShape;

        screenBorderShape.Set(lowerLeftCorner, lowerRightCorner);
        screenBorderBody->CreateFixture(&screenBorderShape, 0);
        screenBorderShape.Set(lowerRightCorner, upperRightCorner);
        screenBorderBody->CreateFixture(&screenBorderShape, 0);
        screenBorderShape.Set(upperRightCorner, upperLeftCorner);
        screenBorderBody->CreateFixture(&screenBorderShape, 0);
        screenBorderShape.Set(upperLeftCorner, lowerLeftCorner);
        screenBorderBody->CreateFixture(&screenBorderShape, 0);
        
        // Set up the panning/zooming Layer
        CCSprite *bgSprite = [CCSprite spriteWithFile:@"bgImage.png"];
        self.panZoomLayer = [CCLayerPanZoom node];
        self.panZoomLayer.maxScale = 2.0f;
        self.panZoomLayer.minScale = 1;
        self.panZoomLayer.mode = kCCLayerPanZoomModeSheet;
        bgSprite.anchorPoint = CGPointZero;
        bgSprite.scale = CC_CONTENT_SCALE_FACTOR();
        [self.panZoomLayer addChild:bgSprite z:-1];
        self.panZoomLayer.rubberEffectRatio = 0.3f;
        
        // Set up the content size
        self.panZoomLayer.contentSize = CGSizeMake([bgSprite spriteWidth], [bgSprite spriteHeight]);
        self.panZoomLayer.panBoundsRect = CGRectMake(0, 0, screenSize.width, screenSize.height);
        self.panZoomLayer.anchorPoint = ccp(0, 0);
        self.panZoomLayer.position = ccp(0, 0);

        player1Vehicle = [[Vehicle alloc] initWithName: @"Triceratops" usingImage:@"triceratops.png"];
        [self.panZoomLayer addChild:player1Vehicle z:1 tag:1];

        // Setting the properties of our definition
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        bodyDef.linearDamping = 1;
        bodyDef.angularDamping = 1;
        bodyDef.position.Set(450.0f/PTM_RATIO,(200.0f)/PTM_RATIO);
        bodyDef.linearVelocity = b2Vec2(-5,0);
        bodyDef.angularVelocity = -110;
        bodyDef.userData = (__bridge void*)player1Vehicle; //this tells the Box2D body which sprite to update.

        //create a body with the definition we just created
        player1Body = world->CreateBody(&bodyDef);
        //the -> is C++ syntax; it is like calling an object's methods (the CreateBody "method")

        //Create a fixture for the arm
        b2PolygonShape playerShape;
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &playerShape; //geometric shape
        fixtureDef.density = 0.3F; //affects collision momentum and inertia
        playerShape.SetAsBox([player1Vehicle boundingBox].size.width / 3 / PTM_RATIO, [player1Vehicle boundingBox].size.height / 3 / PTM_RATIO);
        //this is based on the dimensions of the arm which you can get from your image editing software of choice
        player1Fixture = player1Body->CreateFixture(&fixtureDef);

        player2Vehicle = [[Vehicle alloc] initWithName: @"Mammoth" usingImage:@"mammoth.png"];
        [self.panZoomLayer addChild:player2Vehicle z:1 tag:2];
        //causes rotations to slow down. A value of 0 means there is no slowdown
        bodyDef.position.Set(50.0f/PTM_RATIO,(200.0f)/PTM_RATIO);
        bodyDef.linearVelocity = b2Vec2(5,0);
        bodyDef.angularVelocity = 90;
        bodyDef.userData = (__bridge void*)player2Vehicle; //this tells the Box2D body which sprite to update.

        //create a body with the definition we just created
        player2Body = world->CreateBody(&bodyDef);
        //the -> is C++ syntax; it is like calling an object's methods (the CreateBody "method")

        fixtureDef.shape = &playerShape; //geometric shape
        fixtureDef.density = 0.3F; //affects collision momentum and inertia
        playerShape.SetAsBox([player2Vehicle boundingBox].size.width / 4 / PTM_RATIO, [player2Vehicle boundingBox].size.height / 4 / PTM_RATIO);
        //this is based on the dimensions of the arm which you can get from your image editing software of choice
        player2Fixture = player2Body->CreateFixture(&fixtureDef);

        //Create 2 attack buttons

        CCMenu *attackMenu = [[CCMenu alloc] init];
        for (int i = 1; i <= 2; i++) {
            NSString *levelString = [NSString stringWithFormat:@"Shot %i", i];
            CCLabelTTF *label = [CCLabelTTF labelWithString:levelString
                                                   fontName:@"Marker Felt"
                                                   fontSize:50];

            CCMenuItemLabel *levelLabel = [CCMenuItemLabel
                                           itemWithLabel:label
                                           block:^(id sender) {
                                               Vehicle* current = isFirstPlayerTurn ? player1Vehicle : player2Vehicle;

                                               if (current.energy >= 25) {
                                                   CCSprite *projectile = [CCSprite spriteWithFile:@"seal.png"];
                                                   [self.panZoomLayer addChild:projectile z:-1];
                                                   b2BodyDef bodyDef;
                                                   bodyDef.type = b2_dynamicBody;
                                                   bodyDef.linearDamping = 1;
                                                   bodyDef.angularDamping = 1;

                                                   CGPoint pos = [self toPixels: isFirstPlayerTurn ? player1Body->GetPosition() : player2Body->GetPosition()];
                                                   b2Vec2 startVelocity;
                                                   if (current.flipX) {
                                                       pos.x -= 50;
                                                       startVelocity = b2Vec2(-10, 10);
                                                   }
                                                   else {
                                                       pos.x += 50;
                                                       startVelocity = b2Vec2(10, 10);
                                                   }

                                                   bodyDef.position.Set(pos.x/PTM_RATIO, (pos.y + 25)/PTM_RATIO);
                                                   bodyDef.linearVelocity = startVelocity;
                                                   bodyDef.angularVelocity = isFirstPlayerTurn ? 60 : -60; //In radians
                                                   bodyDef.bullet = true;
                                                   bodyDef.userData = (__bridge void*)projectile; //this tells the Box2D body which sprite to update.
                                                   projectileBody = world->CreateBody(&bodyDef);
                                                   b2CircleShape projectileShape;
                                                   b2FixtureDef projectileFixtureDef;
                                                   projectileShape.m_radius = projectile.contentSize.width/2.0f/PTM_RATIO;
                                                   projectileFixtureDef.shape = &projectileShape;
                                                   projectileFixtureDef.density = 10.3F; //affects collision momentum and inertia
                                                   projectileFixture = projectileBody->CreateFixture(&projectileFixtureDef);

                                                   current.energy -= 25;
                                                   if (current.energy == 0) {
                                                       isFirstPlayerTurn = !isFirstPlayerTurn;
                                                       turnJustEnded = YES;
                                                       current.energy = 100;
                                                   }

                                                   energyLabel.string = [NSString stringWithFormat:@"Energy: %i", isFirstPlayerTurn ? player1Vehicle.energy : player2Vehicle.energy];
                                               }
                                           }
                                           ];

            levelLabel.position = CGPointMake(0, (i * 50 * -1));
            [attackMenu addChild:levelLabel];
        }

        attackMenu.position = CGPointMake(screenSize.width / 2, screenSize.height * .90);
        [self.panZoomLayer addChild: attackMenu];

        //Show Power and Angle for current vehicle
        energyLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Energy: %i", 100]
                                        fontName:@"Marker Felt"
                                        fontSize:20];
        energyLabel.position = CGPointMake(50, screenSize.height - 20);
        energyLabel.color = ccBLACK;
        [self.panZoomLayer addChild:energyLabel];

        angleLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Angle: %i", player1Vehicle.lastAngle]
                                        fontName:@"Marker Felt"
                                        fontSize:20];
        angleLabel.position = CGPointMake(50, screenSize.height - 40);
        angleLabel.color = ccBLACK;
        [self.panZoomLayer addChild:angleLabel];

        //Create 2 arrows for movement
        leftArrow = [CCSprite spriteWithFile:@"arrow_left.png"];
        rightArrow = [CCSprite spriteWithFile:@"arrow_right.png"];
        leftArrow.position = CGPointMake([leftArrow boundingBox].size.width / 2, screenSize.height / 2 - 100);
        rightArrow.position = CGPointMake([rightArrow boundingBox].size.width / 2 + [leftArrow boundingBox].size.width, screenSize.height / 2 - 100);
        [self.panZoomLayer addChild:leftArrow];
        [self.panZoomLayer addChild:rightArrow];
        [self addChild:self.panZoomLayer];

        //schedules a call to the update method every frame
        [self scheduleUpdate];
    }

    return self;
}

+ (id)scene
{
    CCScene *scene = [CCScene node];
    GameLayer *layer = [GameLayer node];
    [scene addChild: layer];
	return scene;
}

#pragma mark Gesture Handlers

- (void)handleRotateGesture:(UIRotationGestureRecognizer *)gesture
{
    if ([gesture velocity] > 0) {
        [angleLabel setString:[NSString stringWithFormat:@"Angle: %i",
                               isFirstPlayerTurn ? ++player1Vehicle.lastAngle : --player2Vehicle.lastAngle]];
    }
    else if ([gesture velocity] < 0) {
        [angleLabel setString:[NSString stringWithFormat:@"Angle: %i",
                               isFirstPlayerTurn ? --player1Vehicle.lastAngle : ++player2Vehicle.lastAngle]];
    }
}

- (void)handleThreeFingers:(UIPanGestureRecognizer *)gesture
{
    UIView *view = [[CCDirector sharedDirector] view];
    /*
    if ([gesture velocityInView:view].x > 0) {
        [powerLabel setString:[NSString stringWithFormat:@"Power: %i",
                               isFirstPlayerTurn ? ++player1Vehicle.power : ++player2Vehicle.power]];
    }
    else if ([gesture velocityInView:view].x < 0) {
        [powerLabel setString:[NSString stringWithFormat:@"Power: %i",
                               isFirstPlayerTurn ? --player1Vehicle.power : --player2Vehicle.power]];
    }
    */
}

//Create the bullets, add them to the list of bullets so they can be referred to later
- (void)createBullets
{
    CCSprite *bullet = [CCSprite spriteWithFile:@"flyingpenguin.png"];
    bullet.position = CGPointMake(250.0f, FLOOR_HEIGHT+190.0f);
    [self.panZoomLayer addChild:bullet z:9];
    [bullets addObject:bullet];
}

//Check through all the bullets and blocks and see if they intersect
-(void) detectCollisions
{
    for(unsigned int i = 0; i < [bullets count]; i++)
    {
        for(unsigned int j = 0; j < [blocks count]; j++)
        {
            if([bullets count]>0)
            {
                NSInteger first = i;
                NSInteger second = j;
                block = [blocks objectAtIndex:second];
                projectile = [bullets objectAtIndex:first];

                firstrect = [projectile textureRect];
                secondrect = [block textureRect];
                //check if their x coordinates match
                if(projectile.position.x == block.position.x)
                {
                    //check if their y coordinates are within the height of the block
                    if(projectile.position.y < (block.position.y + 23.0f) && projectile.position.y > block.position.y - 23.0f)
                    {
                        [self removeChild:block cleanup:YES];
                        [self removeChild:projectile cleanup:YES];
                        [blocks removeObjectAtIndex:second];
                        [bullets removeObjectAtIndex:first];

                    }
                }
            }

        }

    }
}

- (void)update:(ccTime)delta
{
    //Check for inputs and create a bullet if there is a tap
    KKInput *input = [KKInput sharedInput];
    if(input.anyTouchEndedThisFrame)
    {
        //[self createBullets];
    }
    //Move the projectiles to the right and down
    for(unsigned int i = 0; i < [bullets count]; i++)
    {
        NSInteger j = i;
        projectile = [bullets objectAtIndex:j];
        projectile.position = ccp(projectile.position.x + 1.0f,projectile.position.y - 0.25f);
    }
    //Move the screen if the bullets move too far right
    if([bullets count] > 0)
    {
        projectile = [bullets objectAtIndex:0];
        if(projectile.position.x > 320 && self.position.x > -480)
        {
            self.position = ccp(self.position.x - 1, self.position.y);
        }
    }
    //If there are bullets and blocks in existence, check if they are colliding
    if([bullets count] > 0 && [blocks count] > 0)
    {
        [self detectCollisions];
    }

    //get all the bodies in the world
    for (b2Body* body = world->GetBodyList(); body != nil; body = body->GetNext())
    {
        //get the sprite associated with the body
        CCSprite* sprite = (__bridge CCSprite*)body->GetUserData();
        if (sprite != NULL)
        {
            // update the sprite's position to where their physics bodies are
            sprite.position = [self toPixels:body->GetPosition()];
            sprite.rotation = CC_RADIANS_TO_DEGREES(body->GetAngle()) * -1;
        }
    }
    if (turnJustEnded) {
        turnJustEnded = !turnJustEnded;
        energyLabel.string = [NSString stringWithFormat:@"Energy: %i", isFirstPlayerTurn ? player1Vehicle.energy : player2Vehicle.energy];
        angleLabel.string = [NSString stringWithFormat:@"Angle: %i", isFirstPlayerTurn ? player1Vehicle.lastAngle : player2Vehicle.lastAngle];
    }
    if ([input isAnyTouchOnNode:leftArrow touchPhase:KKTouchPhaseBegan]) {
        Vehicle *vehicleToFlip = isFirstPlayerTurn ? player1Vehicle : player2Vehicle;
        vehicleToFlip.flipX = YES;
    }
    if ([input isAnyTouchOnNode:rightArrow touchPhase:KKTouchPhaseBegan]) {
        Vehicle *vehicleToFlip = isFirstPlayerTurn ? player1Vehicle : player2Vehicle;
        vehicleToFlip.flipX = NO;
    }
    if ([input isAnyTouchOnNode:leftArrow touchPhase:KKTouchPhaseAny]) {
        Vehicle *vehicleToFlip = isFirstPlayerTurn ? player1Vehicle : player2Vehicle;
        vehicleToFlip.flipX = YES;
        b2Body *bodyToMove = isFirstPlayerTurn ? player1Body : player2Body;
        bodyToMove->SetLinearVelocity(b2Vec2(-2, 0));

        Vehicle *vehicleToDrain = isFirstPlayerTurn ? player1Vehicle : player2Vehicle;
        vehicleToDrain.energy--;
        if (!vehicleToDrain.energy) {
            isFirstPlayerTurn = !isFirstPlayerTurn;
            turnJustEnded = YES;
            vehicleToDrain.energy = 100;
            bodyToMove->SetLinearVelocity(b2Vec2(0, 0));
        }

        energyLabel.string = [NSString stringWithFormat:@"Energy: %i", isFirstPlayerTurn ? player1Vehicle.energy : player2Vehicle.energy];
    }
    if ([input isAnyTouchOnNode:rightArrow touchPhase:KKTouchPhaseAny]) {
        Vehicle *vehicleToFlip = isFirstPlayerTurn ? player1Vehicle : player2Vehicle;
        vehicleToFlip.flipX = NO;
        b2Body *bodyToMove = isFirstPlayerTurn ? player1Body : player2Body;
        bodyToMove->SetLinearVelocity(b2Vec2(2, 0));

        Vehicle *vehicleToDrain = isFirstPlayerTurn ? player1Vehicle : player2Vehicle;
        vehicleToDrain.energy--;
        if (!vehicleToDrain.energy) {
            isFirstPlayerTurn = !isFirstPlayerTurn;
            turnJustEnded = YES;
            vehicleToDrain.energy = 100;
            bodyToMove->SetLinearVelocity(b2Vec2(0, 0));
        }

        energyLabel.string = [NSString stringWithFormat:@"Energy: %i", isFirstPlayerTurn ? player1Vehicle.energy : player2Vehicle.energy];
    }

    float timeStep = 0.03f;
    int32 velocityIterations = 8;
    int32 positionIterations = 1;
    world->Step(timeStep, velocityIterations, positionIterations);

    [self stabilizeVehicle:player1Body withTimeStep:timeStep];
    [self stabilizeVehicle:player2Body withTimeStep:timeStep];
}

- (void)stabilizeVehicle:(b2Body *)vehicleBody withTimeStep:(float)timeStep
{
    float desiredAngle = 0;
    float angleNow = vehicleBody->GetAngle();
    float changeExpected = vehicleBody->GetAngularVelocity() * timeStep; //expected angle change in next timestep
    float angleNextStep = angleNow + changeExpected;
    float changeRequiredInNextStep = desiredAngle - angleNextStep;
    float rotationalAcceleration = timeStep * changeRequiredInNextStep;
    float torque = rotationalAcceleration * TORQUE_ADJUSTMENT;
    if (torque > MAX_TORQUE) {
        torque = MAX_TORQUE;
    }
    vehicleBody->ApplyTorque(torque);
}

// convenience method to convert a b2Vec2 to a CGPoint
- (CGPoint)toPixels:(b2Vec2)vec
{
    return ccpMult(CGPointMake(vec.x, vec.y), PTM_RATIO);
}

@end
