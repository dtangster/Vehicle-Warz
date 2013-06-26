//
//  Weapon.h
//  Template Penguin
//
//  Created by David Tang on 6/24/13.
//
//

#import "CCSprite.h"

@interface Weapon : CCSprite

@property (strong, nonatomic) NSString *weaponName;
@property int energyCost;

-(void) executeAttack;

@end
