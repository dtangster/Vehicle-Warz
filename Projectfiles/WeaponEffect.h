//
//  WeaponEffect.h
//  Vehicle Warz
//
//  Created by David Tang on 7/3/13.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, Event)
{
    OnLaunch,
    AfterDelay,
    OnImpact,
    OnImpactAfterDelay
};

@class Weapon;

@interface WeaponEffect : NSObject

@property (nonatomic) Weapon *weapon; // The effect applies to this weapon
@property (nonatomic) NSString *soundEffect;
@property (nonatomic) BOOL isRunning;
@property (nonatomic) Event startType;
@property (nonatomic) Event stopType;
@property (nonatomic) float startDelay; // Used only if startType is AfterDelay or OnImpactAfterDelay
@property (nonatomic) float stopDelay; // Used only if stopType is AfterDelay or OnImpactAfterDelay
@property (nonatomic) int damage;

// The behavior of the weapon from the time it is launched until it is detonated
- (void)executeEffect;

@end
