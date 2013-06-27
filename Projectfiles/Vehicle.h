//
//  Vehicle.h
//  Template Penguin
//
//  Created by David Tang on 6/24/13.
//
//

#import "CCSprite.h"

@class Weapon;
@class GameLayer;

@interface Vehicle : CCSprite

@property (nonatomic) NSString *vehicleName;
@property (nonatomic) b2Fixture *fixture; //will store the shape and density information
@property (nonatomic) b2Body *body;  //will store the position and type
@property (nonatomic) Weapon *weapon1;
@property (nonatomic) Weapon *weapon2;
@property (nonatomic) Weapon *special;
@property (nonatomic) int baseHealth;
@property (nonatomic) int baseShield;
@property (nonatomic) int basePower;
@property (nonatomic) int baseSpeed;
@property (nonatomic) int baseEnergy;
@property (nonatomic) int maxHealth;
@property (nonatomic) int maxShield;
@property (nonatomic) int maxEnergy;
@property (nonatomic) int health;
@property (nonatomic) int shield;
@property (nonatomic) int power;
@property (nonatomic) int speed;
@property (nonatomic) int energy;
@property (nonatomic) int maxFrontUpperAngle;
@property (nonatomic) int maxFrontLowerAngle;
@property (nonatomic) int lastAngle;

-(id) initWithName:(NSString *) vehicleName usingImage:(NSString *) fileName;
-(BOOL) attackWithWeapon:(Weapon *) weapon onScreen:(GameLayer *) screen;

@end
