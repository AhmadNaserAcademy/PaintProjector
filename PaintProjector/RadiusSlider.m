//
//  RadiusSlider.m
//  ProjectPaint
//
//  Created by 胡 文杰 on 13-5-4.
//  Copyright (c) 2013年 WenjiHu. All rights reserved.
//

#import "RadiusSlider.h"

@implementation RadiusSlider

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        UIImage *minTrackImage = [[UIImage imageNamed:@"radiusSliderTracker.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
        UIImage *maxTrackImage = [[UIImage imageNamed:@"radiusSliderTracker.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
        
        [self setMinimumTrackImage:minTrackImage forState:UIControlStateNormal];
        [self setMaximumTrackImage:maxTrackImage forState:UIControlStateNormal];
        
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* shadow2Color = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    UIColor* shadowColor2 = [UIColor colorWithRed: 0.3 green: 0.3 blue: 0.3 alpha: 1];
    UIColor* radiusColor = [UIColor colorWithRed: 0.6 green: 0.6 blue: 0.6 alpha: 1];
    UIColor* color = [UIColor colorWithRed: 0.8 green: 0.8 blue: 0.8 alpha: 1];
    
    //// Shadow Declarations
    UIColor* shadow = shadowColor2;
    CGSize shadowOffset = CGSizeMake(0.1, 2.1);
    CGFloat shadowBlurRadius = 2;
    UIColor* shadow2 = shadow2Color;
    CGSize shadow2Offset = CGSizeMake(0.1, 1.1);
    CGFloat shadow2BlurRadius = 2;
    
    //// Rounded Rectangle Drawing
    UIBezierPath* roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(1, 7, 248, 20) cornerRadius: 10];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, shadow2Offset, shadow2BlurRadius, shadow2.CGColor);

    //draw
    CGContextBeginTransparencyLayer(context, NULL);
    [roundedRectanglePath addClip];
    [color setFill];
    [roundedRectanglePath fill];
    
    UIBezierPath* sizePath = [UIBezierPath bezierPath];
    [sizePath moveToPoint:CGPointMake(0, self.bounds.size.height * 0.5)];
    [sizePath addLineToPoint:CGPointMake(self.bounds.size.width, 0)];
    [sizePath addLineToPoint:CGPointMake(self.bounds.size.width, self.bounds.size.height)];
    [sizePath closePath];
    [radiusColor setFill];
    [sizePath fill];

    CGContextEndTransparencyLayer(context);
    
    ////// Rounded Rectangle Inner Shadow
    CGRect roundedRectangleBorderRect = CGRectInset([roundedRectanglePath bounds], -shadowBlurRadius, -shadowBlurRadius);
    roundedRectangleBorderRect = CGRectOffset(roundedRectangleBorderRect, -shadowOffset.width, -shadowOffset.height);
    roundedRectangleBorderRect = CGRectInset(CGRectUnion(roundedRectangleBorderRect, [roundedRectanglePath bounds]), -1, -1);
    
    UIBezierPath* roundedRectangleNegativePath = [UIBezierPath bezierPathWithRect: roundedRectangleBorderRect];
    [roundedRectangleNegativePath appendPath: roundedRectanglePath];
    roundedRectangleNegativePath.usesEvenOddFillRule = YES;
    
    CGContextSaveGState(context);
    {
        CGFloat xOffset = shadowOffset.width + round(roundedRectangleBorderRect.size.width);
        CGFloat yOffset = shadowOffset.height;
        CGContextSetShadowWithColor(context,
                                    CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)),
                                    shadowBlurRadius,
                                    shadow.CGColor);
        
        [roundedRectanglePath addClip];
        CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(roundedRectangleBorderRect.size.width), 0);
        [roundedRectangleNegativePath applyTransform: transform];
        [[UIColor grayColor] setFill];
        [roundedRectangleNegativePath fill];
    }
    CGContextRestoreGState(context);
    CGContextRestoreGState(context);
    
    
    
    //// Cleanup
    CGColorSpaceRelease(colorSpace);
}


@end