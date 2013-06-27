//
//  Vehicle.m
//  Template Penguin
//
//  Created by David Tang on 6/24/13.
//
//

#import "Vehicle.h"
#import "Weapon.h"

@implementation Vehicle

-(id) initWithName:(NSString *) vehicleName usingImage:(NSString *) fileName
{
    if ((self = [super initWithFile:fileName]))
    {
        self.vehicleName = vehicleName;
        self.baseHealth = 2;
        self.baseShield = 2;
        self.basePower = 100;
        self.baseSpeed = 2;
        self.baseEnergy = 100;
        self.maxHealth = 2;
        self.maxShield = 2;
        self.maxEnergy = 100;
        self.health = 2;
        self.shield = 2;
        self.power = 100;
        self.speed = 2;
        self.energy = 100;
        self.lastShotPower = 0;
        self.lastAngle = 0;
    }
    
    return self;
}

-(BOOL) attackWithWeapon:(Weapon *) weapon onScreen:(GameLayer *) screen
{
    return [weapon executeAttackOnScreen:screen];
}

-(void) setWeapon1:(Weapon *) weapon1
{
    _weapon1 = weapon1;
    weapon1.carrier = self;
}

-(void) setWeapon2:(Weapon *) weapon2
{
    _weapon2 = weapon2;
    weapon2.carrier = self;
}

-(void) setSpecial:(Weapon *) special
{
    _special = special;
    special.carrier = self;
}

@end
