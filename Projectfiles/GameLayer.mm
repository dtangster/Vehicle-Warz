/*
 * Kobold2D™ --- http://www.kobold2d.org
 *
 * Copyright (c) 2010-2011 Steffen Itterheim.
 * Released under MIT License in Germany (LICENSE-Kobold2D.txt).
 */

#import "GameLayer.h"
#import "Vehicle.h"
#import "Weapon.h"
#import "CCSprite+SpriteSize.h"

#define PTM_RATIO 32.0f
#define FLOOR_HEIGHT    50.0f
#define TORQUE_ADJUSTMENT 50
#define MAX_TORQUE 1000
#define SHOT_ONE_TEXT @"Shot 1"
#define SHOT_TWO_TEXT @"Shot 2"
#define SHOT_SPECIAL_TEXT @"Special"

CCSprite *projectile;
CCSprite *block;
CGRect firstrect;
CGRect secondrect;
NSMutableArray *blocks = [[NSMutableArray alloc] init];

// UIKit Gestures
UIPanGestureRecognizer *panGesture;
UIPanGestureRecognizer *threeFingerGesture;

//-------------------------------TEMPORARY--------------------------------
UIRotationGestureRecognizer *rotateGesture;
//-------------------------------TEMPORARY--------------------------------

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
        panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                  action:@selector(handlePanGesture:)];
        [panGesture setMinimumNumberOfTouches:2];
        [panGesture setMaximumNumberOfTouches:2];
        threeFingerGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                     action:@selector(handleThreeFingers:)];
        [threeFingerGesture setMinimumNumberOfTouches:3];
        [threeFingerGesture setMaximumNumberOfTouches:3];
        
        //-------------------------------TEMPORARY--------------------------------
        rotateGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self
                                                                     action:@selector(handleRotateGesture:)];
        //-------------------------------TEMPORARY--------------------------------

        [[[CCDirector sharedDirector] view] addGestureRecognizer:panGesture];
        [[[CCDirector sharedDirector] view] addGestureRecognizer:threeFingerGesture];
        
        //-------------------------------TEMPORARY--------------------------------
        [[[CCDirector sharedDirector] view] addGestureRecognizer:rotateGesture];
        //-------------------------------TEMPORARY--------------------------------
        
        // Construct a world object, which will hold and simulate the rigid bodies.
        b2Vec2 gravity = b2Vec2(0.0f, -10.0f);
        _world = new b2World(gravity);
        _world->SetAllowSleeping(YES);
        //world->SetContinuousPhysics(YES);

        //create an object that will check for collisions
        _contactListener = new ContactListener();
        _world->SetContactListener(_contactListener);

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
        _screenBorderBody = _world->CreateBody(&screenBorderDef);
        b2EdgeShape screenBorderShape;

        screenBorderShape.Set(lowerLeftCorner, lowerRightCorner);
        _screenBorderBody->CreateFixture(&screenBorderShape, 0);
        screenBorderShape.Set(lowerRightCorner, upperRightCorner);
        _screenBorderBody->CreateFixture(&screenBorderShape, 0);
        screenBorderShape.Set(upperRightCorner, upperLeftCorner);
        _screenBorderBody->CreateFixture(&screenBorderShape, 0);
        screenBorderShape.Set(upperLeftCorner, lowerLeftCorner);
        _screenBorderBody->CreateFixture(&screenBorderShape, 0);
        
        // Set up a layer that restricts panning and zooming to within the background's content size
        self.panZoomLayer = [CCLayerPanZoom node];
        CCSprite *bgSprite = [CCSprite spriteWithFile:@"bgImage.png"];
        bgSprite.anchorPoint = CGPointZero;
        bgSprite.scale = CC_CONTENT_SCALE_FACTOR();
        [self.panZoomLayer addChild:bgSprite z:-1];
        
        // Set up the zooming restrictions
        [[self panZoomLayer] setMaxScale:2.0f];
        [[self panZoomLayer] setMinScale:1];
        [[self panZoomLayer] setRubberEffectRatio:0.0f];
        
        // Set up the content size for restricting panning
        [[self panZoomLayer] setContentSize:CGSizeMake([bgSprite spriteWidth], [bgSprite spriteHeight])];
        [[self panZoomLayer] setPanBoundsRect:CGRectMake(0, 0, screenSize.width, screenSize.height)];
        [[self panZoomLayer] setAnchorPoint:CGPointZero];
        [[self panZoomLayer] setPosition:CGPointZero];

        // Create first player vehicle
        _player1Vehicle = [[Vehicle alloc] initWithName: @"Triceratops" usingImage:@"triceratops.png"];
        [self.panZoomLayer addChild:_player1Vehicle z:1 tag:1];

        // Setting the properties of our definition
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        bodyDef.linearDamping = 1;
        bodyDef.angularDamping = 1;
        bodyDef.position.Set(450.0f/PTM_RATIO,(200.0f)/PTM_RATIO);
        bodyDef.linearVelocity = b2Vec2(-5,0);
        bodyDef.angularVelocity = -110;
        
        // This tells the Box2D body which sprite to update.
        bodyDef.userData = (__bridge void*)_player1Vehicle;

        // Create a body with the definition we just created
        _player1Vehicle.body = _world->CreateBody(&bodyDef);

        // Create a physical body for the vehicle
        b2PolygonShape playerShape;
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &playerShape;
        fixtureDef.density = 0.3F; // Affects collision momentum and inertia
        playerShape.SetAsBox([_player1Vehicle boundingBox].size.width / 3 / PTM_RATIO, [_player1Vehicle boundingBox].size.height / 3 / PTM_RATIO);
        _player1Vehicle.fixture = _player1Vehicle.body->CreateFixture(&fixtureDef);

        // Create second player vehicle
        _player2Vehicle = [[Vehicle alloc] initWithName: @"Mammoth" usingImage:@"mammoth.png"];
        [self.panZoomLayer addChild:_player2Vehicle z:1 tag:2];
        bodyDef.position.Set(50.0f/PTM_RATIO,(200.0f)/PTM_RATIO);
        bodyDef.linearVelocity = b2Vec2(5,0);
        bodyDef.angularVelocity = 90;
        bodyDef.userData = (__bridge void*)_player2Vehicle;
        _player2Vehicle.body = _world->CreateBody(&bodyDef);
        fixtureDef.shape = &playerShape;
        fixtureDef.density = 0.3F; //affects collision momentum and inertia
        playerShape.SetAsBox([_player2Vehicle boundingBox].size.width / 4 / PTM_RATIO, [_player2Vehicle boundingBox].size.height / 4 / PTM_RATIO);
        _player2Vehicle.fixture = _player2Vehicle.body->CreateFixture(&fixtureDef);

        // Create a temporary seal weapon and assign to all weapon shots for both players
        Weapon *tempWeapon = [[Weapon alloc] initWithName:@"Seal" withEnergyCost:20 usingImage:@"seal.png"];
        _player1Vehicle.weapon1 = tempWeapon;
        tempWeapon = [[Weapon alloc] initWithName:@"Seal" withEnergyCost:20 usingImage:@"seal.png"];
        _player1Vehicle.weapon2 = tempWeapon;
        tempWeapon = [[Weapon alloc] initWithName:@"Seal" withEnergyCost:20 usingImage:@"seal.png"];
        _player1Vehicle.special = tempWeapon;
        tempWeapon = [[Weapon alloc] initWithName:@"Seal" withEnergyCost:20 usingImage:@"seal.png"];
        _player2Vehicle.weapon1 = tempWeapon;
        tempWeapon = [[Weapon alloc] initWithName:@"Seal" withEnergyCost:20 usingImage:@"seal.png"];
        _player2Vehicle.weapon2 = tempWeapon;
        tempWeapon = [[Weapon alloc] initWithName:@"Seal" withEnergyCost:20 usingImage:@"seal.png"];
        _player2Vehicle.special = tempWeapon;
        
        // Create 2 attack buttons
        CCMenu *attackMenu = [[CCMenu alloc] init];
        attackMenu.position = CGPointMake(screenSize.width / 2, screenSize.height * .80);
        [self.panZoomLayer addChild: attackMenu];
        
        // Create first shot label
        NSString *shotString = [NSString stringWithFormat:SHOT_ONE_TEXT];
        CCLabelTTF *label = [CCLabelTTF labelWithString:shotString
                                               fontName:@"Marker Felt"
                                               fontSize:30];
        CCMenuItemLabel *menuLabel = [CCMenuItemLabel itemWithLabel:label target:self selector:@selector(linkAttacksToButtons:)];
        [attackMenu addChild:menuLabel z:2 tag:10];
        
        // Create second shot label
        shotString = [NSString stringWithFormat:SHOT_TWO_TEXT];
        label = [CCLabelTTF labelWithString:shotString
                                               fontName:@"Marker Felt"
                                               fontSize:30];
        menuLabel = [CCMenuItemLabel itemWithLabel:label target:self selector:@selector(linkAttacksToButtons:)];
        [attackMenu addChild:menuLabel z:2 tag:11];
        
        // Create special shot label
        shotString = [NSString stringWithFormat:SHOT_SPECIAL_TEXT];
        label = [CCLabelTTF labelWithString:shotString
                                   fontName:@"Marker Felt"
                                   fontSize:30];
        menuLabel = [CCMenuItemLabel itemWithLabel:label target:self selector:@selector(linkAttacksToButtons:)];
        [attackMenu addChild:menuLabel z:2 tag:12];
        [attackMenu alignItemsVertically];
        
        // Show energy, power, and angle for current vehicle
        _energyLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Energy: %i", _player1Vehicle.energy]
                                        fontName:@"Marker Felt"
                                        fontSize:20];
        _energyLabel.position = CGPointMake(50, screenSize.height - 20);
        _energyLabel.color = ccBLACK;
        [self.panZoomLayer addChild:_energyLabel];
        
        _shotPowerLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Power: %i", _player1Vehicle.lastShotPower]
                                         fontName:@"Marker Felt"
                                         fontSize:20];
        _shotPowerLabel.position = CGPointMake(50, screenSize.height - 40);
        _shotPowerLabel.color = ccBLACK;
        [self.panZoomLayer addChild:_shotPowerLabel];

        _angleLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Angle: %i", _player1Vehicle.lastAngle]
                                        fontName:@"Marker Felt"
                                        fontSize:20];
        _angleLabel.position = CGPointMake(50, screenSize.height - 60);
        _angleLabel.color = ccBLACK;
        [self.panZoomLayer addChild:_angleLabel];

        // Create 2 arrows for movement
        _leftArrow = [CCSprite spriteWithFile:@"arrow_left.png"];
        _rightArrow = [CCSprite spriteWithFile:@"arrow_right.png"];
        _leftArrow.position = CGPointMake([_leftArrow boundingBox].size.width / 2, screenSize.height / 2 - 100);
        _rightArrow.position = CGPointMake([_rightArrow boundingBox].size.width / 2 + [_leftArrow boundingBox].size.width, screenSize.height / 2 - 100);
        [self.panZoomLayer addChild:_leftArrow];
        [self.panZoomLayer addChild:_rightArrow];
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
- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture
{
    UIView *view = [[CCDirector sharedDirector] view];
    Vehicle *current = _isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;
    
    if ([gesture velocityInView:view].x > 0 && current.lastAngle < current.maxFrontUpperAngle) {
        [_angleLabel setString:[NSString stringWithFormat:@"Angle: %i", ++current.lastAngle]];
    }
    else if ([gesture velocityInView:view].x < 0 && current.lastAngle > current.maxFrontLowerAngle) {
        [_angleLabel setString:[NSString stringWithFormat:@"Angle: %i", --current.lastAngle]];
    }
}

- (void)handleThreeFingers:(UIPanGestureRecognizer *)gesture
{
    UIView *view = [[CCDirector sharedDirector] view];
    Vehicle *current = _isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;
    
    if ([gesture velocityInView:view].x > 0 && current.lastShotPower <= current.power) {
        [_shotPowerLabel setString:[NSString stringWithFormat:@"Power: %i", ++current.lastShotPower]];
    }
    else if ([gesture velocityInView:view].x < 0 && current.lastShotPower >= 0) {
        [_shotPowerLabel setString:[NSString stringWithFormat:@"Power: %i", --current.lastShotPower]];
    }
}

//-------------------------------TEMPORARY--------------------------------
- (void)handleRotateGesture:(UIRotationGestureRecognizer *)gesture
{
    Vehicle *current = _isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;

    if (gesture.velocity > 0 && current.lastShotPower < current.power) {
        [_shotPowerLabel setString:[NSString stringWithFormat:@"Power: %i", ++current.lastShotPower]];
    }
    else if (gesture.velocity < 0 && current.lastShotPower > 0) {
        [_shotPowerLabel setString:[NSString stringWithFormat:@"Power: %i", --current.lastShotPower]];
    }
}
//-------------------------------TEMPORARY--------------------------------

- (void)linkAttacksToButtons:(CCMenuItemLabel *) sender
{
    Vehicle *vehicle = _isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;

    if ([sender.label.string isEqualToString:SHOT_ONE_TEXT]) {
        [vehicle attackWithWeapon:vehicle.weapon1 onScreen:self];
    }
    else if ([sender.label.string isEqualToString:SHOT_TWO_TEXT]) {
        [vehicle attackWithWeapon:vehicle.weapon2 onScreen:self];
    }
    else if ([sender.label.string isEqualToString:SHOT_SPECIAL_TEXT]) {
        [vehicle attackWithWeapon:vehicle.special onScreen:self];
    }
}

/*
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
*/

- (void)update:(ccTime)delta
{
    //Check for inputs and create a bullet if there is a tap
    KKInput *input = [KKInput sharedInput];
    
    /*
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
    */

    // Get all the bodies in the world
    for (b2Body* body = _world->GetBodyList(); body != nil; body = body->GetNext())
    {
        // Get the sprite associated with the body
        CCSprite* sprite = (__bridge CCSprite*)body->GetUserData();
        if (sprite != NULL)
        {
            // Update the sprite's position to where their physics bodies are
            sprite.position = [self toPixels:body->GetPosition()];
            sprite.rotation = CC_RADIANS_TO_DEGREES(body->GetAngle()) * -1;
        }
    }
    
    // Change energy and angle labels when a vehicle turn ends
    if (_turnJustEnded) {
        _turnJustEnded = !_turnJustEnded;
        _energyLabel.string = [NSString stringWithFormat:@"Energy: %i", _isFirstPlayerTurn ? _player1Vehicle.energy : _player2Vehicle.energy];
        _angleLabel.string = [NSString stringWithFormat:@"Angle: %i", _isFirstPlayerTurn ? _player1Vehicle.lastAngle : _player2Vehicle.lastAngle];
    }
    
    // Ensure that the current vehicle is facing left when they press the left arrow
    if ([input isAnyTouchOnNode:_leftArrow touchPhase:KKTouchPhaseBegan]) {
        Vehicle *vehicleToFlip = _isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;
        vehicleToFlip.flipX = YES;
    }
    
    // Ensure that the current vehicle is facing right when they press right arrow
    if ([input isAnyTouchOnNode:_rightArrow touchPhase:KKTouchPhaseBegan]) {
        Vehicle *vehicleToFlip = _isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;
        vehicleToFlip.flipX = NO;
    }
    if ([input isAnyTouchOnNode:_leftArrow touchPhase:KKTouchPhaseAny]) {
        Vehicle *vehicleToFlip = _isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;
        vehicleToFlip.flipX = YES;
        
        // Maintains a constant velocity for the vehicle
        b2Body *bodyToMove = _isFirstPlayerTurn ? _player1Vehicle.body : _player2Vehicle.body;
        bodyToMove->SetLinearVelocity(b2Vec2(vehicleToFlip.speed * -1, 0));

        // Deplete vehicle energy for moving
        vehicleToFlip.energy--;
        
        // Switch turns when out of energy
        if (!vehicleToFlip.energy) {
            _isFirstPlayerTurn = !_isFirstPlayerTurn;
            _turnJustEnded = YES;
            vehicleToFlip.energy = vehicleToFlip.maxEnergy; // Reset energy to prepare for next turn
            bodyToMove->SetLinearVelocity(b2Vec2(0, 0)); // Prevents sliding when energy is depleted
        }

        // Update energy label
        _energyLabel.string = [NSString stringWithFormat:@"Energy: %i", _isFirstPlayerTurn ? _player1Vehicle.energy : _player2Vehicle.energy];
    }
    
    if ([input isAnyTouchOnNode:_rightArrow touchPhase:KKTouchPhaseAny]) {
        Vehicle *vehicleToFlip = _isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;
        vehicleToFlip.flipX = NO;
        b2Body *bodyToMove = _isFirstPlayerTurn ? _player1Vehicle.body : _player2Vehicle.body;
        bodyToMove->SetLinearVelocity(b2Vec2(vehicleToFlip.speed, 0));
        
        // Deplete vehicle energy for moving
        vehicleToFlip.energy--;
        
        // Switch turns when out of energy
        if (!vehicleToFlip.energy) {
            _isFirstPlayerTurn = !_isFirstPlayerTurn;
            _turnJustEnded = YES;
            vehicleToFlip.energy = vehicleToFlip.maxEnergy; // Reset energy to prepare for next turn
            bodyToMove->SetLinearVelocity(b2Vec2(0, 0)); // Prevents sliding when energy is depleted
        }

        _energyLabel.string = [NSString stringWithFormat:@"Energy: %i", _isFirstPlayerTurn ? _player1Vehicle.energy : _player2Vehicle.energy];
    }

    float timeStep = 0.03f;
    int32 velocityIterations = 8;
    int32 positionIterations = 1;
    _world->Step(timeStep, velocityIterations, positionIterations);

    // Prevent vehicles from flipping over
    [self stabilizeVehicle:_player1Vehicle.body withTimeStep:timeStep];
    [self stabilizeVehicle:_player2Vehicle.body withTimeStep:timeStep];
}

- (void)stabilizeVehicle:(b2Body *)vehicleBody withTimeStep:(float)timeStep
{
    float desiredAngle = 0;
    float angleNow = vehicleBody->GetAngle();
    
    // Expected angle change in next timestep
    float changeExpected = vehicleBody->GetAngularVelocity() * timeStep;
    
    float angleNextStep = angleNow + changeExpected;
    float changeRequiredInNextStep = desiredAngle - angleNextStep;
    float rotationalAcceleration = timeStep * changeRequiredInNextStep;
    float torque = rotationalAcceleration * TORQUE_ADJUSTMENT;
    
    if (torque > MAX_TORQUE) {
        torque = MAX_TORQUE;
    }
    
    vehicleBody->ApplyTorque(torque);
}

// Convenience method to convert a b2Vec2 to a CGPoint
- (CGPoint)toPixels:(b2Vec2)vec
{
    return ccpMult(CGPointMake(vec.x, vec.y), PTM_RATIO);
}

@end
