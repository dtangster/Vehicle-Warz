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

@implementation WeaponMagneticEffect

- (id)initWithAttractionPower:(float) attraction withAffectedDistance:(float) distance
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
    float distance = ccpDistance(bodyPos, shotPos);
    float newX = ((shotPos.x - bodyPos.x) * _attractionPower) / (distance * distance);
    float newY = ((shotPos.y - bodyPos.y) * _attractionPower) / (distance * distance) ;
    b2Vec2 attractionVec = b2Vec2(newX, newY);

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
