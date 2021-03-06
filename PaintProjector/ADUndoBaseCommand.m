//
//  UndoBaseCommand.m
//  ProjectPaint
//
//  Created by 胡 文杰 on 13-6-12.
//  Copyright (c) 2013年 WenjiHu. All rights reserved.
//

#import "ADUndoBaseCommand.h"

@implementation ADUndoBaseCommand

- (ADUndoBaseCommand*)initWithTexture:(GLuint)texture{
    self = [super init];
    if (self!=nil) {
        _texture = texture;
    }
    
    return self;
}
-(void)execute{
    DebugLogFuncStart(@"execute");
    [self.delegate willExecuteUndoBaseCommand:self];

    [super endExecute];

}
@end
