//
//  UndoStack.m
//  PaintProjector
//
//  Created by 文杰 胡 on 12-11-7.
//  Copyright (c) 2012年 Hu Wenjie. All rights reserved.
//

#import "ADImageStack.h"

@implementation ADImageStack
- (void)push:(CGImageRef)image {
    [super push: (__bridge id)image];
}

- (CGImageRef)pop {
    return (__bridge CGImageRef)[super pop];
}

- (CGImageRef)lastUndoImage{
    NSUInteger count = [self.contents count];
    if (count > 0) {
        CGImageRef returnObject = (__bridge CGImageRef)[self.contents objectAtIndex:count - 1];
        return returnObject;
    }
    return nil;
}

@end
