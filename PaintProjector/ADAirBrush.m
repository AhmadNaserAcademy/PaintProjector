//
//  AirBrush.m
//  PaintProjector
//
//  Created by 胡 文杰 on 13-10-19.
//  Copyright (c) 2013年 WenjiHu. All rights reserved.
//

#import "ADAirBrush.h"
static ADBrushState *brushStateAirBrush = nil;
@implementation ADAirBrush
//- (id)initWithPaintView:(PaintingView *)paintView{
//    self = [super initWithPaintView:paintView];
//    if (self !=nil) {
//
//        [self resetDefaultBrushState];
//    }
//    
//    return self;
//}
+(void)setBrushStateTemplate:(ADBrushState*)brushState{
    brushStateAirBrush = brushState;
}
+(ADBrushState*)brushStateTemplate{
    return brushStateAirBrush;
}
- (NSString*)name{
    return @"ADAirBrush";
}

- (BOOL)isEditable{
    return true;
}

- (void)setRadiusSliderValue{
    self.radiusSliderMinValue = 5;
    self.radiusSliderMaxValue = 100;
}

- (void)resetDefaultBrushState{
    self.brushState.opacity = 0.5;//1;
    self.brushState.flow = 0.3;
    self.brushState.flowJitter = 0.0;
    self.brushState.flowFade = 0.0;
    self.brushState.radius = 30;
    self.brushState.radiusJitter = 0.0;
    self.brushState.radiusFade = 0.0;
    self.brushState.hardness = 0;
    self.brushState.roundness = 1.0;
    self.brushState.angle = 0;
    self.brushState.angleJitter = 0.0;
    self.brushState.angleFade = 0.0;
    self.brushState.spacing = 0.025;
    self.brushState.scattering = 0;
    self.brushState.isAirbrush = false;
    self.brushState.isPatternTexture = false;
    self.brushState.isVelocitySensor = false;
    self.brushState.isRadiusMagnifySensor = false;    
    self.brushState.wet = 0;
}

- (BOOL)free{
    return false;
}

- (NSInteger)iapProductFeatureId{
    return 4;
}
@end
