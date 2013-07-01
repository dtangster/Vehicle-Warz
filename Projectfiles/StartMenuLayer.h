//
//  StartMenuLayer.h
//  Template Penguin
//
//  Created by Akshay on 6/29/13.
//
//

#import "CCLayer.h"
#import "GameCenterHelper.h"

@interface StartMenuLayer : CCLayer

+ (id)scene;
- (id)init;
- (void)setUpMenus;
- (void)playGame:(CCMenuItem *)sender;

@end
