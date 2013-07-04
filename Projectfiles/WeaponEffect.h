//
//  WeaponEffect.h
//  Vehicle Warz
//
//  Created by David Tang on 7/3/13.
//
//

#import <Foundation/Foundation.h>

@class Weapon;

@interface WeaponEffect : NSObject

@property (nonatomic) Weapon *affectedOn; // The effect applies to this weapon

// The behavior of the weapon from the time it is launched until it is detonated
- (void)executeEffects;

@end
