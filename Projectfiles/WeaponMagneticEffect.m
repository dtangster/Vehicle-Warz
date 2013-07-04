//
//  WeaponMagneticEffect.m
//  Vehicle Warz
//
//  Created by David Tang on 7/3/13.
//
//

#import "WeaponMagneticEffect.h"

BOOL began;

@implementation WeaponMagneticEffect

- (id)initWithDamage:(int) damage
 withAttractionPower:(int) attraction
withAffectedDistance:(float) distance
      isLinearEffect:(BOOL) isLinear
{
    if (self = [super init])
    {
        _attractionPower = attraction;
        _distanceAffected = distance;
    }
    
    return self;
}

- (void)executeEffect
{
    if (!self.isRunning) {
        return;
    }
    if (self.startDelay) {
        self.startDelay--;
    }
    if (began && self.stopDelay && (self.stopType == AfterDelay || self.stopType == OnImpactAfterDelay)) {
        self.stopDelay--;
    }
    if (!self.stopDelay) {
        began = NO;
        self.isRunning = NO;
    }
    
    // Do something here
    
    
    
    // Flag as started so we know to use delay timer if needed
    began = YES;
}

@end
