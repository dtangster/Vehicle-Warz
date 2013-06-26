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
@property (strong, nonatomic) Weapon *weapon1;
@property (strong, nonatomic) Weapon *weapon2;
@property int health;
@property int power;
@property int speed;
@property int lastAngle;
@property BOOL isFacingLeft;

-(id) initWithName:(NSString *) vehicleName usingImage:(NSString *) fileName;
-(void) attackWithWeapon:(Weapon *) weapon;

@end
