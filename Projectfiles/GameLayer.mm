/*
 * Kobold2D™ --- http://www.kobold2d.org
 *
 * Copyright (c) 2010-2011 Steffen Itterheim.
 * Released under MIT License in Germany (LICENSE-Kobold2D.txt).
 */

#import "GameLayer.h"
#import "Vehicle.h"
#import "Weapon.h"
#import "WeaponEffect.h"
#import "WeaponMagneticEffect.h"
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

// UIKit Gestures
UIPanGestureRecognizer *twoFingerPanGesture;
UIPanGestureRecognizer *threeFingerPanGesture;

// Temporary
UIRotationGestureRecognizer *rotateGesture;

// Used for playing back actions of a vehicle
NSUInteger physicsHistoryIndex = 0;

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
        
        CGSize screenSize = [CCDirector sharedDirector].winSize;
        
        // Construct a world object, which will hold and simulate the rigid bodies.
        b2Vec2 gravity = b2Vec2(0.0f, -10.0f);
        _world = new b2World(gravity);
        _world->SetAllowSleeping(YES);
        //world->SetContinuousPhysics(YES);

        // Create an object that will check for collisions
        _contactListener = new ContactListener();
        _world->SetContactListener(_contactListener);

        glClearColor(0.1f, 0.0f, 0.2f, 1.0f);

        // Set up game height and width
        b2Vec2 lowerLeftCorner = b2Vec2(0,FLOOR_HEIGHT/PTM_RATIO);
        b2Vec2 lowerRightCorner = b2Vec2(screenSize.width * 4.0f / PTM_RATIO, FLOOR_HEIGHT / PTM_RATIO);
        b2Vec2 upperLeftCorner = b2Vec2(0,screenSize.height * 4.0f / PTM_RATIO);
        b2Vec2 upperRightCorner = b2Vec2(screenSize.width * 4.0f / PTM_RATIO, screenSize.height * 4.0f / PTM_RATIO);

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

        // Initialize arrays
        _activeProjectiles = [NSMutableArray array];
        _persistingProjectiles = [NSMutableArray array];
        _actionReplayData = [NSMutableArray array];
        _timerFrames = [NSMutableArray array];
        
        // Load sound effects
        _soundEffects = [[NSDictionary alloc] initWithContentsOfFile:@"sound_effects.plist"];
        
        [self addChild:_panZoomLayer];
        [self setUpSpriteSheets];
        [self setUpGestures];
        [self setUpWeapons];
        [self setUpMenu];
        _isFirstPlayerTurn = YES;
        
        // Schedules a call to the update method every frame
        [self scheduleUpdate];
    }

    return self;
}

#pragma mark Setups
- (void)setUpSpriteSheets
{
    CGSize screenSize = [CCDirector sharedDirector].winSize;
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

    // Set up sprite sheets for countdown timer
    CCSpriteBatchNode *spriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"timer.png"];
    CCSpriteFrameCache *frameCache = [CCSpriteFrameCache sharedSpriteFrameCache];
    [frameCache addSpriteFramesWithFile: @"timer.plist"];
    [self addChild:spriteSheet];
    
    for(int i = 10; i >= 1; --i)
    {
        [_timerFrames addObject:[frameCache spriteFrameByName: [NSString stringWithFormat:@"%d.png", i]]];
    }
    
    _timer = [CCSprite spriteWithSpriteFrameName:@"10.png"];
    _timer.position = CGPointMake(screenSize.width - 25, screenSize.height - 25);
    
    // Create an animation from the set of frames
    _countDown = [CCAnimation animationWithFrames: _timerFrames delay:1.0f];
    
    //Create an action with the animation that can then be assigned to a sprite
    //_decrementTimer = [CCAnimate actionWithAnimation:_countDown restoreOriginalFrame:NO];
    _decrementTimer = [CCRepeatForever actionWithAction: [CCAnimate actionWithAnimation:_countDown restoreOriginalFrame:NO]];
    
    
    [_timer runAction:_decrementTimer];
    [self addChild:_timer];
}

- (void)setUpGestures
{
    twoFingerPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                  action:@selector(handleTwoFingerPanGesture:)];
    [twoFingerPanGesture setMinimumNumberOfTouches:2];
    [twoFingerPanGesture setMaximumNumberOfTouches:2];
    threeFingerPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                 action:@selector(handleThreeFingerPanGesture:)];
    [threeFingerPanGesture setMinimumNumberOfTouches:3];
    [threeFingerPanGesture setMaximumNumberOfTouches:3];
    
    // Temporary
    rotateGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self
                                                                 action:@selector(handleRotateGesture:)];    
    [[[CCDirector sharedDirector] view] addGestureRecognizer:twoFingerPanGesture];
    [[[CCDirector sharedDirector] view] addGestureRecognizer:threeFingerPanGesture];
    
    // Temporary
    [[[CCDirector sharedDirector] view] addGestureRecognizer:rotateGesture];
}

- (void)setUpWeapons
{
    b2BodyDef bodyDef = [self createBodyDefWithType:b2_dynamicBody withLinearDamping:1.0 withAngularDamping:1.0];
    
    // Create a temporary seal weapon and assign to all weapon shots for both players
    Weapon *tempWeapon = [[Weapon alloc] initWithName:@"Seal"
                                           usingImage:@"seal.png"
                                           usingSound:_soundEffects[@"vehicle1-shot1"]
                                        usingBodyDef:bodyDef
                                       withEnergyCost:20
                                             isCircle:YES];
    _player1Vehicle.weapon1 = tempWeapon;
    tempWeapon = tempWeapon = [[Weapon alloc] initWithName:@"Seal"
                                                usingImage:@"seal.png"
                                                usingSound:_soundEffects[@"vehicle1-shot1"]
                                              usingBodyDef:bodyDef
                                            withEnergyCost:20
                                                  isCircle:YES];
    _player1Vehicle.weapon2 = tempWeapon;
    tempWeapon = tempWeapon = [[Weapon alloc] initWithName:@"Seal"
                                                usingImage:@"seal.png"
                                                usingSound:_soundEffects[@"vehicle1-shot1"]
                                              usingBodyDef:bodyDef
                                            withEnergyCost:20
                                                  isCircle:YES];
    _player1Vehicle.special = tempWeapon;
    tempWeapon = tempWeapon = [[Weapon alloc] initWithName:@"Seal"
                                                usingImage:@"seal.png"
                                                usingSound:_soundEffects[@"vehicle1-shot1"]
                                              usingBodyDef:bodyDef
                                            withEnergyCost:20
                                                  isCircle:YES];
    _player2Vehicle.weapon1 = tempWeapon;
    tempWeapon = tempWeapon = [[Weapon alloc] initWithName:@"Seal"
                                                usingImage:@"seal.png"
                                                usingSound:_soundEffects[@"vehicle1-shot1"]
                                              usingBodyDef:bodyDef
                                            withEnergyCost:20
                                                  isCircle:YES];
    _player2Vehicle.weapon2 = tempWeapon;
    tempWeapon = tempWeapon = [[Weapon alloc] initWithName:@"Seal"
                                                usingImage:@"seal.png"
                                                usingSound:_soundEffects[@"vehicle1-shot1"]
                                              usingBodyDef:bodyDef
                                            withEnergyCost:20
                                                  isCircle:YES];
    _player2Vehicle.special = tempWeapon;
    
    // PROTOTYPE TESTING OF WEAPONEFFECT
    WeaponEffect *effect = [[WeaponMagneticEffect alloc] initWithAttractionPower:1 withAffectedDistance:10];
    effect.startType = OnImpact;
    effect.startDelay = 20;
    effect.stopDelay = 20;
    [_player1Vehicle.weapon1 addEffect:effect];
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
    
    // Show health, shield, energy, power, and angle for current vehicle and selected weapon
    label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Health: %i", _player1Vehicle.health]
                               fontName:@"Marker Felt"
                               fontSize:20];
    label.color = ccBLACK;
    _healthLabel = [CCMenuItemLabel itemWithLabel:label];
    _healthLabel.position = CGPointMake(-(screenSize.width / 2) + 60, 60);
    [controlMenu addChild:_healthLabel];
    
    label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Shield: %i", _player1Vehicle.shield]
                               fontName:@"Marker Felt"
                               fontSize:20];
    label.color = ccBLACK;
    _shieldLabel = [CCMenuItemLabel itemWithLabel:label];
    _shieldLabel.position = CGPointMake(-(screenSize.width / 2) + 60, 35);
    [controlMenu addChild:_shieldLabel];
    
    label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Energy: %i", _player1Vehicle.energy]
                               fontName:@"Marker Felt"
                               fontSize:20];
    label.color = ccBLACK;
    _energyLabel = [CCMenuItemLabel itemWithLabel:label];
    _energyLabel.position = CGPointMake(-(screenSize.width / 2) + 60, 10);
    [controlMenu addChild:_energyLabel];
    
    label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Power: %i", _player1Vehicle.selectedWeapon.lastShotPower]
                               fontName:@"Marker Felt"
                               fontSize:20];
    label.color = ccBLACK;
    _shotPowerLabel = [CCMenuItemLabel itemWithLabel:label];
    _shotPowerLabel.position = CGPointMake(-(screenSize.width / 2) + 60, -15);
    [controlMenu addChild:_shotPowerLabel];
    
    label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Angle: %i", _player1Vehicle.selectedWeapon.lastAngle]
                               fontName:@"Marker Felt"
                               fontSize:20];
    label.color = ccBLACK;
    _angleLabel = [CCMenuItemLabel itemWithLabel:label];
    _angleLabel.position = CGPointMake(-(screenSize.width / 2) + 60, -40);
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
    if (_isReplaying || gesture.state == UIGestureRecognizerStateEnded) {
        return;
    }
    
    UIView *view = [[CCDirector sharedDirector] view];
    Vehicle *current = _isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;
    
    if ([gesture velocityInView:view].y < 0 && current.selectedWeapon.lastAngle < current.maxFrontUpperAngle) {
        [_actionReplayData addObject:INCREASE_ANGLE];
        [_angleLabel setString:[NSString stringWithFormat:@"Angle: %i", ++current.selectedWeapon.lastAngle]];
    }
    else if ([gesture velocityInView:view].y > 0 && current.selectedWeapon.lastAngle > current.maxFrontLowerAngle) {
        [_actionReplayData addObject:DECREASE_ANGLE];
        [_angleLabel setString:[NSString stringWithFormat:@"Angle: %i", --current.selectedWeapon.lastAngle]];
    }
}

- (void)handleThreeFingerPanGesture:(UIPanGestureRecognizer *)gesture
{
    if (_isReplaying || gesture.state == UIGestureRecognizerStateEnded) {
        return;
    }
    
    UIView *view = [[CCDirector sharedDirector] view];
    Vehicle *current = _isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;
    
    if ([gesture velocityInView:view].x > 0 && current.selectedWeapon.lastShotPower < current.power) {
        [_actionReplayData addObject:INCREASE_POWER];
        [_shotPowerLabel setString:[NSString stringWithFormat:@"Power: %i", ++current.selectedWeapon.lastShotPower]];
    }
    else if ([gesture velocityInView:view].x < 0 && current.selectedWeapon.lastShotPower > 0) {
        [_actionReplayData addObject:DECREASE_POWER];
        [_shotPowerLabel setString:[NSString stringWithFormat:@"Power: %i", --current.selectedWeapon.lastShotPower]];
    }
}

// Temporary method
- (void)handleRotateGesture:(UIRotationGestureRecognizer *)gesture
{
    if (_isReplaying || gesture.state == UIGestureRecognizerStateEnded) {
        return;
    }
    
    Vehicle *current = _isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;

    if (gesture.velocity > 0 && current.selectedWeapon.lastShotPower < current.power) {
        [_actionReplayData addObject:INCREASE_POWER];
        [_shotPowerLabel setString:[NSString stringWithFormat:@"Power: %i", ++current.selectedWeapon.lastShotPower]];
    }
    else if (gesture.velocity < 0 && current.selectedWeapon.lastShotPower > 0) {
        [_actionReplayData addObject:DECREASE_POWER];
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

- (void)update:(ccTime)delta
{
    // Will probably use this variable later for implementing automatic panning
    CCDirector* director = [CCDirector sharedDirector];
    
    // Keep running this IF block when the game is in replay mode
    if (_isReplaying) {
        [self replayActions];
        return;
    }

    if ([_decrementTimer isDone]) {
        _turnJustEnded = YES;
        _isFirstPlayerTurn = !_isFirstPlayerTurn;
    }
    
    // This IF block should always go immediately after the IF (_isReplaying) block
    if (_turnJustEnded) {
        Vehicle *current = _isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;
        Vehicle *other = !_isFirstPlayerTurn ? _player1Vehicle : _player2Vehicle;
        
        // Change labels to reflect the vehicle that is starting his turn
        _healthLabel.string = [NSString stringWithFormat:@"Health: %i", current.health];
        _shieldLabel.string = [NSString stringWithFormat:@"Shield: %i", current.shield];
        _energyLabel.string = [NSString stringWithFormat:@"Energy: %i", current.energy];
        _angleLabel.string = [NSString stringWithFormat:@"Angle: %i", current.selectedWeapon.lastAngle];
        _shotPowerLabel.string = [NSString stringWithFormat:@"Power: %i", current.selectedWeapon.lastShotPower];
        
        // Restore shields of vehicle beginning its turn
        other.shield = other.maxShield;
        
        // Restore energy of vehicle that just ended its turn
        other.energy = other.maxEnergy;
                
        // Store the array
        [NSKeyedArchiver archiveRootObject:_actionReplayData toFile:ACTION_SEQUENCE_FILE];
        
        // Load the array
        _actionReplayData = [NSKeyedUnarchiver unarchiveObjectWithFile:ACTION_SEQUENCE_FILE];
        
        // Turn on replay mode
        _isReplaying = YES;
        
        // Reset timer
        [_timer stopAllActions];
        [_timer runAction:_decrementTimer];
        
        _turnJustEnded = !_turnJustEnded;
        _vehicleTurnJustBegan = YES;
    }
    
    // This IF block prevents action events from overlapping when a player turn changes
    if (!_vehicleTurnJustBegan) {
        [self checkTouchEvents];
    }
    
    _vehicleTurnJustBegan = NO;
    
    // Apply weapon effects and remove finished effects
    [self applyWeaponEffects];
    
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
            
            if (-bodyToMove->GetLinearVelocity().x <= current.speed * VEHICLE_SPEED_RATIO) {
                bodyToMove->ApplyForceToCenter(b2Vec2(-current.speed * VEHICLE_SPEED_RATIO + currentVec.x, currentVec.y));
            }
        }
        else if ([direction isEqualToString:RIGHT_MOVEMENT_CONTINUE]) {
            current.flipX = NO;
            
            if (bodyToMove->GetLinearVelocity().x <= current.speed * VEHICLE_SPEED_RATIO) {
                bodyToMove->ApplyForceToCenter(b2Vec2(current.speed * VEHICLE_SPEED_RATIO + currentVec.x, currentVec.y));
            }
        }
        
        // Switch turns when out of energy
        if (!--current.energy) {
            _isFirstPlayerTurn = !_isFirstPlayerTurn;
            _turnJustEnded = YES;
            //bodyToMove->SetLinearVelocity(b2Vec2(0, 0)); // Prevents sliding when energy is depleted, but resets forces
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

- (void)applyWeaponEffects {
    NSMutableArray *weaponsDestroyed = [NSMutableArray array];
    
    for (Weapon *weapon in _activeProjectiles) {
        if (weapon.body == nil) {
            [weaponsDestroyed addObject:weapon];
            continue;
        }
        
        for (WeaponEffect *effect in weapon.effects) {
            [effect executeEffectOnScreen:self];
            
            if (effect.isFinished) {
                [weapon.effects removeObject:effect];
            }
        }
    }
    
    [_activeProjectiles removeObjectsInArray:weaponsDestroyed];
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
        _actionReplayData = [NSMutableArray array];
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

// Convenience method to create a body definition
- (b2BodyDef)createBodyDefWithType:(b2BodyType) type
                 withLinearDamping:(float) linearDamp
                withAngularDamping:(float) angularDamp
{
    b2BodyDef bodyDef;
    
    bodyDef.type = type;
    bodyDef.linearDamping = linearDamp;
    bodyDef.angularDamping = angularDamp;
    bodyDef.bullet = true;
    
    return bodyDef;
}

// Convenience method to convert a b2Vec2 to a CGPoint
- (CGPoint)toPixels:(b2Vec2)vec
{
    return ccpMult(CGPointMake(vec.x, vec.y), PTM_RATIO);
}

@end
