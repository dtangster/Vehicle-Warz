//
//  WeaponMagneticEffect.m
//  Vehicle Warz
//
//  Created by David Tang on 7/3/13.
//
//

#import "WeaponMagneticEffect.h"

@implementation WeaponMagneticEffect

- (id)initWithDamage:(int) damage
 withAttractionPower:(int) attraction
withAffectedDistance:(float) distance
      isLinearEffect:(BOOL) isLinear
{
    if (self = [super init])
    {
        _damage = damage;
        _attractionPower = attraction;
        _distanceAffected = distance;
    }
    
    return self;
}

- (void)executeEffect
{
    if (self.happensAtLaunch) {
        
    }
    else if (self.happensAfterDelay) {
        
    }
    else if (self.happensOnImpact) {
        
    }
    else if (self.happensAfterDelayOnImpact) {
        
    }
    
    if (self.stopAfterDelay) {
        
    }
    else if (self.stopOnImpact) {
        
    }
    else if (self.stopOnDelayAfterImpact) {
        
    }
}

@end
