//
//  Terrain.h
//  Vehicle Warz
//
//  Created by David Tang on 7/5/13.
//
//

#import "CCSprite.h"

@interface Terrain : CCSprite

@property (nonatomic) b2Fixture *fixture; // Will store the shape and density information
@property (nonatomic) b2Body *body;  // Will store the position and type

@end
