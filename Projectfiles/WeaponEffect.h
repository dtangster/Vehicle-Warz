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
    OnImpact
};

@class GameLayer;
@class Weapon;

@interface WeaponEffect : NSObject <NSCopying>

@property (nonatomic) Weapon *affectedWeapon; // The effect applies to this weapon
@property (nonatomic) NSString *soundEffect;
@property (nonatomic) BOOL isRunning; // Is actively running
@property (nonatomic) BOOL isWaitingToStart;
@property (nonatomic) BOOL isWaitingToStop;
@property (nonatomic) BOOL isFinished;
@property (nonatomic) Event startType;
@property (nonatomic) Event stopType;
@property (nonatomic) int startDelay; // This value should not change when set
@property (nonatomic) int stopDelay; // This value should not change when set
@property (nonatomic) int startTimer; // Each new run of the effect will copy startDelay here
@property (nonatomic) int stopTimer; // Each new run of the effect will copy stopDelay here
@property (nonatomic) int damage;

// Initializes variables and determines if the effect should run
- (BOOL)initAndOkToRun;

// The behavior of the weapon from the time it is launched until it is detonated
- (void)executeEffectOnScreen:(GameLayer *) screen;

- (id)copyWithZone:(NSZone *) zone;

@end
