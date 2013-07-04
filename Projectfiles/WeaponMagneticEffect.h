//
//  WeaponMagneticEffect.h
//  Vehicle Warz
//
//  Created by David Tang on 7/3/13.
//
//

#import "WeaponEffect.h"

@interface WeaponMagneticEffect : WeaponEffect <NSCopying>

@property (nonatomic) int attractionPower; // Negative means repulsion
@property (nonatomic) float distanceAffected;

- (id)initWithAttractionPower:(int) attraction withAffectedDistance:(float) distance;
- (id)copyWithZone:(NSZone *) zone;

@end
