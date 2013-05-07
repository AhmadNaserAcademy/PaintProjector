//
//  RedoButton.m
//  iReporter
//
//  Created by 文杰 胡 on 12-11-10.
//  Copyright (c) 2012年 Marin Todorov. All rights reserved.
//

#import "RedoButton.h"

@implementation RedoButton

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
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* iconHighlightColor = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    UIColor* iconColor = [UIColor colorWithRed: 0.795 green: 0.795 blue: 0.795 alpha: 1];
    CGFloat iconColorHSBA[4];
    [iconColor getHue: &iconColorHSBA[0] saturation: &iconColorHSBA[1] brightness: &iconColorHSBA[2] alpha: &iconColorHSBA[3]];
    
    UIColor* iconShadowColorColor = [UIColor colorWithHue: iconColorHSBA[0] saturation: iconColorHSBA[1] brightness: 0.325 alpha: iconColorHSBA[3]];
    UIColor* labelHightlightColor = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    
    //// Shadow Declarations
    UIColor* iconHighlight = iconHighlightColor;
    CGSize iconHighlightOffset = CGSizeMake(0.1, 1.1);
    CGFloat iconHighlightBlurRadius = 0;
    UIColor* iconShadow = iconShadowColorColor;
    CGSize iconShadowOffset = CGSizeMake(0.1, 1.1);
    CGFloat iconShadowBlurRadius = 0;
    UIColor* labelHightlight = labelHightlightColor;
    CGSize labelHightlightOffset = CGSizeMake(0.1, 1.1);
    CGFloat labelHightlightBlurRadius = 0;
    
    //// Abstracted Attributes
    NSString* textContent = @"Redo";
    
    
    //// Text Drawing
    CGRect textRect = CGRectMake(0, 42, 60, 18);
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, labelHightlightOffset, labelHightlightBlurRadius, labelHightlight.CGColor);
    [iconColor setFill];
    [textContent drawInRect: textRect withFont: [UIFont fontWithName: @"Helvetica-Bold" size: 12] lineBreakMode: UILineBreakModeWordWrap alignment: UITextAlignmentCenter];
    CGContextRestoreGState(context);
    
    
    
    //// Main Drawing
    UIBezierPath* mainPath = [UIBezierPath bezierPath];
    [mainPath moveToPoint: CGPointMake(35.89, 37.06)];
    [mainPath addLineToPoint: CGPointMake(43.14, 29.67)];
    [mainPath addLineToPoint: CGPointMake(21.88, 29.67)];
    [mainPath addCurveToPoint: CGPointMake(11.94, 25.47) controlPoint1: CGPointMake(18.28, 29.67) controlPoint2: CGPointMake(14.68, 28.27)];
    [mainPath addCurveToPoint: CGPointMake(11.94, 5.17) controlPoint1: CGPointMake(6.45, 19.86) controlPoint2: CGPointMake(6.45, 10.77)];
    [mainPath addCurveToPoint: CGPointMake(21.88, 0.97) controlPoint1: CGPointMake(14.68, 2.37) controlPoint2: CGPointMake(18.28, 0.97)];
    [mainPath addLineToPoint: CGPointMake(21.88, 6.49)];
    [mainPath addCurveToPoint: CGPointMake(15.76, 9.07) controlPoint1: CGPointMake(19.67, 6.49) controlPoint2: CGPointMake(17.45, 7.35)];
    [mainPath addCurveToPoint: CGPointMake(15.76, 21.56) controlPoint1: CGPointMake(12.38, 12.52) controlPoint2: CGPointMake(12.38, 18.11)];
    [mainPath addCurveToPoint: CGPointMake(21.88, 24.15) controlPoint1: CGPointMake(17.45, 23.29) controlPoint2: CGPointMake(19.67, 24.15)];
    [mainPath addLineToPoint: CGPointMake(43.14, 24.15)];
    [mainPath addLineToPoint: CGPointMake(35.89, 16.76)];
    [mainPath addLineToPoint: CGPointMake(38.44, 14.16)];
    [mainPath addLineToPoint: CGPointMake(51.15, 26.69)];
    [mainPath addLineToPoint: CGPointMake(38.44, 39.66)];
    [mainPath addLineToPoint: CGPointMake(35.89, 37.06)];
    [mainPath closePath];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, iconHighlightOffset, iconHighlightBlurRadius, iconHighlight.CGColor);
    [iconColor setFill];
    [mainPath fill];
    
    ////// Main Inner Shadow
    CGRect mainBorderRect = CGRectInset([mainPath bounds], -iconShadowBlurRadius, -iconShadowBlurRadius);
    mainBorderRect = CGRectOffset(mainBorderRect, -iconShadowOffset.width, -iconShadowOffset.height);
    mainBorderRect = CGRectInset(CGRectUnion(mainBorderRect, [mainPath bounds]), -1, -1);
    
    UIBezierPath* mainNegativePath = [UIBezierPath bezierPathWithRect: mainBorderRect];
    [mainNegativePath appendPath: mainPath];
    mainNegativePath.usesEvenOddFillRule = YES;
    
    CGContextSaveGState(context);
    {
        CGFloat xOffset = iconShadowOffset.width + round(mainBorderRect.size.width);
        CGFloat yOffset = iconShadowOffset.height;
        CGContextSetShadowWithColor(context,
                                    CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)),
                                    iconShadowBlurRadius,
                                    iconShadow.CGColor);
        
        [mainPath addClip];
        CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(mainBorderRect.size.width), 0);
        [mainNegativePath applyTransform: transform];
        [[UIColor grayColor] setFill];
        [mainNegativePath fill];
    }
    CGContextRestoreGState(context);
    
    CGContextRestoreGState(context);
    
    
    
    
}

//- (id) hitTest:(CGPoint)point withEvent:(UIEvent*)event {
//        
//}
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event{
    if(point.x > 0 && point.x < self.frame.size.width && point.y < 0 && point.y > - self.frame.size.height){
        return true;        
    }
    else {
        return false;

    }
}
@end
