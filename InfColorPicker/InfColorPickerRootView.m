//
//  InfColorPickerRootView.m
//  PaintProjector
//
//  Created by 胡 文杰 on 13-9-26.
//  Copyright (c) 2013年 WenjiHu. All rights reserved.
//

#import "InfColorPickerRootView.h"
#import "PaintUIKitStyle.h"

@implementation InfColorPickerRootView

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
     //罩一层白色在上面
     // Drawing code
//     UIColor* color = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: FuzzyTransparentAlpha];
//     
//     UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: self.bounds];
//     [color setFill];
//     [rectanglePath fill];
     
     [PaintUIKitStyle drawCrystalGradientInView:self];
 }

@end
