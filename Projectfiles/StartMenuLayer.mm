//
//  StartMenuLayer.m
//  Vehicle Warz
//
//  Created by Akshay on 6/29/13.
//
//

#import "AppDelegate.h"
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
    // TODO: Find a match with Game Center with another player.
}

#pragma mark GameCenterHelperDelegate Methods
- (void)matchStarted
{
}

- (void)matchEnded
{
    // Maybe update the leaderboards/achievements here
}

- (void)match:(GKMatch *)aMatch didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID
{
}


@end
