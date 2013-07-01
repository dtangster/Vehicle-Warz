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
@property (strong) GKMatch *match;
@property (assign) id <GameCenterHelperDelegate> delegate;
@property (nonatomic) NSMutableArray *unsavedAchievements;
@property (nonatomic) NSMutableDictionary *savedAchievements;

+ (GameCenterHelper *)sharedInstance;

// Authentication
- (void)authenticateLocalUser;

// Matchmaking
- (void)findAMatchWith:(UIViewController *)viewController
              delegate:(id<GameCenterHelperDelegate>)theDelegate;

// Achievements
- (void)reportAchievementIdentidier:(NSString *)identifier percentComplete:(float)percent;
@end
