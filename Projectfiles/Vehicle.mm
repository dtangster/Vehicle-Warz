//
//  Vehicle.m
//  Vehicle Warz
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
        _experience = 0;
        _level = 1;
        _baseHealth = 100;
        _baseShield = 1;
        _basePower = 100;
        _baseSpeed = 30;
        _baseEnergy = 1000;
        _damageIncurred = 0;
        
        // These should be some formula using the base as a multiplier
        _maxHealth = _baseHealth; 
        _maxShield = _baseShield;
        _maxPower = _basePower;
        _maxSpeed = _baseSpeed;
        _maxEnergy = _baseEnergy;
        
        // Give vehicles full health, shields, etc.
        _health = _maxHealth; 
        _shield = _maxShield;
        _power = _maxPower;
        _speed = _maxSpeed;
        _energy = _maxEnergy;
        
        // Limits the range of angles
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

-(BOOL) applyDamageToSelf
{
    if (!_damageIncurred) {
        return NO;
    }
    
    if (_shield >= _damageIncurred) {
        _shield -= _damageIncurred;
        _damageIncurred = 0;
    }
    else {
        _damageIncurred -= _shield;
        _health -= _damageIncurred;
        _shield = 0;
    }
    
    if (_health < 0) {
        _health = 0;
    }
    
    _damageIncurred = 0;
    return YES;
}

@end
