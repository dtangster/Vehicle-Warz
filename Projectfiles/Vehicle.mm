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
        _vehicleName = vehicleName;
        _baseHealth = 2;
        _baseShield = 2;
        _basePower = 100;
        _baseSpeed = 1;
        _baseEnergy = 100;
        _maxHealth = 2;
        _maxShield = 2;
        _maxEnergy = 100;
        _maxSpeed = 1;
        _maxEnergy = 100;
        _health = 2;
        _shield = 2;
        _power = 100;
        _speed = 1;
        _energy = 100;
        _maxFrontUpperAngle = 120;
        _maxFrontLowerAngle = -30;
    }
    
    return self;
}

-(BOOL) attackWithWeapon:(Weapon *) weapon onScreen:(GameLayer *) screen
{
    _selectedWeapon = weapon;
    return [weapon executeAttackOnScreen:screen];
}

-(void) setWeapon1:(Weapon *) weapon
{
    _selectedWeapon = weapon;
    _weapon1 = weapon;
    weapon.carrier = self;
}

-(void) setWeapon2:(Weapon *) weapon
{
    _weapon2 = weapon;
    weapon.carrier = self;
}

-(void) setSpecial:(Weapon *) weapon
{
    _special = weapon;
    weapon.carrier = self;
}

@end
