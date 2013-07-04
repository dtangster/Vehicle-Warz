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
@property (nonatomic) Weapon *subWeapons; // Possibility for a weapon to spawn other weapons
@property (nonatomic) NSString *imageFile;
@property (nonatomic) NSString *weaponName;
@property (nonatomic) NSString *weaponSound;
@property (nonatomic) b2BodyDef bodyDef;
@property (nonatomic) b2Fixture *fixture; // Will store the shape and density information
@property (nonatomic) b2Body *body;  // Will store the position and type
@property (nonatomic) BOOL isCircle;
@property (nonatomic) int energyCost;
@property (nonatomic) int explosionTimer;
@property (nonatomic) BOOL isPersistentWeapon; // Allows the weapon to persist multiple rounds
@property (nonatomic) WeaponEffect *effect; // Behavior of the weapon

// Store last shot settings
@property (nonatomic) int lastShotPower;
@property (nonatomic) int lastAngle;
@property (nonatomic) int lastRotation; // Just in case we want to allow players to set the rotation of the shot

- (id)initWithName:(NSString *) weaponName
        usingImage:(NSString *) fileName
        usingSound:(NSString *) weaponSound
         usingBodyDef:(b2BodyDef) bodyDef
    withEnergyCost:(int) energyCost
          isCircle:(BOOL) isCircle;

// Weapon to vehicle collisions will be delegated to this method from ContactListener
- (void)damageVehicle:(Vehicle *) vehicle
      withContactData:(b2Contact *) contact
          withImpulse:(const b2ContactImpulse *) impulse;

- (BOOL)executeAttackOnScreen: (GameLayer *) screen;
- (void)executeLaunchEffects; // The behavior of the weapon from the time it is launched until it is detonated
- (b2Vec2)calculateInitialVector;

@end
