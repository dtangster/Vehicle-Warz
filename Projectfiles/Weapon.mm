//
//  Weapon.m
//  Template Penguin
//
//  Created by David Tang on 6/24/13.
//
//

#include "math.h"

#import "Weapon.h"
#import "Vehicle.h"
#import "GameLayer.h"

#define PTM_RATIO 32.0f
#define PI 3.14159265
#define POWER_DOWN_SCALE 3

@implementation Weapon

-(id) initWithName:(NSString *) weaponName withEnergyCost:(int) energyCost usingImage:(NSString *) fileName
{
    if ((self = [super initWithFile:fileName]))
    {
        _weaponName = weaponName;
        _imageFile = fileName;
        _energyCost = energyCost;
        _lastShotPower = 0;
        _lastAngle = 0;
        _lastRotation = 30;
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"explo2.wav"];
    }
    
    return self;
}

-(BOOL) executeAttackOnScreen:(GameLayer *)screen
{
    BOOL success = NO;
    
    if (_carrier.energy >= _energyCost) {
        _carrier.energy -= _energyCost;
        success = YES;
        
        // Create clone of itself to shoot because you cannot have multiple instances of yourself on the screen.
        Weapon *clone = [[Weapon alloc] initWithName:_weaponName
                                           withEnergyCost:_energyCost
                                               usingImage:_imageFile];
        clone.carrier = _carrier;
        [screen.panZoomLayer addChild:clone z:-1];
        b2BodyDef bodyDef;
        bodyDef.type = _carrier.body->GetType();
        bodyDef.linearDamping = _carrier.body->GetLinearDamping();
        bodyDef.angularDamping = _carrier.body->GetAngularDamping();
        
        CGPoint pos = [screen toPixels:clone.carrier.body->GetPosition()];
        
        if (clone.carrier.flipX) {
            pos.x -= 50;
            bodyDef.angularVelocity = -_lastRotation; // In radians
        }
        else {
            pos.x += 50;
            bodyDef.angularVelocity = _lastRotation; // In radians
        }
        
        bodyDef.position.Set(pos.x/PTM_RATIO, (pos.y + 25)/PTM_RATIO);
        bodyDef.linearVelocity = [self calculateInitialVector];
        bodyDef.bullet = true;
        bodyDef.userData = (__bridge void*)clone; // This tells the Box2D body which sprite to update.
        clone.body = screen.world->CreateBody(&bodyDef);
        b2CircleShape projectileShape;
        b2FixtureDef projectileFixtureDef;
        projectileShape.m_radius = clone.contentSize.width/2.0f/PTM_RATIO;
        projectileFixtureDef.shape = &projectileShape;
        projectileFixtureDef.density = 0.3F; // Affects collision momentum and inertia
        clone.fixture = clone.body->CreateFixture(&projectileFixtureDef);
        [[SimpleAudioEngine sharedEngine] playEffect:@"explo2.wav"];
        
        // If energy is depleted, refill energy and switch player turns
        if (clone.carrier.energy <= 0) {
            screen.isFirstPlayerTurn = !screen.isFirstPlayerTurn;
            screen.turnJustEnded = YES;
        }
        
        screen.energyLabel.string = [NSString stringWithFormat:@"Energy: %i", clone.carrier.energy];
    }
    
    return success;
}

-(b2Vec2) calculateInitialVector
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

@end
