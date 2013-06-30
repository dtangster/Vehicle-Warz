//
//  StartMenuLayer.m
//  Template Penguin
//
//  Created by Akshay on 6/29/13.
//
//

#import "StartMenuLayer.h"
#import "GameLayer.h"

@implementation StartMenuLayer

+ (id)scene
{
    CCScene *scene = [CCScene node];
    GameLayer *layer = [StartMenuLayer node];
    [scene addChild:layer];
    
    return scene;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        [self setUpMenus];
        // TODO: Set up game center stuff here for a turnbased matchmaking game / leaderboards
    }
    
    return self;
}

- (void)setUpMenus
{
    CCMenuItemFont *playGame = [CCMenuItemFont itemWithString:@"Play Game"
                                                       target:self
                                                     selector:@selector(playGame:)];
    CCMenu *mainMenu = [CCMenu menuWithItems:playGame, nil];
    [self addChild:mainMenu];
    // TODO: Add relevant menu items.
}

- (void)playGame:(CCMenuItem *)sender
{
    [[CCDirector sharedDirector] replaceScene:(CCScene *)[[GameLayer alloc] init]];
}

@end
