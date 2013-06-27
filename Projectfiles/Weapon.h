//
//  Weapon.h
//  Template Penguin
//
//  Created by David Tang on 6/24/13.
//
//

#import "CCSprite.h"

@class Vehicle;

@interface Weapon : CCSprite

@property (strong, nonatomic) Vehicle *carrier;
@property (strong, nonatomic) NSString *weaponName;
@property int energyCost;

-(BOOL) executeAttack;

@end
