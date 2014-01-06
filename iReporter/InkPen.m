//
//  InkPen.m
//  PaintProjector
//
//  Created by 胡 文杰 on 13-10-19.
//  Copyright (c) 2013年 WenjiHu. All rights reserved.
//

#import "InkPen.h"

@implementation InkPen
//- (id)initWithPaintView:(PaintingView *)paintView{
//    self = [super initWithPaintView:paintView];
//    if (self !=nil) {
//        
//
//        
//        [self resetDefaultBrushState];
//    }
//    
//    return self;
//}

- (BOOL)isEditable{
    return true;
}

- (void)setRadiusSliderValue{
    self.radiusSliderMinValue = 1;
    self.radiusSliderMaxValue = 2;
}


- (void)resetDefaultBrushState{
    self.brushState.radius = 2;
    self.brushState.radiusFade = 0;
    self.brushState.radiusJitter = 0;
    self.brushState.opacity = 1.0;
    self.brushState.flow = 1;
    self.brushState.flowFade = 0;
    self.brushState.flowJitter = 0;
    self.brushState.angle = 0;
    self.brushState.angleFade = 0;
    self.brushState.angleJitter = 0;
    self.brushState.roundness = 1.0;
    self.brushState.hardness = 1.0;
    self.brushState.spacing = 0.15;
    self.brushState.scattering = 0;
    self.brushState.isDissolve = false;
    self.brushState.isAirbrush = false;
    self.brushState.isVelocitySensor = true;
    self.brushState.isRadiusMagnifySensor = true;
    self.brushState.wet = 0;
    
    [self setBrushCommonTextures];
    [self setBrushShapeTexture:nil];
}
@end