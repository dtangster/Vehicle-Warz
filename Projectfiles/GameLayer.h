/*
 * Kobold2D™ --- http://www.kobold2d.org
 *
 * Copyright (c) 2010-2011 Steffen Itterheim. 
 * Released under MIT License in Germany (LICENSE-Kobold2D.txt).
 */

#import "cocos2d.h"
#import "Box2D.h"
#import "ContactListener.h"

enum
{
	kTagBatchNode,
};

@class Vehicle;

@interface GameLayer : CCLayer
{
	b2World* world;
    int currentBullet;
    NSMutableArray *bullets;
    ContactListener *contactListener;
    b2Body *screenBorderBody;
    
    Vehicle *player1Vehicle;
    Vehicle *player2Vehicle;
    b2Fixture *player1Fixture; //will store the shape and density information of the catapult arm
    b2Body *player1Body;  //will store the position and type of the catapult arm
    b2Fixture *player2Fixture; //will store the shape and density information of the catapult arm
    b2Body *player2Body;  //will store the position and type of the catapult arm
    b2Fixture *projectileFixture; //will store the shape and density information of the catapult arm
    b2Body *projectileBody;  //will store the position and type of the catapult arm

    //MY STUFF
    float shotPower;
    int angle;
    BOOL isFirstPlayerTurn;
    BOOL justAttacked;
    CCLabelTTF *powerLabel;
    CCLabelTTF *angleLabel;
}

+(id) scene;
- (void)createBullets;

@end
