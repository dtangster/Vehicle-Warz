//
//  WeaponMagneticEffect.m
//  Vehicle Warz
//
//  Created by David Tang on 7/3/13.
//
//

#import "WeaponMagneticEffect.h"
#import "GameLayer.h"
#import "Vehicle.h"
#import "Weapon.h"

#define PTM_RATIO 32.0f

@implementation WeaponMagneticEffect

- (id)initWithAttractionPower:(int) attraction withAffectedDistance:(float) distance
{
    if (self = [super init])
    {
        self.isWaitingToStart = YES;
        _attractionPower = attraction;
        _distanceAffected = distance;
    }
    
    return self;
}

- (void)executeEffectOnScreen:(GameLayer *) screen
{
    if (![self initAndOkToRun]) {
        return;
    }
    
    // Do something here
    
    Vehicle *other = !screen.isFirstPlayerTurn ? screen.player1Vehicle : screen.player2Vehicle;
    CGPoint bodyPos = [screen toPixels:other.body->GetPosition()];
    CGPoint shotPos = self.affectedWeapon.position;
    b2Vec2 attractionVec = b2Vec2(shotPos.x - bodyPos.x , shotPos.y - bodyPos.y);

    other.body->ApplyForceToCenter(attractionVec);
    
    // Flag as started so we know to use delay timer if needed
    self.isWaitingToStop = YES;
}

- (id)copyWithZone:(NSZone *) zone
{
    WeaponMagneticEffect *copy = [super init];
    
    copy.attractionPower = _attractionPower;
    copy.distanceAffected = _distanceAffected;
    
    return copy;
}

@end
