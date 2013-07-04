//
//  WeaponEffect.h
//  Vehicle Warz
//
//  Created by David Tang on 7/3/13.
//
//

#import <Foundation/Foundation.h>

@class Vehicle;
@class Weapon;

@interface WeaponEffect : NSObject

@property (nonatomic) Weapon *affectedOn; // The effect applies to this weapon
@property (nonatomic) Weapon *subWeapons; // Possibility for a weapon to spawn other weapons
@property (nonatomic) int explosionTimer;

// Weapon to vehicle collisions will be delegated to this method from ContactListener
- (void)damageVehicle:(Vehicle *) vehicle
      withContactData:(b2Contact *) contact
         withImpulse:(const b2ContactImpulse *) impulse;

// The behavior of the weapon from the time it is launched until it is detonated
- (void)executeLaunchEffects;

// Weapons can spawn subweapons so you can chain them in sequence
- (void)launchSubWeapons;

@end
