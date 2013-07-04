//
//  WeaponEffect.m
//  Vehicle Warz
//
//  Created by David Tang on 7/3/13.
//
//

#import "WeaponEffect.h"

@implementation WeaponEffect

- (id)copyWithZone:(NSZone *) zone
{
    WeaponEffect *copy = [[WeaponEffect alloc] init];
    
    copy.weapon = _weapon;
    copy.soundEffect = _soundEffect;
    copy.isRunning = _isRunning;
    copy.isWaitingToStop = _isWaitingToStop;
    copy.startType = _startType;
    copy.stopType = _stopType;
    copy.startDelay = _startDelay;
    copy.stopDelay = _stopDelay;
    copy.startTimer = _startDelay;
    copy.stopTimer = _stopDelay;
    copy.damage = _damage;
    
    return copy;
}

@end
