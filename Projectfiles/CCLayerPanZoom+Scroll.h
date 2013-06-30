//
//  CCLayerPanZoom+Moving.h
//  Template Penguin
//
//  Created by Akshay on 6/30/13.
//
//

#import "CCLayerPanZoom.h"
#import <QuartzCore/CAScrollLayer.h>

@interface CCLayerPanZoom (Scroll)

@property (nonatomic) CAScrollLayer *scrollLayer;

- (id)initWithScrollLayer:(CAScrollLayer *)scrollLayer;
- (void)moveToRect:(CGRect)theRect;
- (void)moveToPoint:(CGPoint)thePoint;

@end
