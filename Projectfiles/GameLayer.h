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
@property (nonatomic) NSMutableArray *activeProjectiles; // Weapons that detonate before next player's turn
@property (nonatomic) NSMutableArray *persistingProjectiles; // Weapons that stay on the screen for multiple rounds

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

- (b2BodyDef)createBodyDefWithType:(b2BodyType) type
                 withLinearDamping:(float) linearDamp
                withAngularDamping:(float) angularDamp;

- (b2FixtureDef)createCircleFixtureDef:(BOOL) isCircle;

@end
