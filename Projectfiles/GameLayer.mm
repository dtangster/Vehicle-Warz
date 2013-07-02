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
#import "CCLayerPanZoom+Scroll.h"

#define PTM_RATIO 32.0f
#define FLOOR_HEIGHT 50.0f
#define SCREEN_PAN_RATIO 0.75f
#define TORQUE_ADJUSTMENT 50.0f
#define MAX_TORQUE 1000.0f
#define VEHICLE_SPEED_RATIO 0.1f // This changes how much a vehicle's speed affects its acceleration
#define SHOT_ONE_LABEL @"Shot 1"
#define SHOT_TWO_LABEL @"Shot 2"
#define SHOT_SPECIAL_LABEL @"Special"
#define FIRE_SHOT_LABEL @"Fire"
#define DECREASE_POWER @"Decrease Power"
#define DECREASE_ANGLE @"Decrease Angle"
#define INCREASE_POWER @"Increase Power"
#define INCREASE_ANGLE @"Increase Angle"
#define LEFT_MOVEMENT_BEGAN @"Left Movement Began"
#define RIGHT_MOVEMENT_BEGAN @"Right Movement Began"
#define LEFT_MOVEMENT_CONTINUE @"Left Movement Continue"
#define RIGHT_MOVEMENT_CONTINUE @"Right Movement Continue"
#define WORLD_STEP @"Step"
#define ACTION_SEQUENCE_FILE @"action_sequence.data"

CCSprite *projectile;
CCSprite *block;
CGRect firstrect;
CGRect secondrect;
NSMutableArray *blocks = [[NSMutableArray alloc] init];

// Used for playing back actions of a vehicle
NSUInteger physicsHistoryIndex = 0;

// UIKit Gestures
UIPanGestureRecognizer *twoFingerPanGesture;
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

+ (id)scene
{
    CCScene *scene = [CCScene node];
    GameLayer *layer = [GameLayer node];
    [scene addChild: layer];
    
	return scene;
}

- (id)init
{
    if ((self = [super init]))
    {
        CCLOG(@"%@ init", NSStringFromClass([self class]));
        _actionReplayData = [[NSMutableArray alloc] init];
        
        // Construct a world object, which will hold and simulate the rigid bodies.
        b2Vec2 gravity = b2Vec2(0.0f, -10.0f);
        _world = new b2World(gravity);
        _world->SetAllowSleeping(YES);
        //world->SetContinuousPhysics(YES);

        // Create an object that will check for collisions
        _contactListener = new ContactListener();
        _world->SetContactListener(_contactListener);

        glClearColor(0.1f, 0.0f, 0.2f, 1.0f);

        CGSize screenSize = [CCDirector sharedDirector].winSize;

        // Set up game height and width
        b2Vec2 lowerLeftCorner = b2Vec2(0,FLOOR_HEIGHT/PTM_RATIO);
        b2Vec2 lowerRightCorner = b2Vec2(screenSize.width * 2.0f / PTM_RATIO, FLOOR_HEIGHT / PTM_RATIO);
        b2Vec2 upperLeftCorner = b2Vec2(0,screenSize.height * 2.0f / PTM_RATIO);
        b2Vec2 upperRightCorner = b2Vec2(screenSize.width * 2.0f / PTM_RATIO, screenSize.height * 2.0f / PTM_RATIO);

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
        _panZoomLayer = [[CCLayerPanZoom alloc] init];

        CCSprite *bgSprite = [CCSprite spriteWithFile:@"bgImage-big.png"];
        bgSprite.anchorPoint = CGPointZero;
        [_panZoomLayer addChild:bgSprite z:-1];
        
        // Set up the zooming restrictions
        // NOTE: Apparently the order these properties are set actually matters
        [_panZoomLayer setMaxScale:2.0f];
        [_panZoomLayer setMinScale:0.0f];
        [_panZoomLayer setRubberEffectRatio:0.0f];
        
        // Set up the content size for restricting panning
        [_panZoomLayer setContentSize:CGSizeMake([bgSprite spriteWidth], [bgSprite spriteHeight])];
        [_panZoomLayer setPanBoundsRect:CGRectMake(0, 0, screenSize.width, screenSize.height)];
        [_panZoomLayer setAnchorPoint:CGPointZero];
        [_panZoomLayer setScale:1.0f];
        [_panZoomLayer setPosition:CGPointZero];

        // Create first player vehicle
        _player1Vehicle = [[Vehicle alloc] initWithName: @"Triceratops" usingImage:@"triceratops.png"];
        [_panZoomLayer addChild:_player1Vehicle z:1 tag:1];

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
        playerShape.SetAsBox([_player1Vehicle spriteWidth] / 3 / PTM_RATIO, [_player1Vehicle spriteHeight] / 3 / PTM_RATIO);
        _player1Vehicle.fixture = _player1Vehicle.body->CreateFixture(&fixtureDef);

        // Create second player vehicle
        _player2Vehicle = [[Vehicle alloc] initWithName: @"Mammoth" usingImage:@"mammoth.png"];
        [_panZoomLayer addChild:_player2Vehicle z:1 tag:2];
        bodyDef.position.Set(50.0f/PTM_RATIO,(200.0f)/PTM_RATIO);
        bodyDef.linearVelocity = b2Vec2(5,0);
        bodyDef.angularVelocity = 90;
        bodyDef.userData = (__bridge void*)_player2Vehicle;
        _player2Vehicle.body = _world->CreateBody(&bodyDef);
        fixtureDef.shape = &playerShape;
        fixtureDef.density = 0.3F; //affects collision momentum and inertia
        playerShape.SetAsBox([_player2Vehicle spriteWidth] / 4 / PTM_RATIO, [_player2Vehicle spriteHeight] / 4 / PTM_RATIO);
        _player2Vehicle.fixture = _player2Vehicle.body->CreateFixture(&fixtureDef);
        
        [self addChild:_panZoomLayer];
        [self setUpGestures];
        [self setUpSounds];
        [self setUpMenu];
        _isFirstPlayerTurn = YES;
        
        // Schedules a call to the update method every frame
        [self scheduleUpdate];
    }

    return self;
}

#pragma mark Setups
- (void)setUpGestures
{
    twoFingerPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                  action:@selector(handleTwoFingerPanGesture:)];
    [twoFingerPanGesture setMinimumNumberOfTouches:2];
    [twoFingerPanGesture setMaximumNumberOfTouches:2];
    threeFingerGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                 action:@selector(handleThreeFingers:)];
    [threeFingerGesture setMinimumNumberOfTouches:3];
    [threeFingerGesture setMaximumNumberOfTouches:3];
    
    // Temporary
    rotateGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self
                                                                 action:@selector(handleRotateGesture:)];    
    [[[CCDirector sharedDirector] view] addGestureRecognizer:twoFingerPanGesture];
    [[[CCDirector sharedDirector] view] addGestureRecognizer:threeFingerGesture];
    
    // Temporary
    [[[CCDirector sharedDirector] view] addGestureRecognizer:rotateGesture];
}

- (void)setUpSounds
{
    // Load sound effects
    _soundEffects = [[NSDictionary alloc] initWithContentsOfFile:@"sound_effects.plist"];
    
    // Create a temporary seal weapon and assign to all weapon shots for both players
    Weapon *tempWeapon = [[Weapon alloc] initWithName:@"Seal" withEnergyCost:20
                                           usingImage:@"seal.png"
                                           usingSound:_soundEffects[@"vehicle1-shot1"]];
    _player1Vehicle.weapon1 = tempWeapon;
    tempWeapon = [[Weapon alloc] initWithName:@"Seal" withEnergyCost:20
                                   usingImage:@"seal.png"
                                   usingSound:_soundEffects[@"vehicle1-shot2"]];
    _player1Vehicle.weapon2 = tempWeapon;
    tempWeapon = [[Weapon alloc] initWithName:@"Seal" withEnergyCost:20
                                   usingImage:@"seal.png"
                                   usingSound:_soundEffects[@"vehicle1-special"]];
    _player1Vehicle.special = tempWeapon;
    tempWeapon = [[Weapon alloc] initWithName:@"Seal" withEnergyCost:20
                                   usingImage:@"seal.png"
                                   usingSound:_soundEffects[@"vehicle2-shot1"]];
    _player2Vehicle.weapon1 = tempWeapon;
    tempWeapon = [[Weapon alloc] initWithName:@"Seal" withEnergyCost:20
                                   usingImage:@"seal.png"
                                   usingSound:_soundEffects[@"vehicle2-shot2"]];
    _player2Vehicle.weapon2 = tempWeapon;
    tempWeapon = [[Weapon alloc] initWithName:@"Seal" withEnergyCost:20
                                   usingImage:@"seal.png"
                                   usingSound:_soundEffects[@"vehicle2-special"]];
    _player2Vehicle.special = tempWeapon;
}

- (void)setUpMenu
{
    CGSize screenSize = [[CCDirector sharedDirector] winSize];
    // Create 3 attack buttons
    CCMenu *controlMenu = [[CCMenu alloc] init];
    controlMenu.position = CGPointMake(screenSize.width / 2, screenSize.height * .75);

    // Create first shot label
    NSString *shotString = [NSString stringWithFormat:SHOT_ONE_LABEL];
    CCLabelTTF *label = [CCLabelTTF labelWithString:shotString
                                           fontName:@"Marker Felt"
                                           fontSize:30];
    CCMenuItemLabel *menuLabel = [CCMenuItemLabel itemWithLabel:label target:self selector:@selector(selectWeapon:)];
    [controlMenu addChild:menuLabel];
    
    // Create second shot label
    shotString = [NSString stringWithFormat:SHOT_TWO_LABEL];
    label = [CCLabelTTF labelWithString:shotString
                               fontName:@"Marker Felt"
                               fontSize:30];
    menuLabel = [CCMenuItemLabel itemWithLabel:label target:self selector:@selector(selectWeapon:)];
    [controlMenu addChild:menuLabel];
    
    // Create special shot label
    shotString = [NSString stringWithFormat:SHOT_SPECIAL_LABEL];
    label = [CCLabelTTF labelWithString:shotString
                               fontName:@"Marker Felt"
                               fontSize:30];
    menuLabel = [CCMenuItemLabel itemWithLabel:label target:self selector:@selector(selectWeapon:)];
    [controlMenu addChild:menuLabel];
    
    // Create fire shot label
    shotString = [NSString stringWithFormat:FIRE_SHOT_LABEL];
    label = [CCLabelTTF labelWithString:shotString
                               fontName:@"Marker Felt"
                               fontSize:30];
    menuLabel = [CCMenuItemLabel itemWithLabel:label block:^(id sender) {
        if (!_isReplaying && [self fire]) {
            [_actionReplayData addObject:FIRE_SHOT_LABEL];
        }
    }];
    
    // Add labels to the menu and align them vertically
    [controlMenu addChild:menuLabel];
    [controlMenu alignItemsVertically];
    
    // Show energy, power, and angle for current vehicle and selected weapon
    label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Energy: %i", _player1Vehicle.energy]
                               fontName:@"Marker Felt"
                               fontSize:20];
    label.color = ccBLACK;
    _energyLabel = [CCMenuItemLabel itemWithLabel:label];
    _energyLabel.position = CGPointMake(-(screenSize.width / 2) + 60, screenSize.width * .12);
    [controlMenu addChild:_energyLabel];
    
    label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Power: %i", _player1Vehicle.selectedWeapon.lastShotPower]
                               fontName:@"Marker Felt"
                               fontSize:20];
    label.color = ccBLACK;
    _shotPowerLabel = [CCMenuItemLabel itemWithLabel:label];
    _shotPowerLabel.position = CGPointMake(-(screenSize.width / 2) + 60, screenSize.width * .07);
    [controlMenu addChild:_shotPowerLabel];
    
    label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Angle: %i", _player1Vehicle.selectedWeapon.lastAngle]
                               fontName:@"Marker Felt"
                               fontSize:20];
    label.color = ccBLACK;
    _angleLabel = [CCMenuItemLabel itemWithLabel:label];
    _angleLabel.position = CGPointMake(-(screenSize.width / 2) + 60, screenSize.width * .02);
    [controlMenu addChild:_angleLabel];
    
    // Create 2 arrows for movement
    _leftArrow = [[CCMenuItemImage alloc] initWithNormalImage:@"arrow_left.png"
                                                selectedImage:@"arrow_left.png" disabledImage:@"arrow_left.png"
                                                        block:^(id sender) {}];
    _rightArrow = [[CCMenuItemImage alloc] initWithNormalImage:@"arrow_right.png"
                                                 selectedImage:@"arrow_right.png" disabledImage:@"arrow_right.png"
                                                         block:^(id sender) {}];
    _leftArrow.position = CGPointMake(-(screenSize.width / 2) + 30, -(screenSize.height / 2) - 40);
    _rightArrow.position = CGPointMake(-(screenSize.width / 2) + 65, -(screenSize.height / 2) - 40);
    _leftArrow.isEnabled = false;
    _rightArrow.isEnabled = false;
    [controlMenu addChild:_leftArrow];
    [controlMenu addChild:_rightArrow];
    
    [self addChild:controlMenu];
}

#pragma mark Gesture Handlers
- (void)handleTwoFingerPanGesture:(UIPanGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded) {
        return;
    }
    
    UIView *view = [[CCDirector sharedDirector] view];
    Vehicle *current = _isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;
    
    if ([gesture velocityInView:view].y < 0 && current.selectedWeapon.lastAngle < current.maxFrontUpperAngle) {
        if (!_isReplaying) {
            [_actionReplayData addObject:INCREASE_ANGLE];
        }
        
        [_angleLabel setString:[NSString stringWithFormat:@"Angle: %i", ++current.selectedWeapon.lastAngle]];
    }
    else if ([gesture velocityInView:view].y > 0 && current.selectedWeapon.lastAngle > current.maxFrontLowerAngle) {
        if (!_isReplaying) {
            [_actionReplayData addObject:DECREASE_ANGLE];
        }
        
        [_angleLabel setString:[NSString stringWithFormat:@"Angle: %i", --current.selectedWeapon.lastAngle]];
    }
}

- (void)handleThreeFingers:(UIPanGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded) {
        return;
    }
    
    UIView *view = [[CCDirector sharedDirector] view];
    Vehicle *current = _isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;
    
    if ([gesture velocityInView:view].x > 0 && current.selectedWeapon.lastShotPower < current.power) {
        if (!_isReplaying) {
            [_actionReplayData addObject:INCREASE_POWER];
        }
        
        [_shotPowerLabel setString:[NSString stringWithFormat:@"Power: %i", ++current.selectedWeapon.lastShotPower]];
    }
    else if ([gesture velocityInView:view].x < 0 && current.selectedWeapon.lastShotPower > 0) {
        if (!_isReplaying) {
            [_actionReplayData addObject:DECREASE_POWER];
        }
        
        [_shotPowerLabel setString:[NSString stringWithFormat:@"Power: %i", --current.selectedWeapon.lastShotPower]];
    }
}

// Temporary method
- (void)handleRotateGesture:(UIRotationGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded) {
        return;
    }
    
    Vehicle *current = _isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;

    if (gesture.velocity > 0 && current.selectedWeapon.lastShotPower < current.power) {
        if (!_isReplaying) {
            [_actionReplayData addObject:INCREASE_POWER];
        }
        
        [_shotPowerLabel setString:[NSString stringWithFormat:@"Power: %i", ++current.selectedWeapon.lastShotPower]];
    }
    else if (gesture.velocity < 0 && current.selectedWeapon.lastShotPower > 0) {
        if (!_isReplaying) {
            [_actionReplayData addObject:DECREASE_POWER];
        }
        
        [_shotPowerLabel setString:[NSString stringWithFormat:@"Power: %i", --current.selectedWeapon.lastShotPower]];
    }
}

#pragma mark Physics/Logic
- (void)selectWeapon:(CCMenuItemLabel *) sender
{
    Vehicle *vehicle = _isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;

    if ([sender.label.string isEqualToString:SHOT_ONE_LABEL] && !_isReplaying && vehicle.selectedWeapon != vehicle.weapon1) {
        [_actionReplayData addObject:SHOT_ONE_LABEL];
        vehicle.selectedWeapon = vehicle.weapon1;
    }
    else if ([sender.label.string isEqualToString:SHOT_TWO_LABEL] && !_isReplaying && vehicle.selectedWeapon != vehicle.weapon2) {
        [_actionReplayData addObject:SHOT_TWO_LABEL];
        vehicle.selectedWeapon = vehicle.weapon2;
    }
    else if ([sender.label.string isEqualToString:SHOT_SPECIAL_LABEL] && !_isReplaying && vehicle.selectedWeapon != vehicle.special) {
        [_actionReplayData addObject:SHOT_SPECIAL_LABEL];
        vehicle.selectedWeapon = vehicle.special;
    }
    
    _angleLabel.string = [NSString stringWithFormat:@"Angle: %i", vehicle.selectedWeapon.lastAngle];
    _shotPowerLabel.string = [NSString stringWithFormat:@"Power: %i", vehicle.selectedWeapon.lastShotPower];
}

/*
//Create the bullets, add them to the list of bullets so they can be referred to later
- (void)createBullets
{
    CCSprite *bullet = [CCSprite spriteWithFile:@"flyingpenguin.png"];
    bullet.position = CGPointMake(250.0f, FLOOR_HEIGHT+190.0f);
    [_panZoomLayer addChild:bullet z:9];
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
    CCDirector* director = [CCDirector sharedDirector];
    
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
    
    if (_isReplaying) {
        [self replayActions];
        return;
    }

    // This IF block should always go immediately after the IF (_isReplaying) block
    if (_turnJustEnded) {
        Vehicle *current = _isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;
        Vehicle *other = !_isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;
        
        // Change labels to reflect the vehicle that is starting his turn
        _energyLabel.string = [NSString stringWithFormat:@"Energy: %i", current.energy];
        _angleLabel.string = [NSString stringWithFormat:@"Angle: %i", current.selectedWeapon.lastAngle];
        _shotPowerLabel.string = [NSString stringWithFormat:@"Power: %i", current.selectedWeapon.lastShotPower];
        
        // Restore energy of vehicle that just ended its turn
        other.energy = other.maxEnergy;
        _energyJustRestored = YES;
                
        // Store the array
        [NSKeyedArchiver archiveRootObject:_actionReplayData toFile:ACTION_SEQUENCE_FILE];
        
        // Load the array
        _actionReplayData = [NSKeyedUnarchiver unarchiveObjectWithFile:ACTION_SEQUENCE_FILE];
        
        // Turn on replay mode
        _isReplaying = YES;
        
        _turnJustEnded = !_turnJustEnded;
    }
    
    // This IF block prevents action events from overlapping when a player turn changes
    if (!_energyJustRestored) {
        [self checkTouchEvents];
    }
    
    _energyJustRestored = NO;
    
    [self step];
    [_actionReplayData addObject:WORLD_STEP];
}

- (void)checkTouchEvents {
    KKInput *input = [KKInput sharedInput];
    
    // Ensure that the current vehicle is facing left when they press the left arrow
    if ([input isAnyTouchOnNode:_leftArrow touchPhase:KKTouchPhaseBegan] && [self move:LEFT_MOVEMENT_BEGAN]) {
        [_actionReplayData addObject:LEFT_MOVEMENT_BEGAN];
    }
    
    // Ensure that the current vehicle is facing right when they press right arrow
    if ([input isAnyTouchOnNode:_rightArrow touchPhase:KKTouchPhaseBegan] && [self move:RIGHT_MOVEMENT_BEGAN]) {
        [_actionReplayData addObject:RIGHT_MOVEMENT_BEGAN];
    }
    
    // Move the vehicle left and drain energy when left arrow is pressed
    if (([input isAnyTouchOnNode:_leftArrow touchPhase:KKTouchPhaseStationary]
         || [input isAnyTouchOnNode:_leftArrow touchPhase:KKTouchPhaseMoved])
        && [self move:LEFT_MOVEMENT_CONTINUE]) {
        
        [_actionReplayData addObject:LEFT_MOVEMENT_CONTINUE];
    }
    
    // Move vehicle right and drain energy when right arrow is pressed
    if (([input isAnyTouchOnNode:_rightArrow touchPhase:KKTouchPhaseStationary]
         || [input isAnyTouchOnNode:_leftArrow touchPhase:KKTouchPhaseMoved])
        && [self move:RIGHT_MOVEMENT_CONTINUE]) {
        
        [_actionReplayData addObject:RIGHT_MOVEMENT_CONTINUE];
    }
}

- (BOOL)move:(NSString *) direction {
    Vehicle *current = _isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;
    b2Body *bodyToMove = _isFirstPlayerTurn ? _player1Vehicle.body : _player2Vehicle.body;
    b2Vec2 currentVec = bodyToMove->GetLinearVelocity();
    
    if (current.energy) {
        if ([direction isEqualToString:LEFT_MOVEMENT_BEGAN]) {
            current.flipX = YES;
        }
        else if ([direction isEqualToString:RIGHT_MOVEMENT_BEGAN]) {
            current.flipX = NO;
        }
        else if ([direction isEqualToString:LEFT_MOVEMENT_CONTINUE]) {
            current.flipX = YES;
            bodyToMove->SetLinearVelocity(b2Vec2(-current.speed * VEHICLE_SPEED_RATIO + currentVec.x, currentVec.y));
        }
        else if ([direction isEqualToString:RIGHT_MOVEMENT_CONTINUE]) {
            current.flipX = NO;
            bodyToMove->SetLinearVelocity(b2Vec2(current.speed *VEHICLE_SPEED_RATIO + currentVec.x, currentVec.y));
        }
        
        // Switch turns when out of energy
        if (!--current.energy) {
            _isFirstPlayerTurn = !_isFirstPlayerTurn;
            _turnJustEnded = YES;
            bodyToMove->SetLinearVelocity(b2Vec2(0, 0)); // Prevents sliding when energy is depleted
        }
        
        // Update energy label
        _energyLabel.string = [NSString stringWithFormat:@"Energy: %i", current.energy];
    }
    
    return YES;
}

- (BOOL)fire {
    Vehicle *current = _isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;
    
    return [current.selectedWeapon executeAttackOnScreen:self];
}

- (void)step {
    float timeStep = 0.03f;
    int32 velocityIterations = 8;
    int32 positionIterations = 1;
    _world->Step(timeStep, velocityIterations, positionIterations);
    
    // Prevent vehicles from flipping over
    [self stabilizeVehicle:_player1Vehicle.body withTimeStep:timeStep];
    [self stabilizeVehicle:_player2Vehicle.body withTimeStep:timeStep];
    
    [self updateBodyPositions];
}

- (void)updateBodyPositions {
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
}

- (void)replayActions {
    Vehicle *current = _isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;
    NSString *action = _actionReplayData[physicsHistoryIndex++];
    
    while (![action isEqualToString:WORLD_STEP]) {
        if ([action isEqualToString:LEFT_MOVEMENT_BEGAN]) {
            [self move:LEFT_MOVEMENT_BEGAN];
        }
        else if ([action isEqualToString:RIGHT_MOVEMENT_BEGAN]) {
            [self move:RIGHT_MOVEMENT_BEGAN];
        }
        else if ([action isEqualToString:LEFT_MOVEMENT_CONTINUE]) {
            [self move:LEFT_MOVEMENT_CONTINUE];
        }
        else if ([action isEqualToString:RIGHT_MOVEMENT_CONTINUE]) {
            [self move:RIGHT_MOVEMENT_CONTINUE];
        }
        else if ([action isEqualToString:DECREASE_ANGLE]) {
            [_angleLabel setString:[NSString stringWithFormat:@"Angle: %i", --current.selectedWeapon.lastAngle]];
        }
        else if ([action isEqualToString:INCREASE_ANGLE]) {
            [_angleLabel setString:[NSString stringWithFormat:@"Angle: %i", ++current.selectedWeapon.lastAngle]];
        }
        else if ([action isEqualToString:DECREASE_POWER]) {
            [_shotPowerLabel setString:[NSString stringWithFormat:@"Power: %i", --current.selectedWeapon.lastShotPower]];
        }
        else if ([action isEqualToString:INCREASE_POWER]) {
            [_shotPowerLabel setString:[NSString stringWithFormat:@"Power: %i", ++current.selectedWeapon.lastShotPower]];
        }
        else if ([action isEqualToString:FIRE_SHOT_LABEL]) {
            [self fire];
        }
        else if ([action isEqualToString:SHOT_ONE_LABEL]) {
            current.selectedWeapon = current.weapon1;
            _angleLabel.string = [NSString stringWithFormat:@"Angle: %i", current.selectedWeapon.lastAngle];
            _shotPowerLabel.string = [NSString stringWithFormat:@"Power: %i", current.selectedWeapon.lastShotPower];
        }
        else if ([action isEqualToString:SHOT_TWO_LABEL]) {
            current.selectedWeapon = current.weapon2;
            _angleLabel.string = [NSString stringWithFormat:@"Angle: %i", current.selectedWeapon.lastAngle];
            _shotPowerLabel.string = [NSString stringWithFormat:@"Power: %i", current.selectedWeapon.lastShotPower];
        }
        else if ([action isEqualToString:SHOT_SPECIAL_LABEL]) {
            current.selectedWeapon = current.special;
            _angleLabel.string = [NSString stringWithFormat:@"Angle: %i", current.selectedWeapon.lastAngle];
            _shotPowerLabel.string = [NSString stringWithFormat:@"Power: %i", current.selectedWeapon.lastShotPower];
        }
        
        action = _actionReplayData[physicsHistoryIndex++];
    }
    
    if (physicsHistoryIndex == _actionReplayData.count) {
        physicsHistoryIndex = 0;
        _actionReplayData = [[NSMutableArray alloc] init];
        _isReplaying = !_isReplaying;
    }
    
    [self step];
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
