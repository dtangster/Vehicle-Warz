//
//  Weapon.m
//  Template Penguin
//
//  Created by David Tang on 6/24/13.
//
//

#import "Weapon.h"
#import "Vehicle.h"

@implementation Weapon

-(id) initWithCarrier:(Vehicle *) carrier withName:(NSString *) weaponName withEnergyCost:(int) energyCost usingImage:(NSString *) fileName
{
    if ((self = [super initWithFile:fileName]))
    {
        self.carrier = carrier;
        self.weaponName = weaponName;
        self.energyCost = energyCost;
    }
    
    return self;
}

-(BOOL) executeAttack
{
    BOOL success = NO;
    
    if (self.carrier.energy >= self.energyCost) {
        self.carrier.energy -= self.energyCost;
        success = YES;
        
        //TO-DO: Add general implementation to execute an attack here
        
        
    }
    
    return success;
}

@end
