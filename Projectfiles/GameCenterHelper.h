//
//  GameCenterHelper.h
//  Template Penguin
//
//  Created by Akshay on 6/30/13.
//
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@interface GameCenterHelper : NSObject {
    BOOL isUserAuthenticated;
}

+ (GameCenterHelper *)sharedInstance;
- (void)authenticateLocalUser;

@end
