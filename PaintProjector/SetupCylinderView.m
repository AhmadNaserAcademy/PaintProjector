//
//  SetupCylinderButton.m
//  PaintProjector
//
//  Created by 胡 文杰 on 5/2/14.
//  Copyright (c) 2014 WenjiHu. All rights reserved.
//

#import "SetupCylinderView.h"

@implementation SetupCylinderView

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
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* iconHighlightColor = [UIColor colorWithRed: 1 green: 0.991 blue: 0.995 alpha: 0.284];
    UIColor* iconColor = [UIColor colorWithRed: 0.198 green: 0.198 blue: 0.198 alpha: 1];
    CGFloat iconColorRGBA[4];
    [iconColor getRed: &iconColorRGBA[0] green: &iconColorRGBA[1] blue: &iconColorRGBA[2] alpha: &iconColorRGBA[3]];
    
    UIColor* gradientColor = [UIColor colorWithRed: (iconColorRGBA[0] * 0.7 + 0.3) green: (iconColorRGBA[1] * 0.7 + 0.3) blue: (iconColorRGBA[2] * 0.7 + 0.3) alpha: (iconColorRGBA[3] * 0.7 + 0.3)];
    CGFloat gradientColorRGBA[4];
    [gradientColor getRed: &gradientColorRGBA[0] green: &gradientColorRGBA[1] blue: &gradientColorRGBA[2] alpha: &gradientColorRGBA[3]];
    
    UIColor* iconSpecularColor = [UIColor colorWithRed: (gradientColorRGBA[0] * 0.9 + 0.1) green: (gradientColorRGBA[1] * 0.9 + 0.1) blue: (gradientColorRGBA[2] * 0.9 + 0.1) alpha: (gradientColorRGBA[3] * 0.9 + 0.1)];
    CGFloat iconSpecularColorRGBA[4];
    [iconSpecularColor getRed: &iconSpecularColorRGBA[0] green: &iconSpecularColorRGBA[1] blue: &iconSpecularColorRGBA[2] alpha: &iconSpecularColorRGBA[3]];
    
    UIColor* glowColor = [UIColor colorWithRed: (iconSpecularColorRGBA[0] * 1 + 0) green: (iconSpecularColorRGBA[1] * 1 + 0) blue: (iconSpecularColorRGBA[2] * 1 + 0) alpha: (iconSpecularColorRGBA[3] * 1 + 0)];
    UIColor* iconShadowTempColor = [UIColor colorWithRed: (iconColorRGBA[0] * 0.3) green: (iconColorRGBA[1] * 0.3) blue: (iconColorRGBA[2] * 0.3) alpha: (iconColorRGBA[3] * 0.3 + 0.7)];
    UIColor* iconShadowColor = [iconShadowTempColor colorWithAlphaComponent: 0.1];
    
    //// Shadow Declarations
    UIColor* iconHighlight = iconHighlightColor;
    CGSize iconHighlightOffset = CGSizeMake(0.1, -2.1);
    CGFloat iconHighlightBlurRadius = 2;
    UIColor* iconShadow = iconShadowColor;
    CGSize iconShadowOffset = CGSizeMake(0.1, 2.1);
    CGFloat iconShadowBlurRadius = 2;
    UIColor* glow = glowColor;
    CGSize glowOffset = CGSizeMake(0.1, -0.1);
    CGFloat glowBlurRadius = 4;
    
    //// Frames
    CGRect frame = CGRectMake(0, 0, 66, 66);
    
    //// Subframes
    CGRect iconNormal = CGRectMake(CGRectGetMinX(frame) + floor((CGRectGetWidth(frame) - 31) * 0.51429 + 0.5), CGRectGetMinY(frame) + floor((CGRectGetHeight(frame) - 44) * 0.54545 + 0.5), 31, 44);
    
    
    //// IconNormal
    {
        CGContextSaveGState(context);
        CGContextSetShadowWithColor(context, glowOffset, glowBlurRadius, glow.CGColor);
        CGContextBeginTransparencyLayer(context, NULL);
        
        
        //// Group 5
        {
            CGContextSaveGState(context);
            CGContextSetAlpha(context, 0.38);
            CGContextBeginTransparencyLayer(context, NULL);
            
            
            //// Bezier 2 Drawing
            UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
            [bezier2Path moveToPoint: CGPointMake(CGRectGetMinX(iconNormal) + 0.84533 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.28295 * CGRectGetHeight(iconNormal))];
            [bezier2Path addCurveToPoint: CGPointMake(CGRectGetMinX(iconNormal) + 0.84533 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.05796 * CGRectGetHeight(iconNormal)) controlPoint1: CGPointMake(CGRectGetMinX(iconNormal) + 1.03605 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.22082 * CGRectGetHeight(iconNormal)) controlPoint2: CGPointMake(CGRectGetMinX(iconNormal) + 1.03605 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.12009 * CGRectGetHeight(iconNormal))];
            [bezier2Path addCurveToPoint: CGPointMake(CGRectGetMinX(iconNormal) + 0.15467 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.05796 * CGRectGetHeight(iconNormal)) controlPoint1: CGPointMake(CGRectGetMinX(iconNormal) + 0.65461 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + -0.00417 * CGRectGetHeight(iconNormal)) controlPoint2: CGPointMake(CGRectGetMinX(iconNormal) + 0.34539 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + -0.00417 * CGRectGetHeight(iconNormal))];
            [bezier2Path addCurveToPoint: CGPointMake(CGRectGetMinX(iconNormal) + 0.15467 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.28295 * CGRectGetHeight(iconNormal)) controlPoint1: CGPointMake(CGRectGetMinX(iconNormal) + -0.03605 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.12009 * CGRectGetHeight(iconNormal)) controlPoint2: CGPointMake(CGRectGetMinX(iconNormal) + -0.03605 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.22082 * CGRectGetHeight(iconNormal))];
            [bezier2Path addCurveToPoint: CGPointMake(CGRectGetMinX(iconNormal) + 0.84533 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.28295 * CGRectGetHeight(iconNormal)) controlPoint1: CGPointMake(CGRectGetMinX(iconNormal) + 0.34539 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.34508 * CGRectGetHeight(iconNormal)) controlPoint2: CGPointMake(CGRectGetMinX(iconNormal) + 0.65461 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.34508 * CGRectGetHeight(iconNormal))];
            [bezier2Path closePath];
            [bezier2Path moveToPoint: CGPointMake(CGRectGetMinX(iconNormal) + 0.15467 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.32840 * CGRectGetHeight(iconNormal))];
            [bezier2Path addCurveToPoint: CGPointMake(CGRectGetMinX(iconNormal) + 0.84533 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.32840 * CGRectGetHeight(iconNormal)) controlPoint1: CGPointMake(CGRectGetMinX(iconNormal) + 0.34539 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.39053 * CGRectGetHeight(iconNormal)) controlPoint2: CGPointMake(CGRectGetMinX(iconNormal) + 0.65461 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.39053 * CGRectGetHeight(iconNormal))];
            [bezier2Path addCurveToPoint: CGPointMake(CGRectGetMinX(iconNormal) + 0.98837 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.21591 * CGRectGetHeight(iconNormal)) controlPoint1: CGPointMake(CGRectGetMinX(iconNormal) + 0.94069 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.29734 * CGRectGetHeight(iconNormal)) controlPoint2: CGPointMake(CGRectGetMinX(iconNormal) + 0.98837 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.25662 * CGRectGetHeight(iconNormal))];
            [bezier2Path addLineToPoint: CGPointMake(CGRectGetMinX(iconNormal) + 0.98837 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.82955 * CGRectGetHeight(iconNormal))];
            [bezier2Path addLineToPoint: CGPointMake(CGRectGetMinX(iconNormal) + 0.98837 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.85227 * CGRectGetHeight(iconNormal))];
            [bezier2Path addLineToPoint: CGPointMake(CGRectGetMinX(iconNormal) + 0.98339 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.85227 * CGRectGetHeight(iconNormal))];
            [bezier2Path addCurveToPoint: CGPointMake(CGRectGetMinX(iconNormal) + 0.84533 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.94204 * CGRectGetHeight(iconNormal)) controlPoint1: CGPointMake(CGRectGetMinX(iconNormal) + 0.96892 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.88512 * CGRectGetHeight(iconNormal)) controlPoint2: CGPointMake(CGRectGetMinX(iconNormal) + 0.92290 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.91677 * CGRectGetHeight(iconNormal))];
            [bezier2Path addCurveToPoint: CGPointMake(CGRectGetMinX(iconNormal) + 0.15467 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.94204 * CGRectGetHeight(iconNormal)) controlPoint1: CGPointMake(CGRectGetMinX(iconNormal) + 0.65461 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 1.00417 * CGRectGetHeight(iconNormal)) controlPoint2: CGPointMake(CGRectGetMinX(iconNormal) + 0.34539 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 1.00417 * CGRectGetHeight(iconNormal))];
            [bezier2Path addCurveToPoint: CGPointMake(CGRectGetMinX(iconNormal) + 0.01661 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.85227 * CGRectGetHeight(iconNormal)) controlPoint1: CGPointMake(CGRectGetMinX(iconNormal) + 0.07710 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.91677 * CGRectGetHeight(iconNormal)) controlPoint2: CGPointMake(CGRectGetMinX(iconNormal) + 0.03108 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.88512 * CGRectGetHeight(iconNormal))];
            [bezier2Path addLineToPoint: CGPointMake(CGRectGetMinX(iconNormal) + 0.01163 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.85227 * CGRectGetHeight(iconNormal))];
            [bezier2Path addLineToPoint: CGPointMake(CGRectGetMinX(iconNormal) + 0.01163 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.21591 * CGRectGetHeight(iconNormal))];
            [bezier2Path addCurveToPoint: CGPointMake(CGRectGetMinX(iconNormal) + 0.15467 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.32840 * CGRectGetHeight(iconNormal)) controlPoint1: CGPointMake(CGRectGetMinX(iconNormal) + 0.01163 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.25662 * CGRectGetHeight(iconNormal)) controlPoint2: CGPointMake(CGRectGetMinX(iconNormal) + 0.05931 * CGRectGetWidth(iconNormal), CGRectGetMinY(iconNormal) + 0.29734 * CGRectGetHeight(iconNormal))];
            [bezier2Path closePath];
            CGContextSaveGState(context);
            CGContextSetShadowWithColor(context, iconShadowOffset, iconShadowBlurRadius, iconShadow.CGColor);
            [iconColor setFill];
            [bezier2Path fill];
            
            ////// Bezier 2 Inner Shadow
            CGRect bezier2BorderRect = CGRectInset([bezier2Path bounds], -iconHighlightBlurRadius, -iconHighlightBlurRadius);
            bezier2BorderRect = CGRectOffset(bezier2BorderRect, -iconHighlightOffset.width, -iconHighlightOffset.height);
            bezier2BorderRect = CGRectInset(CGRectUnion(bezier2BorderRect, [bezier2Path bounds]), -1, -1);
            
            UIBezierPath* bezier2NegativePath = [UIBezierPath bezierPathWithRect: bezier2BorderRect];
            [bezier2NegativePath appendPath: bezier2Path];
            bezier2NegativePath.usesEvenOddFillRule = YES;
            
            CGContextSaveGState(context);
            {
                CGFloat xOffset = iconHighlightOffset.width + round(bezier2BorderRect.size.width);
                CGFloat yOffset = iconHighlightOffset.height;
                CGContextSetShadowWithColor(context,
                                            CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)),
                                            iconHighlightBlurRadius,
                                            iconHighlight.CGColor);
                
                [bezier2Path addClip];
                CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(bezier2BorderRect.size.width), 0);
                [bezier2NegativePath applyTransform: transform];
                [[UIColor grayColor] setFill];
                [bezier2NegativePath fill];
            }
            CGContextRestoreGState(context);
            
            CGContextRestoreGState(context);
            
            
            
            CGContextEndTransparencyLayer(context);
            CGContextRestoreGState(context);
        }
        
        
        //// Group 4
        {
            CGContextSaveGState(context);
            CGContextSetAlpha(context, 0.38);
            CGContextSetBlendMode(context, kCGBlendModeOverlay);
            CGContextBeginTransparencyLayer(context, NULL);
            
            
            CGContextEndTransparencyLayer(context);
            CGContextRestoreGState(context);
        }
        
        
        CGContextEndTransparencyLayer(context);
        CGContextRestoreGState(context);
    }
    
    
}


@end
