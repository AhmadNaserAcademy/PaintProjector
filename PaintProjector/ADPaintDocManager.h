//
//  PaintSaveDocManager.h
//  PaintProjector
//
//  Created by 胡 文杰 on 13-3-27.
//  Copyright (c) 2013年 Hu Wenjie. All rights reserved.
//
//名称:绘图文件管理器
//描述:用于管理应用的文件
//功能:目录创建 删除 目录下的文件加载

#import <Foundation/Foundation.h>
@class ADPaintDoc;

@interface ADPaintDocManager : NSObject{
    NSMutableArray* _directories;          //文件系统中的目录列表
}
+(id)sharedInstance;

- (int)directoryCount;
- (BOOL)createDirectory:(NSString*)dirName;
- (NSString*)directoryPath:(int)index;

- (NSMutableArray *)loadPaintDocsInDirectory:(NSString*)dirName;
- (NSMutableArray *)loadPaintDocsInDirectoryIndex:(int)dirIndex;

- (ADPaintDoc*)createPaintDocInDirectory:(NSString*)dirName;
- (ADPaintDoc*)clonePaintDoc:(ADPaintDoc*)paintDoc;
- (void)deletePaintDoc:(ADPaintDoc*)paintDoc;
- (void)renamePaintDoc:(ADPaintDoc*)paintDoc name:(NSString*)name;
- (NSString *)nextPaintDocPathInDirectory:(NSString*)dirName;


/*
+ (NSMutableArray *)loadPaintDocs;



+ (NSMutableArray *)importablePaintDocs;
 */
@end
