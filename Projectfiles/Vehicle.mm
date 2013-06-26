//
//  Vehicle.m
//  Template Penguin
//
//  Created by David Tang on 6/24/13.
//
//

#import "Vehicle.h"

@implementation Vehicle

@synthesize vehicleName = _vehicleName;
@synthesize health = _health;
@synthesize shield = _shield;
@synthesize power = _power;
@synthesize speed = _speed;
@synthesize energy = _energy;
@synthesize lastAngle = _lastAngle;

-(id) initWithName:(NSString *) vehicleName usingImage:(NSString *) fileName
{
    if ((self = [super initWithFile:fileName]))
    {
        vehicleName = _vehicleName;
        _health = 2;
        _shield = 2;
        _power = 100;
        _speed = 2;
        _energy = 100;
        _lastAngle = 45;
    }
    return self;
}

- (void)setPower:(int)power
{
    _power = power;
}

- (int)power
{
    if (_power > 100) {
        [self setPower:100];
    }
    else if (_power < 0) {
        [self setPower:0];
    }
    
    return _power;
}
@end
