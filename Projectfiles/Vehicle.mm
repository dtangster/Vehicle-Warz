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
        self.health = 2;
        self.shield = 2;
        self.power = 100;
        self.speed = 2;
        self.energy = 100;
        self.lastAngle = 45;
    }
    
    return self;
}

-(BOOL) attackWithWeapon:(Weapon *) weapon
{
    return [weapon executeAttack];
}

-(void) setWeapon1:(Weapon *) weapon1
{
    self.weapon1 = weapon1;
    weapon1.carrier = self;
}

-(void) setWeapon2:(Weapon *) weapon2
{
    self.weapon2 = weapon2;
    weapon2.carrier = self;
}

-(void) setSpecial:(Weapon *) special
{
    self.weapon1 = special;
    special.carrier = self;
}

@end
