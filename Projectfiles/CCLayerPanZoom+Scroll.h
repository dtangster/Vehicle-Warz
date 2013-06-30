//
//  CCLayerPanZoom+Scroll.h
//  Template Penguin
//
//  Created by Akshay on 6/30/13.
//
//

#import "CCLayerPanZoom.h"

@interface CCLayerPanZoom (Scroll)

- (id)initWithScrollLayer:(CAScrollLayer *)scrollLayer;

- (void)scrollToPoint:(CGPoint)thePoint;

- (void)scrollToRect:(CGRect)theRect;

- (void)enableTouches:(BOOL)enable;

- (void)removeAllTouches;

@end
