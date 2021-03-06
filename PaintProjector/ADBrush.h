//
//  Brush.h
//  PaintProjector
//
//  Created by 文杰 胡 on 12-10-28.
//  Copyright (c) 2012年 Hu Wenjie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "ADBrushTypeButton.h"
#import "ADUltility.h"
#import "RETextureManager.h"
#import "ADShaderBrush.h"
#import "REMaterial.h"
#import "RERenderTexture.h"
#import "ADBrushState.h"

@class ADPaintView;
@class REGLWrapper;

#define BUFFER_OFFSET(i) ((char *)NULL + (i))
#define kBrushCurveIntervalScale 1.2
#define kBrushPixelStep		2

#pragma mark- BrushState

#pragma mark- Brush
typedef enum
{
    BrushType_Pencil,
    BrushType_Pen,
    BrushType_Marker,
    BrushType_Eraser,
    BrushType_Chalk,
    BrushType_Finger,
    BrushType_Max,
}BrushType;

typedef struct {
    float Position[4];
    float Color[4];
} BrushVertex;

@class ADBrush;
@protocol ADBrushDelegate
- (void) willBrushColorChanged:(ADBrush*)brush;
- (void) willUpdateSmudgeTextureWithBrushState:(ADBrushState*)brushState location:(CGPoint)point;
- (void) willUpdateSmudgeSubPoint;
//- (void) willUpdateLayerContentCGRectWithPoint:(CGPoint)point radius:(CGFloat)radius;
@end

@interface ADBrush : NSObject
{
//    BrushState* _brushState;    

//    CGPoint _lastDrawPoint;
//    CGPoint _curDrawPoint; 
    
    //shader        
//    GLuint _programBrush;
//    GLuint _vertexProgram;
//    GLuint _fragmentProgram;
//    GLuint _ppo;

    //tex
//    GLuint _maskTexture;
//    GLuint _shapeTexture;
//    GLuint _maskTextureUniform;
//    GLuint _patternTexture;
//    GLuint _patternTextureUniform;
//    GLuint _paramsUniform;
//    GLuint _params2Uniform;
//    GLuint _projectionUniform;
//    GLuint _colorUniform;

//    GLuint _smudgeTexture;
//    GLuint _smudgeBackTexture;
//    GLuint _smudgeTextureUniform;
  
    //temp
    CGFloat _red;
    CGFloat _green;
    CGFloat _blue;
    CGFloat _alpha;
    
    GLfloat _projectionMat[16];
}
+(void)setBrushStateTemplate:(ADBrushState*)brushState;
+(ADBrushState*)brushStateTemplate;
#pragma mark- InAppPurchase
@property (assign, nonatomic, readonly) BOOL free;
@property (assign, nonatomic, readonly) BOOL available;
@property (assign, nonatomic, readonly) NSInteger iapProductFeatureId;

#pragma mark- Common
@property (assign, nonatomic) id delegate;
@property (copy, nonatomic) NSString *name;
@property (assign, nonatomic, readonly) BOOL isEditable;

#pragma mark- Core
@property (weak, nonatomic) ADPaintView* paintView;
@property (assign, nonatomic) CGSize canvasSize;
@property (retain, nonatomic) ADBrushState* brushState;
@property (assign, nonatomic) CGPoint lastSegmentEndPoint;
@property (assign, nonatomic) CGPoint curSegmentEndPoint;
@property (assign, nonatomic) float curStrokedLength;//当前绘制的长度

#pragma mark- OpenGLES
@property (assign, nonatomic) BrushVertex* vertexBuffer;
@property (assign, nonatomic) float patternTextureSize;
@property (retain, nonatomic) ADShaderBrush *shader;
@property (retain, nonatomic) REMaterial *material;
@property (retain, nonatomic) RETexture *shapeTexture;
@property (retain, nonatomic) RETexture *maskTexture;
@property (retain, nonatomic) RETexture *patternTexture;
@property (retain, nonatomic) RERenderTexture *smudgeTexture;
@property (retain, nonatomic) RERenderTexture *smudgeBackTexture;
#pragma mark- UI
@property (assign, nonatomic) float radiusSliderMaxValue;
@property (assign, nonatomic) float radiusSliderMinValue;

- (id)initWithPaintView:(ADPaintView*)paintView delegate:(id)delegate;
- (void)initGL;
- (void)tearDownGL;
//- (BOOL)loadShader;
- (void)resetDefaultTextures;
- (void)resetDefaultBrushState;
- (BOOL)createSmudgeFramebuffers;
- (void)deleteSmudgeFramebuffers;
- (void)swapSmudgeFramebuffers;

- (CGFloat)radius;
- (void)setRadius:(CGFloat)newValue;
- (void)setBrushCommonTextures;
- (void)setBrushShapeTexture:(NSString*)textureName;
- (void)setPatternTextureWithImage:(NSString*)patterName;
- (UIColor *)color;
- (void)setColor:(UIColor *)newValue;
- (void)setBlendModeWithBrushState:(ADBrushState*)brushState;

- (void)startDraw:(CGPoint)startLocation;
- (void)prepareWithBrushState:(ADBrushState*)brushState lastBrushState:(ADBrushState*)lastBrushState;
- (size_t)numOfSegmentPointFromStart:(CGPoint)start toEnd:(CGPoint)end brushState:(ADBrushState*)brushState isTapDraw:(BOOL)isTapDraw;
- (void)fillDataFromPoint:(CGPoint)start toPoint:(CGPoint)end segmentOffset:(int)segmentOffset brushState:(ADBrushState*)brushState isTapDraw:(BOOL)isTapDraw isImmediate:(BOOL)isImmediate;
- (void)fillSegmentBezierOrigin:(CGPoint) origin Control:(CGPoint) control Destination:(CGPoint)destination Count:(size_t) count segmentOffset:(int)segmentOffset brushState:(ADBrushState*)brushState isImmediate:(BOOL)isImmediate;
- (void)renderImmediate:(BOOL)isImmediate;
- (void)endDraw;



@end
