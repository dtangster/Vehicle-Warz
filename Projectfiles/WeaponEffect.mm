//
//  WeaponEffect.m
//  Vehicle Warz
//
//  Created by David Tang on 7/3/13.
//
//

#import "WeaponEffect.h"

@implementation WeaponEffect

- (BOOL)initAndOkToRun
{
    if (!self.isRunning) {
        return NO;
    }
    else if (self.isWaitingToStart) {
        self.startTimer = self.startDelay;
        self.stopTimer = self.stopDelay;
        self.isWaitingToStart = NO;
    }
    
    if (self.startTimer) {
        self.startTimer--;
        return NO;
    }
    if (self.isWaitingToStop && self.stopTimer) {
        self.stopTimer--;
    }
    if (!self.stopTimer) {
        self.isWaitingToStart = YES;
        self.isWaitingToStop = NO;
        self.isRunning = NO;
        self.isFinished = YES;
        return NO;
    }
    
    return YES;
}

- (id)copyWithZone:(NSZone *) zone
{
    WeaponEffect *copy = [[WeaponEffect alloc] init];
    
    copy.affectedWeapon = _affectedWeapon;
    copy.soundEffect = _soundEffect;
    copy.isRunning = _isRunning;
    copy.isWaitingToStart = _isWaitingToStart;
    copy.isWaitingToStop = _isWaitingToStop;
    copy.isFinished = _isFinished;
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
