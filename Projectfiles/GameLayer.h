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

@class Vehicle;

@interface GameLayer : CCLayer

@property (nonatomic) b2World *world;
@property (nonatomic) ContactListener *contactListener;
@property (nonatomic) b2Body *screenBorderBody;
@property (nonatomic) BOOL isFirstPlayerTurn;
@property (nonatomic) BOOL turnJustEnded;
@property (nonatomic) BOOL vehicleTurnJustBegan;
@property (nonatomic) BOOL isReplaying;
@property (nonatomic) Vehicle *player1Vehicle;
@property (nonatomic) Vehicle *player2Vehicle;
@property (nonatomic) CCMenuItemLabel *healthLabel;
@property (nonatomic) CCMenuItemLabel *shieldLabel;
@property (nonatomic) CCMenuItemLabel *energyLabel;
@property (nonatomic) CCMenuItemLabel *angleLabel;
@property (nonatomic) CCMenuItemLabel *shotPowerLabel;
@property (nonatomic) CCMenuItemImage *leftArrow;
@property (nonatomic) CCMenuItemImage *rightArrow;
@property (nonatomic) CCLayerPanZoom *panZoomLayer;
@property (nonatomic) NSDictionary *soundEffects;

// Properties used for the countdown timer
@property (nonatomic) CCSprite *timer;
@property (nonatomic) NSMutableArray *timerFrames;
@property (nonatomic) CCAction *decrementTimer;
@property (nonatomic) CCAnimation *countDown;

// The last action should always be @"Step" in order to work
@property (nonatomic) NSMutableArray *actionReplayData;

+ (id)scene;
- (id)init;
- (CGPoint)toPixels:(b2Vec2)vec;
- (void)createBullets;

@end
