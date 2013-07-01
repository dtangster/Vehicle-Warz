//
//  StartMenuLayer.h
//  Vehicle Warz
//
//  Created by Akshay on 6/29/13.
//
//

#import "CCLayer.h"
#import "GameCenterHelper.h"

@interface StartMenuLayer : CCLayer <GameCenterHelperDelegate>

+ (id)scene;
- (id)init;
- (void)setUpMenus;
- (void)playGame:(CCMenuItem *)sender;

@end
