//
//  Weapon.m
//  Vehicle Warz
//
//  Created by David Tang on 6/24/13.
//
//

#import "Weapon.h"
#import "WeaponEffect.h"
#import "Vehicle.h"
#import "GameLayer.h"

#define PTM_RATIO 32.0f
#define PI 3.14159265f
#define POWER_DOWN_SCALE 3.0f

@implementation Weapon

- (id)initWithName:(NSString *) weaponName
        usingImage:(NSString *) fileName
        usingSound:(NSString *) weaponSound
      usingBodyDef:(b2BodyDef) bodyDef
    withEnergyCost:(int) energyCost
          isCircle:(BOOL) isCircle;
{
    if ((self = [super initWithFile:fileName]))
    {
        _weaponName = weaponName;
        _imageFile = fileName;
        _bodyDef = bodyDef;
        _isCircle = isCircle;
        _weaponSound = weaponSound;
        _energyCost = energyCost;
        _lastShotPower = 0;
        _lastAngle = 0;
        _lastRotation = 30;
        _effects = [NSMutableArray array];
        [[SimpleAudioEngine sharedEngine] preloadEffect:weaponSound];
    }
    
    return self;
}

- (BOOL)executeAttackOnScreen:(GameLayer *)screen
{
    BOOL success = NO;
    
    if (_carrier.energy >= _energyCost) {
        _carrier.energy -= _energyCost;
        success = YES;
        
        // Create clone of itself to shoot because you cannot have multiple instances of yourself on the screen.
        Weapon *clone = [[Weapon alloc] initWithName:_weaponName
                                          usingImage:_imageFile
                                          usingSound:_weaponSound
                                        usingBodyDef:_bodyDef
                                      withEnergyCost:_energyCost
                                            isCircle:_isCircle
                         ];
        
        if (_isPersistentWeapon) {
            [screen.persistingProjectiles addObject: clone];
        }
        else {
            [screen.activeProjectiles addObject: clone];
        }
        
        clone.carrier = _carrier;
        [screen.panZoomLayer addChild:clone];
        
        CGPoint pos = [screen toPixels:clone.carrier.body->GetPosition()];
        b2BodyDef tempBodyDef = _bodyDef;
        
        if (clone.carrier.flipX) {
            pos.x -= 50;
            tempBodyDef.angularVelocity = -_lastRotation; // In radians
        }
        else {
            pos.x += 50;
            tempBodyDef.angularVelocity = _lastRotation; // In radians
        }
        
        tempBodyDef.position.Set(pos.x / PTM_RATIO, (pos.y + 25) / PTM_RATIO);
        tempBodyDef.linearVelocity = [self calculateInitialVector];
        tempBodyDef.userData = (__bridge void*)clone; // This tells the Box2D body which sprite to update.
        clone.body = screen.world->CreateBody(&tempBodyDef);
        
        // Create a physical body for the projectile
        b2CircleShape projectileShape;
        b2FixtureDef projectileFixtureDef;
        
        if (_isCircle) {
            b2CircleShape circle;
            circle.m_radius = clone.contentSize.width / 2.0f / PTM_RATIO;
            projectileFixtureDef.shape = &circle;
        }
        else
        {
            
            b2PolygonShape box;
            box.SetAsBox(clone.contentSize.width / 2.0f / PTM_RATIO,
                         clone.contentSize.height / 2.0f / PTM_RATIO);
            projectileFixtureDef.shape = &box;
        }
        
        projectileShape.m_radius = clone.contentSize.width/2.0f/PTM_RATIO;
        projectileFixtureDef.shape = &projectileShape;
        projectileFixtureDef.density = 0.3F; // Affects collision momentum and inertia
        clone.fixture = clone.body->CreateFixture(&projectileFixtureDef);
        [[SimpleAudioEngine sharedEngine] playEffect:_weaponSound];
        
        // Create clones of weapon effects
        for (WeaponEffect *effect in _effects) {
            [clone.effects addObject:[effect copy]];
            effect.affectedWeapon = clone;
        }
        [self notifyEffectsWithStartEvent:OnLaunch];
        
        // If energy is depleted, refill energy and switch player turns
        if (clone.carrier.energy <= 0) {
            screen.isFirstPlayerTurn = !screen.isFirstPlayerTurn;
            screen.turnJustEnded = YES;
        }
        
        screen.energyLabel.string = [NSString stringWithFormat:@"Energy: %i", clone.carrier.energy];
    }
    
    return success;
}

- (void)notifyEffectsWithStartEvent:(Event) type
{
    for (WeaponEffect *effect in _effects) {
        if (effect.startType == type) {
            effect.isRunning = YES;
        }
    }
}
- (void)notifyEffectsWithStopEvent:(Event) type
{
    for (WeaponEffect *effect in _effects) {
        if (effect.stopType == type) {
            effect.isRunning = NO;
        }
    }
}

// Weapon to Vehicle collisions from ContactListener will be delegated to this method
- (void)damageVehicle:(Vehicle *) vehicle
      withContactData:(b2Contact *) contact
          withImpulse:(const b2ContactImpulse *) impulse
{
    NSLog(@"Collision from weapon to vehicle detected");
    [self notifyEffectsWithStartEvent:OnImpact];
}

- (b2Vec2)calculateInitialVector
{
    float x;
    float y = sin(_lastAngle * PI / 180) * _lastShotPower / POWER_DOWN_SCALE;
    
    if (_carrier.flipX) {
        x = cos(PI - ((_lastAngle + _carrier.rotation) * PI / 180)) * _lastShotPower / POWER_DOWN_SCALE;
    }
    else {
        x = cos((_lastAngle + _carrier.rotation) * PI / 180) * _lastShotPower / POWER_DOWN_SCALE;
    }
    
    return b2Vec2(x, y);
}

- (void)addEffect:(WeaponEffect *) effect
{
    [_effects addObject:effect];
    effect.affectedWeapon = self;
}

@end
