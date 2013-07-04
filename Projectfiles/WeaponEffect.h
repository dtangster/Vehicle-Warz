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

@property (nonatomic) Weapon *weapon; // The effect applies to this weapon
@property (nonatomic) NSString *soundEffect;
@property (nonatomic) BOOL isLinearEffect; // Effects can be less if vehicles are further away
@property (nonatomic) BOOL happensAtLaunch; // Happens as soon as the weapon is launched
@property (nonatomic) BOOL happensOnImpact; // Happens after the first collision with anything
@property (nonatomic) BOOL happensAfterDelay; // Happens after a delay you specify
@property (nonatomic) float startdelay; // Used with happensAfterDelay
@property (nonatomic) BOOL happensAfterDelayOnImpact; // Happens after any collision followed by a delay you specify
@property (nonatomic) float delayOnImpact; // Used with happensAfterDelayOnImpact
@property (nonatomic) BOOL stopAfterDelay; // Stop effects after a delay you specify
@property (nonatomic) float stopDelay; // Used with stopAfterDelay
@property (nonatomic) BOOL stopOnImpact; // Stop effects after the first collision with anything
@property (nonatomic) BOOL stopOnDelayAfterImpact; // Stop effects after any collision followed by a delay you specify
@property (nonatomic) float stopDelayAfterImpact; // Used with stopOnDelayAfterImpact

// The behavior of the weapon from the time it is launched until it is detonated
- (void)executeEffect;

@end
