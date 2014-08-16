//
//  ADPreviousPageButton.m
//  PaintProjector
//
//  Created by 胡 文杰 on 8/16/14.
//  Copyright (c) 2014 WenjiHu. All rights reserved.
//

#import "ADPreviousPageButton.h"

@implementation ADPreviousPageButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    [self drawCanvas1WithFrame:rect];
}

- (void)drawCanvas1WithFrame: (CGRect)frame;
{
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* color = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    
    //// previous Drawing
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMinX(frame) + 11, CGRectGetMinY(frame) + 44);
    CGContextRotateCTM(context, -90 * M_PI / 180);
    
    UIBezierPath* previousPath = UIBezierPath.bezierPath;
    [previousPath moveToPoint: CGPointMake(0, -5.5)];
    [previousPath addLineToPoint: CGPointMake(4.76, 2.75)];
    [previousPath addLineToPoint: CGPointMake(-4.76, 2.75)];
    [previousPath closePath];
    [color setFill];
    [previousPath fill];
    
    CGContextRestoreGState(context);
}

@end
