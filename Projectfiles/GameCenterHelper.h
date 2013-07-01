//
//  GameCenterHelper.h
//  Template Penguin
//
//  Created by Akshay on 6/30/13.
//
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@protocol GameCenterHelperDelegate

- (void)matchStarted;
- (void)matchEnded;
- (void)match:(GKMatch *)aMatch didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID;

@end

@interface GameCenterHelper : NSObject <GKMatchmakerViewControllerDelegate, GKMatchDelegate> {
    BOOL userAuthenticated;
    BOOL matchDidStart;
}

@property (strong) UIViewController *matchViewController;
@property (strong) GKMatch *theMatch;
@property (assign) id <GameCenterHelperDelegate> delegate;

+ (GameCenterHelper *)sharedInstance;
- (void)authenticateLocalUser;
- (void)findAMatchWith:(UIViewController *)viewController
              delegate:(id<GameCenterHelperDelegate>)theDelegate;

@end
