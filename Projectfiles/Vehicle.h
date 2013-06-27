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
@property b2Fixture *fixture; //will store the shape and density information
@property b2Body *body;  //will store the position and type
@property (strong, nonatomic) Weapon *weapon1;
@property (strong, nonatomic) Weapon *weapon2;
@property (strong, nonatomic) Weapon *special;
@property int baseHealth;
@property int baseShield;
@property int basePower;
@property int baseSpeed;
@property int baseEnergy;
@property int maxHealth;
@property int maxShield;
@property int maxEnergy;
@property int health;
@property int shield;
@property int power;
@property int speed;
@property int energy;
@property int maxFrontUpperAngle;
@property int maxFrontLowerAngle;
@property int lastAngle;

-(id) initWithName:(NSString *) vehicleName usingImage:(NSString *) fileName;
-(BOOL) attackWithWeapon:(Weapon *) weapon;

@end
