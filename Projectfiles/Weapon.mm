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
        self.weaponName = weaponName;
        self.imageFile = fileName;
        self.energyCost = energyCost;
    }
    
    return self;
}

-(BOOL) executeAttackOnScreen:(GameLayer *)screen
{
    BOOL success = NO;
    
    if (self.carrier.energy >= self.energyCost) {
        self.carrier.energy -= self.energyCost;
        success = YES;
        
        // Create clone of itself to shoot because you cannot have multiple instances of yourself on the screen.
        Weapon *clone = [[Weapon alloc] initWithName:self.weaponName
                                           withEnergyCost:self.energyCost
                                               usingImage:self.imageFile];
        clone.carrier = self.carrier;
        [screen.panZoomLayer addChild:clone z:-1];
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        bodyDef.linearDamping = 1;
        bodyDef.angularDamping = 1;
        
        CGPoint pos = [screen toPixels:clone.carrier.body->GetPosition()];
        
        if (clone.carrier.flipX) {
            pos.x -= 50;
            bodyDef.angularVelocity = -30; // In radians
        }
        else {
            pos.x += 50;
            bodyDef.angularVelocity = 30; // In radians
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
        projectileFixtureDef.density = 10.3F; // Affects collision momentum and inertia
        clone.fixture = clone.body->CreateFixture(&projectileFixtureDef);
        
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
    float y = sin(_carrier.lastAngle * PI / 180) * _carrier.lastShotPower / POWER_DOWN_SCALE;
    
    if (_carrier.flipX) {
        x = cos(PI - ((_carrier.lastAngle + _carrier.rotation) * PI / 180)) * _carrier.lastShotPower / POWER_DOWN_SCALE;
    }
    else {
        x = cos((_carrier.lastAngle + _carrier.rotation) * PI / 180) * _carrier.lastShotPower / POWER_DOWN_SCALE;
    }
    
    return b2Vec2(x, y);
}

@end
