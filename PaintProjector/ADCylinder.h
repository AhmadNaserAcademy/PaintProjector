//
//  Cylinder.h
//  PaintProjector
//
//  Created by 胡 文杰 on 13-7-28.
//  Copyright (c) 2013年 WenjiHu. All rights reserved.
//

//#import "Entity.h"
#import "REModelEntity.h"

@interface ADCylinder : REModelEntity
@property (assign, nonatomic) GLKVector3 eye;
@property(weak, nonatomic)RETexture *reflectionTex;
@property(assign, nonatomic)GLKVector4 reflectionTexUVSpace;
@property(assign, nonatomic)CGFloat reflectionStrength;

@end
