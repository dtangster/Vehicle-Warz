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

@property (strong, nonatomic) Vehicle *carrier;
@property (strong, nonatomic) NSString *imageFile;
@property (strong, nonatomic) NSString *weaponName;
@property b2Fixture *fixture; //will store the shape and density information
@property b2Body *body;  //will store the position and type
@property int energyCost;

-(id) initWithName:(NSString *) weaponName withEnergyCost:(int) energyCost usingImage:(NSString *) fileName;
-(BOOL) executeAttackOnScreen: (GameLayer *) screen;

@end
