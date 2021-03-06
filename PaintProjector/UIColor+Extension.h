//
//  UIColor+UIColor_String.h
//  PaintProjector
//
//  Created by kobunketsu on 14-3-1.
//  Copyright (c) 2014年 WenjiHu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Extension)
+(UIColor*)colorWithString:(NSString*)string;
-(NSString*)colorString;

-(UIColor*)blendColor:(UIColor*)color withAlpha:(CGFloat)alpha;
#pragma mark- Common Colors
+ (UIColor*)selectableColor;
@end
