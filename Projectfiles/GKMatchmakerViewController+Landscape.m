//
//  GKMatchmakerViewController+Landscape.m
//  Template Penguin
//
//  Created by Akshay on 6/30/13.
//
//

#import "GKMatchmakerViewController+Landscape.h"

@implementation GKMatchmakerViewController (Landscape)

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientation(toInterfaceOrientation);
}

- (NSUInterger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

@end
