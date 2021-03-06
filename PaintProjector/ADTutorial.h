//
//  Tutorial.h
//  PaintProjector
//
//  Created by 胡 文杰 on 6/15/14.
//  Copyright (c) 2014 WenjiHu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADTutorialStep.h"

@interface ADTutorial : NSObject
//从当前步骤开始
- (void)startCurrentStep;
//从指定步骤名字开始
- (void)startFromStepName:(NSString *)name;
//从指定步骤序号开始
- (void)startFromStepIndex:(NSInteger)index;
//进入下一步
- (void)stepNext:(void (^)(void))block;
//进入下一步并直接开始
- (void)stepNextImmediate;
//中止
- (void)cancel;
//结束
- (void)end;
//添加步骤
- (ADTutorialStep *)addStep:(NSString *)name;
- (ADTutorialStep *)addStep:(NSString *)name ofClass:(NSString *)className;
//删除步骤
- (void)removeStep:(NSString *)name;
@property (assign, nonatomic) id delegate;
@property (copy, nonatomic) NSString *name;
@property (assign, nonatomic) NSInteger curStepIndex;
@property (weak, nonatomic) ADTutorialStep *curStep;
@property (retain, nonatomic) NSMutableArray *steps;
@end

@protocol ADTutorialDelegate
- (void)willTutorialEnd:(ADTutorial *)tutorial finished:(BOOL)finished;
@end
