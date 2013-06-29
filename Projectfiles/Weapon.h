//
//  Weapon.h
//  Template Penguin
//
//  Created by David Tang on 6/24/13.
//
//

#import "CCSprite.h"

@class Vehicle;
@class GameLayer;

@interface Weapon : CCSprite

@property (nonatomic) Vehicle *carrier;
@property (nonatomic) NSString *imageFile;
@property (nonatomic) NSString *weaponName;
@property (nonatomic) b2Fixture *fixture; // Will store the shape and density information
@property (nonatomic) b2Body *body;  // Will store the position and type
@property (nonatomic) int energyCost;

// Store last shot settings
@property (nonatomic) int lastShotPower;
@property (nonatomic) int lastAngle;
@property (nonatomic) int lastRotation; // Just in case we want to allow players to set the rotation of the shot

-(id) initWithName:(NSString *) weaponName withEnergyCost:(int) energyCost usingImage:(NSString *) fileName;
-(BOOL) executeAttackOnScreen: (GameLayer *) screen;
-(b2Vec2) calculateInitialVector;

@end
