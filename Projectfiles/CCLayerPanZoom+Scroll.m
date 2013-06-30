//
//  CCLayerPanZoom+Moving.m
//  Template Penguin
//
//  Created by Akshay on 6/30/13.
//
//

#import "CCLayerPanZoom+Moving.h"

@implementation CCLayerPanZoom (Scroll)

- (id)initWithScrollLayer:(CAScrollLayer *)scrollLayer
{
    self = [super init];
    if (self) {
        _scrollLayer = scrollLayer;
    }
    
    return self;
}

- (void)moveToPoint:(CGPoint)thePoint
{
    [_scrollLayer moveToPoint:thePoint];
}

- (void)moveToRect:(CGRect)theRect
{
    
}

@end
