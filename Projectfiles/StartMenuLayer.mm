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
        // Log in user to GameCenter.
        // NOTE: Currently, GameCenter won't be able to log in since
        // we have't register to the iOS Developer program
        [[GameCenterHelper sharedInstance] authenticateLocalUser];
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

- (void)matchStarted
{
    
}

- (void)matchEnded
{
    
}

- (void)match:(GKMatch *)aMatch didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID
{
    
}

@end
