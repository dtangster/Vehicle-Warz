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
@property (nonatomic) b2Fixture *fixture; // Will store the shape and density information
@property (nonatomic) b2Body *body;  // Will store the position and type
@property (nonatomic) Weapon *weapon1;
@property (nonatomic) Weapon *weapon2;
@property (nonatomic) Weapon *special;

// These are the base stats that multiplier effects will be applied to
@property (nonatomic) int baseHealth;
@property (nonatomic) int baseShield;
@property (nonatomic) int basePower;
@property (nonatomic) int baseSpeed;
@property (nonatomic) int baseEnergy;

// These are the stats after applying level up attributes and items. (IE. 40/120 HP where 120 is the max)
@property (nonatomic) int maxHealth;
@property (nonatomic) int maxShield;
@property (nonatomic) int maxPower;
@property (nonatomic) int maxSpeed;
@property (nonatomic) int maxEnergy;

// These are the stats of the max version minus any damage done, buffs or debuffs applied
@property (nonatomic) int health;
@property (nonatomic) int shield;
@property (nonatomic) int power;
@property (nonatomic) int speed;
@property (nonatomic) int energy;

// The max angle above its horizontal line
@property (nonatomic) int maxFrontUpperAngle;

// The max angle below its horizontal line
@property (nonatomic) int maxFrontLowerAngle;

// Store last shot settings
@property (nonatomic) int lastShotPower;
@property (nonatomic) int lastAngle;

-(id) initWithName:(NSString *) vehicleName usingImage:(NSString *) fileName;
-(BOOL) attackWithWeapon:(Weapon *) weapon onScreen:(GameLayer *) screen;

@end
