/*
 * Kobold2D™ --- http://www.kobold2d.org
 *
 * Copyright (c) 2010-2011 Steffen Itterheim. 
 * Released under MIT License in Germany (LICENSE-Kobold2D.txt).
 */

#import "GameLayer.h"
#import "Vehicle.h"

const float PTM_RATIO = 32.0f;
#define FLOOR_HEIGHT    50.0f

CCSprite *projectile;
CCSprite *block;
CGRect firstrect;
CGRect secondrect;
NSMutableArray *blocks = [[NSMutableArray alloc] init];



@interface GameLayer (PrivateMethods)
-(void) enableBox2dDebugDrawing;
-(void) addSomeJoinedBodies:(CGPoint)pos;
-(void) addNewSpriteAt:(CGPoint)p;
-(b2Vec2) toMeters:(CGPoint)point;
-(CGPoint) toPixels:(b2Vec2)vec;
@end

@implementation GameLayer


-(id) init
{
	if ((self = [super init]))
	{
		CCLOG(@"%@ init", NSStringFromClass([self class]));
        KKInput *input = [KKInput sharedInput];
        //input.gestureTapEnabled = YES; //This causes my shot menuitems to not be activated
        input.gesturePanEnabled = YES;
        input.gestureRotationEnabled = YES;
        input.gesturePinchEnabled = YES;
        
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
        
        
        //Add all the sprites to the game, including blocks and the catapult. It's tedious...
        //See the storing game data tutorial to learn how to abstract all of this out to a plist file
        
        CCSprite *sprite = [CCSprite spriteWithFile:@"background.png"];
        sprite.anchorPoint = CGPointZero;
        [self addChild:sprite z:-1];
        
        sprite = [CCSprite spriteWithFile:@"ground.png"];
        sprite.anchorPoint = CGPointZero;
        [self addChild:sprite z:-1];
        
        player1Vehicle = [[Vehicle alloc] initWithName: @"Triceratops" usingImage:@"triceratops.png"];
        [self addChild:player1Vehicle z:1 tag:1];
        
        // Setting the properties of our definition
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        bodyDef.linearDamping = 1;
        bodyDef.angularDamping = 1;
        bodyDef.position.Set(450.0f/PTM_RATIO,(200.0f)/PTM_RATIO);
        bodyDef.linearVelocity = b2Vec2(-5,0);
        bodyDef.userData = (__bridge void*)player1Vehicle; //this tells the Box2D body which sprite to update.
        
        //create a body with the definition we just created
        player1Body = world->CreateBody(&bodyDef);
        //the -> is C++ syntax; it is like calling an object's methods (the CreateBody "method")
        
        //Create a fixture for the arm
        b2PolygonShape playerShape;
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &playerShape; //geometric shape
        fixtureDef.density = 0.3F; //affects collision momentum and inertia
        playerShape.SetAsBox(30.0f/PTM_RATIO, 30.0f/PTM_RATIO);
        //this is based on the dimensions of the arm which you can get from your image editing software of choice
        player1Fixture = player1Body->CreateFixture(&fixtureDef);
        
        player2Vehicle = [[Vehicle alloc] initWithName: @"Mammoth" usingImage:@"mammoth.png"];
        [self addChild:player2Vehicle z:1 tag:2];
        //causes rotations to slow down. A value of 0 means there is no slowdown
        bodyDef.position.Set(50.0f/PTM_RATIO,(200.0f)/PTM_RATIO);
        bodyDef.linearVelocity = b2Vec2(5,0);
        bodyDef.userData = (__bridge void*)player2Vehicle; //this tells the Box2D body which sprite to update.
        
        //create a body with the definition we just created
        player2Body = world->CreateBody(&bodyDef);
        //the -> is C++ syntax; it is like calling an object's methods (the CreateBody "method")
        
        fixtureDef.shape = &playerShape; //geometric shape
        fixtureDef.density = 0.3F; //affects collision momentum and inertia
        playerShape.SetAsBox(30.0f/PTM_RATIO, 30.0f/PTM_RATIO);
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
                                               CCSprite *projectile = [CCSprite spriteWithFile:@"seal.png"];
                                               [self addChild:projectile z:-1];
                                               b2BodyDef bodyDef;
                                               bodyDef.type = b2_dynamicBody;
                                               bodyDef.linearDamping = 1;
                                               bodyDef.angularDamping = 1;
                                               CGPoint pos = [self toPixels: isFirstPlayerTurn ? player1Body->GetPosition() : player2Body->GetPosition()];
                                               bodyDef.position.Set((pos.x - (isFirstPlayerTurn ? 50 : -50))/PTM_RATIO, (pos.y + 25)/PTM_RATIO);
                                               bodyDef.linearVelocity = b2Vec2(isFirstPlayerTurn ? -5 : 5, 40);
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
                                               isFirstPlayerTurn = !isFirstPlayerTurn;
                                               justAttacked = true;
                                           }
                                           ];
            
            levelLabel.position = CGPointMake(0, (i * 50 * -1));
            [attackMenu addChild:levelLabel];
        }

        attackMenu.position = CGPointMake(screenSize.width / 2, screenSize.height * .90);
        [self addChild: attackMenu];
        
        //Show Power and Angle for current vehicle
        powerLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Power: %i", 100]
                                               fontName:@"Marker Felt"
											   fontSize:20];
		powerLabel.position = CGPointMake(50, screenSize.height - 20);
		powerLabel.color = ccBLACK;
		[self addChild:powerLabel];

        angleLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Angle: %i", player1Vehicle.lastAngle]
                                   fontName:@"Marker Felt"
                                   fontSize:20];
		angleLabel.position = CGPointMake(50, screenSize.height - 40);
		angleLabel.color = ccBLACK;
		[self addChild:angleLabel];
        
        //schedules a call to the update method every frame
		[self scheduleUpdate];
	}
    
	return self;
}

+(id) scene
{
    CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	GameLayer *layer = [GameLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}


//Create the bullets, add them to the list of bullets so they can be referred to later
- (void)createBullets
{
    CCSprite *bullet = [CCSprite spriteWithFile:@"flyingpenguin.png"];
    bullet.position = CGPointMake(250.0f, FLOOR_HEIGHT+190.0f);
    [self addChild:bullet z:9];
    [bullets addObject:bullet];
}

//Check through all the bullets and blocks and see if they intersect
-(void) detectCollisions
{
    for(int i = 0; i < [bullets count]; i++)
    {
        for(int j = 0; j < [blocks count]; j++)
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



-(void) dealloc
{
	delete world;
    
#ifndef KK_ARC_ENABLED
	[super dealloc];
#endif
}



-(void) update:(ccTime)delta
{
    //Check for inputs and create a bullet if there is a tap
    KKInput *input = [KKInput sharedInput];
    if(input.anyTouchEndedThisFrame)
    {
        [self createBullets];
    }
    //Move the projectiles to the right and down
    for(int i = 0; i < [bullets count]; i++)
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
            float angle = body->GetAngle();
            sprite.rotation = CC_RADIANS_TO_DEGREES(angle) * -1;
        }
    }
    if (justAttacked) {
        justAttacked = !justAttacked;
        angleLabel.string = [NSString stringWithFormat:@"Angle: %i", isFirstPlayerTurn ? player1Vehicle.lastAngle : player2Vehicle.lastAngle];
    }
    if (input.gestureRotationBegan) {
        input.gesturePinchEnabled = NO;
        if (input.gestureRotationVelocity > 0) {
            angleLabel.string = [NSString stringWithFormat:@"Angle: %i", isFirstPlayerTurn ? ++player1Vehicle.lastAngle : --player2Vehicle.lastAngle];
        }
        else if (input.gestureRotationVelocity < 0) {
            angleLabel.string = [NSString stringWithFormat:@"Angle: %i", isFirstPlayerTurn ? --player1Vehicle.lastAngle : ++player2Vehicle.lastAngle];
        }
    }
    else {
        input.gesturePinchEnabled = YES;
    }
    if (input.gesturePinchBegan) {
        input.gestureRotationEnabled = NO;
        self.scale = input.gesturePinchScale;
    }
    else {
        input.gestureRotationEnabled = YES;
    }
    if (input.gesturePanBegan) {
        CGPoint vel = input.gesturePanVelocity;
        CGPoint pos = input.gesturePanTranslation;
        
        //Update the screen position only when the finger is moving
        if (vel.x || vel.y) {
            //Change the position of the screen relative to the panning motion
            self.position = CGPointMake(self.position.x - pos.x, self.position.y + pos.y);
            
            //Reset the point translation value so it doesn't append with the next pan motion
            //before releasing the finger
            input.gesturePanTranslation = CGPointMake(0, 0);
        }
    }
    
    float timeStep = 0.03f;
    int32 velocityIterations = 8;
    int32 positionIterations = 1;
    world->Step(timeStep, velocityIterations, positionIterations);
}

// convenience method to convert a b2Vec2 to a CGPoint
-(CGPoint) toPixels:(b2Vec2)vec
{
	return ccpMult(CGPointMake(vec.x, vec.y), PTM_RATIO);
}


@end
