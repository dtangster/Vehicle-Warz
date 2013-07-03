//
//  Weapon.h
//  Vehicle Warz
//
//  Created by David Tang on 6/24/13.
//
//

#import "CCSprite.h"
#import "SimpleAudioEngine.h"

@class Vehicle;
@class GameLayer;
@class WeaponEffect;

@interface Weapon : CCSprite

@property (nonatomic) Vehicle *carrier;
@property (nonatomic) NSString *imageFile;
@property (nonatomic) NSString *weaponName;
@property (nonatomic) NSString *weaponSound;
@property (nonatomic) b2Fixture *fixture; // Will store the shape and density information
@property (nonatomic) b2Body *body;  // Will store the position and type
@property (nonatomic) int energyCost;
@property (nonatomic) WeaponEffect *effect; // Determines what the shot does

// Store last shot settings
@property (nonatomic) int lastShotPower;
@property (nonatomic) int lastAngle;
@property (nonatomic) int lastRotation; // Just in case we want to allow players to set the rotation of the shot

- (id)initWithName:(NSString *) weaponName withEnergyCost:(int) energyCost usingImage:(NSString *)fileName usingSound:(NSString *)weaponSound;
- (BOOL)executeAttackOnScreen: (GameLayer *) screen;
- (b2Vec2)calculateInitialVector;

@end
