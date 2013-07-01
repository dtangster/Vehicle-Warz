//
//  GameCenterHelper.m
//  Template Penguin
//
//  Created by Akshay on 6/30/13.
//
//

#import "GameCenterHelper.h"

@implementation GameCenterHelper

static GameCenterHelper *sharedHelper = nil;

+ (GameCenterHelper *)sharedInstance
{
    if (!sharedHelper) {
        sharedHelper = [[GameCenterHelper alloc] init];
    }
    
    return sharedHelper;
}

- (id)init
{
    // NOTE: Game center is required for this game so no need to check if it's available
    // since this game will only work with iOS 4.1+
    if ((self = [super init])) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(authenticationChanged)
                   name:GKPlayerAuthenticationDidChangeNotificationName
                 object:nil];
    }
    
    return self;
}

- (void)authenticationChanged
{
    if ([GKLocalPlayer localPlayer].isAuthenticated && !isUserAuthenticated) {
        isUserAuthenticated = YES;
    }
    else {
        isUserAuthenticated = NO;
    }
}

@end
