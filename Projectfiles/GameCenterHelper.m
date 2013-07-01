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
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    userAuthenticated = ([localPlayer isAuthenticated] && !userAuthenticated) ? YES : NO;
}

- (void)authenticateLocalUser
{
    if (!([[GKLocalPlayer localPlayer] isAuthenticated])) {
        [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:nil];
        NSLog(@"Trying to authenticate local user.");
    }
    else {
        NSLog(@"Local user is already authenticated");
    }
}

- (void)findAMatchWith:(UIViewController *)viewController delegate:(id<GameCenterHelperDelegate>)theDelegate
{
    matchDidStart = NO;
    _match = nil;
    _matchViewController = viewController;
    _delegate = theDelegate;
    [_matchViewController dismissModalViewControllerAnimated:NO];
    
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = 2;
    request.maxPlayers = 2;
    request.defaultNumberOfPlayers = 2;
    
    GKMatchmakerViewController *matchmaker = [[GKMatchmakerViewController alloc]
                                               initWithMatchRequest:request];
    
    [_matchViewController presentModalViewController:matchmaker animated:YES];
}

#pragma mark Callbacks

- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController
{
    [_matchViewController dismissModalViewControllerAnimated:YES];
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error
{
    [_matchViewController dismissModalViewControllerAnimated:YES];
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)match
{
    [_matchViewController dismissModalViewControllerAnimated:YES];
    _match = match;
    _match.delegate = self;
}

- (void)match:(GKMatch *)aMatch didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID
{
    if (_match != aMatch) {
        return;
    }
    
    [_delegate match:aMatch didReceiveData:data fromPlayer:playerID];
}

- (void)match:(GKMatch *)theMatch player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state
{
    if (_match != theMatch) {
        return;
    }
    
    switch (state) {
        case GKPlayerStateConnected:
            if (!matchDidStart && theMatch.expectedPlayerCount == 0) {
                NSLog(@"Starting match");
            }
            break;
        case GKPlayerStateDisconnected:
            matchDidStart = NO;
            [_delegate matchEnded];
            break;
        default:
            break;
    }
}

- (void)match:(GKMatch *)theMatch connectionWithPlayerFailed:(NSString *)playerID withError:(NSError *)error
{
    if (_match != theMatch) {
        return;
    }
    
    matchDidStart = NO;
    [_delegate matchEnded];
}

@end
