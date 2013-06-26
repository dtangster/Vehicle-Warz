//
//  Vehicle.m
//  Template Penguin
//
//  Created by David Tang on 6/24/13.
//
//

#import "Vehicle.h"

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

@end
