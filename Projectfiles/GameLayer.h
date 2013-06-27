/*
 * Kobold2D™ --- http://www.kobold2d.org
 *
 * Copyright (c) 2010-2011 Steffen Itterheim. 
 * Released under MIT License in Germany (LICENSE-Kobold2D.txt).
 */

#import "cocos2d.h"
#import "Box2D.h"
#import "ContactListener.h"
#import "CCLayerPanZoom.h"

enum
{
	kTagBatchNode,
};

@class Vehicle;

@interface GameLayer : CCLayer
{
    int currentBullet;
    NSMutableArray *bullets;
    ContactListener *contactListener;
    b2Body *screenBorderBody;
    
    //MY STUFF
    float shotPower;
    int angle;
    
    CCLabelTTF *angleLabel;
    CCSprite *leftArrow;
    CCSprite *rightArrow;
}


@property b2World *world;
@property (strong, nonatomic) Vehicle *player1Vehicle;
@property (strong, nonatomic) Vehicle *player2Vehicle;
@property BOOL isFirstPlayerTurn;
@property BOOL turnJustEnded;
@property (strong, nonatomic) CCLabelTTF *energyLabel;
@property (strong, nonatomic) CCLayerPanZoom *panZoomLayer;

+(id) scene;
- (CGPoint)toPixels:(b2Vec2)vec;
- (void)createBullets;

@end
