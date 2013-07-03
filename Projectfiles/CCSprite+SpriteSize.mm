//
//  CCSprite+SpriteSize.m
//  Vehicle Warz
//
//  Created by Akshay on 6/26/13.
//
//

#import "CCSprite+SpriteSize.h"

@implementation CCSprite (SpriteSize)

- (CGFloat)spriteHeight
{
    return self.boundingBox.size.height;
}

- (CGFloat)spriteWidth
{
    return self.boundingBox.size.width;
}

@end
