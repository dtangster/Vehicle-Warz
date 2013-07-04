//
//  WeaponMagneticEffect.h
//  Vehicle Warz
//
//  Created by David Tang on 7/3/13.
//
//

#import "WeaponEffect.h"

@interface WeaponMagneticEffect : WeaponEffect

@property (nonatomic) int attractionPower; // Negative means repulsion
@property (nonatomic) float distanceAffected;

- (id)initWithDamage:(int) damage
 withAttractionPower:(int) power
withAffectedDistance:(float) distance
      isLinearEffect:(BOOL) isLinear;

@end
