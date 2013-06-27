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
        self.energyCost = energyCost;
    }
    
    return self;
}

-(BOOL) executeAttack;
{
    BOOL success = NO;
    
    if (self.carrier.energy >= self.energyCost) {
        self.carrier.energy -= self.energyCost;
        success = YES;
        
        //TO-DO: Add general implementation to execute an attack here
        GameLayer *gameLayer = (GameLayer *) self.carrier.parent;
        CCSprite *projectile = [CCSprite spriteWithFile:@"seal.png"];
        [gameLayer.panZoomLayer addChild:projectile z:-1];

        //[gameLayer.panZoomLayer addChild:self z:-1];
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        bodyDef.linearDamping = 1;
        bodyDef.angularDamping = 1;
        
        CGPoint pos = [gameLayer toPixels:self.carrier.body->GetPosition()];
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
        bodyDef.userData = (__bridge void*)self; //this tells the Box2D body which sprite to update.
        self.body = gameLayer.world->CreateBody(&bodyDef);
        b2CircleShape projectileShape;
        b2FixtureDef projectileFixtureDef;
        projectileShape.m_radius = self.contentSize.width/2.0f/PTM_RATIO;
        projectileFixtureDef.shape = &projectileShape;
        projectileFixtureDef.density = 10.3F; //affects collision momentum and inertia
        self.fixture = self.body->CreateFixture(&projectileFixtureDef);
        
        self.carrier.energy -= self.energyCost;
        if (self.carrier.energy == 0) {
            gameLayer.isFirstPlayerTurn = !gameLayer.isFirstPlayerTurn;
            gameLayer.turnJustEnded = YES;
            self.carrier.energy = self.carrier.maxEnergy;
        }
        
        gameLayer.energyLabel.string = [NSString stringWithFormat:@"Energy: %i", self.carrier.energy];
    }
    
    return success;
}

@end
