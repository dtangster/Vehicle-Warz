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

@implementation WeaponMagneticEffect

- (id)initWithAttractionPower:(int) attraction withAffectedDistance:(float) distance
{
    if (self = [super init])
    {
        _attractionPower = attraction;
        _distanceAffected = distance;
    }
    
    return self;
}

- (void)executeEffectOnScreen:(GameLayer *) screen
{
    if (!self.isRunning) {
        return;
    }
    else if (!self.isWaitingToStop) {
        self.startTimer = self.startDelay;
        self.stopTimer = self.stopDelay;
    }
    
    if (self.startTimer) {
        self.startTimer--;
        return;
    }
    if (self.isWaitingToStop && self.stopTimer) {
        self.stopTimer--;
    }
    if (!self.stopTimer) {
        self.isWaitingToStop = NO;
        self.isRunning = NO;
        self.startTimer = self.startDelay;
        self.stopTimer = self.stopDelay;
        return;
    }
    
    // Do something here
    
    // Of course this arbitrary action is just for testing
    screen.player2Vehicle.body->ApplyForceToCenter(b2Vec2(0,10));
    
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
