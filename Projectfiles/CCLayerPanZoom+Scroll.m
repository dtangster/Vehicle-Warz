//
//  CCLayerPanZoom+Scroll.m
//  Template Penguin
//
//  Created by Akshay on 6/30/13.
//
//

#import "CCLayerPanZoom+Scroll.h"
#import <QuartzCore/CAScrollLayer.h>

CAScrollLayer *scrollLayer;

@implementation CCLayerPanZoom (Scroll)

- (id)initWithScrollLayer:(CAScrollLayer *)theLayer
{
    if ((self = [super init])) {
        scrollLayer = theLayer;
    }
    
    return self;
}

- (void)scrollToRect:(CGRect)theRect
{
    [scrollLayer scrollToRect:theRect];
}

- (void)scrollToPoint:(CGPoint)thePoint
{
    [scrollLayer scrollToPoint:thePoint];
}

- (void)removeAllTouches
{
    [_touches removeAllObjects];
}

- (void)enableTouches:(BOOL)enable
{
    if (enable) {
        [self removeAllTouches];
        [[[CCDirector sharedDirector] touchDispatcher] addStandardDelegate:self priority:0];
        NSLog(@"Touch enabled.");
    }
    else {
        [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
        NSLog(@"Touch disabled.");
    }
}

@end
