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
    else if (self.stopTimer) {
        self.stopTimer--;
        return YES;
    }
    else {
        self.isRunning = NO;
        self.isFinished = YES;
        return NO;
    }
}

- (id)copyWithZone:(NSZone *) zone
{
    WeaponEffect *copy = [[WeaponEffect alloc] init];
    
    copy.affectedWeapon = _affectedWeapon;
    copy.soundEffect = _soundEffect;
    copy.isRunning = _isRunning;
    copy.isWaitingToStart = _isWaitingToStart;
    copy.isFinished = _isFinished;
    copy.startType = _startType;
    copy.startDelay = _startDelay;
    copy.stopDelay = _stopDelay;
    copy.startTimer = _startDelay;
    copy.stopTimer = _stopDelay;
    copy.damage = _damage;
    
    return copy;
}

@end
