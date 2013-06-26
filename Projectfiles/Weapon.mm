//
//  Weapon.m
//  Template Penguin
//
//  Created by David Tang on 6/24/13.
//
//

#import "Weapon.h"

@implementation Weapon

-(id) initWithName:(NSString *) weaponName usingImage:(NSString *) fileName withEnergyCost:(int) energyCost
{
    if ((self = [super initWithFile:fileName]))
    {
        self.weaponName = weaponName;
        self.energyCost = energyCost;
    }
    
    return self;
}

-(void) executeAttack
{
    
}

@end
