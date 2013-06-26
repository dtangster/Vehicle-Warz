//
//  Vehicle.h
//  Template Penguin
//
//  Created by David Tang on 6/24/13.
//
//

#import "CCSprite.h"

@class Weapon;

@interface Vehicle : CCSprite

@property (strong, nonatomic) NSString *vehicleName;
@property int health;
@property int power;
@property int speed;
@property int lastAngle;

-(id) initWithName:(NSString *) vehicleName usingImage:(NSString *) fileName;
-(void) attackWithWeapon:(Weapon *) weapon;

@end
