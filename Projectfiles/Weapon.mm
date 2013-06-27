//
//  Weapon.m
//  Template Penguin
//
//  Created by David Tang on 6/24/13.
//
//

#import "Weapon.h"
#import "Vehicle.h"
#import "GameLayer.h"

#define PTM_RATIO 32.0f

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
        
        // Create clone of itself to shoot because you cannot multiple instances of yourself on the screen.
        // Clones do not have a reference to the original vehicle that wants to use this weapon. Only self
        // has a reference to the original vehicle.
        Weapon *projectile = [[Weapon alloc] initWithName:self.weaponName
                                           withEnergyCost:self.energyCost
                                               usingImage:self.imageFile];
        [screen.panZoomLayer addChild:projectile z:-1];
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        bodyDef.linearDamping = 1;
        bodyDef.angularDamping = 1;
        
        CGPoint pos = [screen toPixels:self.carrier.body->GetPosition()];
        b2Vec2 startVelocity;
        if (self.carrier.flipX) {
            pos.x -= 50;
            startVelocity = b2Vec2(-10, 10);
        }
        else {
            pos.x += 50;
            startVelocity = b2Vec2(10, 10);
        }
        
        bodyDef.position.Set(pos.x/PTM_RATIO, (pos.y + 25)/PTM_RATIO);
        bodyDef.linearVelocity = startVelocity;
        bodyDef.angularVelocity = 60; //In radians
        bodyDef.bullet = true;
        bodyDef.userData = (__bridge void*)projectile; //this tells the Box2D body which sprite to update.
        projectile.body = screen.world->CreateBody(&bodyDef);
        b2CircleShape projectileShape;
        b2FixtureDef projectileFixtureDef;
        projectileShape.m_radius = self.contentSize.width/2.0f/PTM_RATIO;
        projectileFixtureDef.shape = &projectileShape;
        projectileFixtureDef.density = 10.3F; //affects collision momentum and inertia
        projectile.fixture = projectile.body->CreateFixture(&projectileFixtureDef);
        
        // If energy is depleted, refill energy and switch player turns
        if (self.carrier.energy <= 0) {
            screen.isFirstPlayerTurn = !screen.isFirstPlayerTurn;
            screen.turnJustEnded = YES;
            self.carrier.energy = self.carrier.maxEnergy;
        }
        
        screen.energyLabel.string = [NSString stringWithFormat:@"Energy: %i", self.carrier.energy];
    }
    
    return success;
}

@end
