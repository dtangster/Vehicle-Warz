//
//  UINavigationController+Landscape.m
//  Template Penguin
//
//  Created by Akshay on 7/1/13.
//
//

#import "UINavigationController+Landscape.h"

@implementation UINavigationController (Landscape)

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (BOOL)shouldAutorotate
{
    return [[UIDevice currentDevice] orientation] != UIInterfaceOrientationPortrait;
}

@end
