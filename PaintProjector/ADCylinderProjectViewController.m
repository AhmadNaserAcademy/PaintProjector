//
//  CylinderProjectViewController.m
//  PaintProjector
//
//  Created by 胡 文杰 on 13-7-21.
//  Copyright (c) 2013年 WenjiHu. All rights reserved.
//

#import "ADCylinderProjectViewController.h"
#import <Social/Social.h>
#import "REResources.h"
#import "ADSharedPopoverController.h"
#import "ADUnitConverter.h"
#import "ADSimpleIAPManager.h"
#import "ADPaintUIKitAnimation.h"
#import "REAssetDatabase.h"
#import "ADCylinderProjectVirtualDeviceCollectionViewController.h"
#import "ADSimpleTutorialManager.h"
#import "AppDelegate.h"
#import "ADShaderCylinderProject.h"
#import "ADShaderCylinder.h"
#import "ADShaderNoLitTexture.h"
#import "ADShaderUnlitTransparentAdditive.h"
#import "ADDeviceHardware.h"
#import "ADReversePaintInputData.h"
#import "iRate.h"
#import "ADSimpleAlertView.h"


#if TESTFLIGHT
#import "Questionnaire.h"
#endif

//avoid z fighting
#define FarClipDistance 10
#define NearClipDistance 0.005

#define PaintDocTitleMinWidth 200
#define PaintDocTitleFadeInOutDuration 0.2
#define CylinderFadeInOutDuration 0.4
#define CylinderFadeInOutDeallocDelay 0.4
#define CylinderResetParamDuration 0.4
#define CylinderResetDelay 0.2
#define CylinderViewChangeDuration 1
#define TempPaintFrameToPaintFadeInDelay 0.2
#define TempPaintFrameToGalleryFadeInDuration 0.4
#define TempPaintFrameToPaintFadeInDuration 0.4
#define PopoverFrameWithIconAlignedWidth 330

static float DeviceWidth = 0.154;

@interface ADCylinderProjectViewController ()
//TODO: deprecated
@property (retain, nonatomic) ADSharedPopoverController *sharedPopoverController;
@property (assign, nonatomic)GLKVector2 touchDirectionBegin;
//@property (assign, nonatomic)float translateImageX;//圆柱体中图片横向移动
@property(nonatomic, copy) NSString *userInputParamkeyPath;
//@property (retain, nonatomic) REAnimation *resetAnimation;
//VC切换动画效果管理器
@property (nonatomic) ADPaintScreenTransitionManager *transitionManager;

//@property (retain, nonatomic) UIAlertView *saveAlertView;
@property (retain, nonatomic) ADCylinderProjectUserInputParams *userInputParamsSrc;
@property (retain, nonatomic) ADCylinderProjectUserInputParams *userInputParamsMacPro;
@property (retain, nonatomic) ADCylinderProjectUserInputParams *userInputParamsTeaCup;
@property (retain, nonatomic) ADCylinderProjectUserInputParams *userInputParamsCan;
@property (retain, nonatomic) ADCylinderProjectUserInputParams *userInputParamsPen;
@property (retain, nonatomic) ADCylinderProjectUserInputParams *userInputParamsNormal;
@property (retain, nonatomic) ADCylinderProjectUserInputParams *userInputParamsBrowse;//初始用户输入参数

@property (copy, nonatomic) NSString *paintDocTitle;
@end

@implementation ADCylinderProjectViewController

//core motion

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self initWithCustom];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    DebugLogSystem(@"initWithCoder");
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initWithCustom];
    }
    return self;
}

- (void)initWithCustom{

}
- (void)viewWillAppear:(BOOL)animated{
    DebugLogSystem(@"[ viewWillAppear ]");
    [self addBackgroundView];
    
    //用于解决启动闪黑屏的问题
    [self setupBaseParams];
    
    [self setupInputParams];
    
    [self setupGL];
    
    [self setupScene];
    
    //run completion block
//    [self allViewUserInteractionEnable:true];
    
    [self tutorialSetup];
}

- (void)viewDidAppear:(BOOL)animated{
    DebugLogSystem(@"[ viewDidAppear ]");
    [Flurry logEvent:@"CP_inCylinderProject" withParameters:nil timed:true];
    [Flurry logPageView];
    
    [self.delegate willCompleteLaunchTransitionToCylinderProject];
    
    [ADPaintUIKitAnimation view:self.rootView switchDownToolBarToView:self.downToolBar completion:nil];
    [ADPaintUIKitAnimation view:self.rootView switchTopToolBarToView:self.iAdBar completion:nil];
    [self displayTitle:true withPaintDoc:[ADPaintFrameManager curGroup].curPaintDoc];
    
    [self tutorialStartCurrentStep];

}

-(void)viewWillDisappear:(BOOL)animated{
    DebugLogSystem(@"[ viewWillDisappear ]");
    [self destroyScene];
    
    [self tearDownGL];
    
    [self destroyInputParams];
    
    [self destroyBaseParams];
}

-(void)viewDidDisappear:(BOOL)animated{
    DebugLogSystem(@"[ viewDidDisappear ]");
    [Flurry endTimedEvent:@"CP_inCylinderProject" withParameters:nil];
    
    [self destroyBackgroundView];
}

- (void)viewDidLoad
{
    DebugLogSystem(@"[ viewDidLoad ]");
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self registerDeviceRotation];
    

    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(applicationDidEnterBackground:)
     name:UIApplicationDidEnterBackgroundNotification
     object:nil];
    
    //通知程序返回激活状态
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(applicationWillEnterForeground:)
     name:UIApplicationWillEnterForegroundNotification
     object:nil];
    
    //通知程序退出激活状态
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(applicationWillResignActive:)
     name:UIApplicationWillResignActiveNotification
     object:nil];
    
    //通知程序即将关闭
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(applicationWillTerminate:)
     name:UIApplicationWillTerminateNotification
     object:nil];
  
    
    self.projectView.opaque = NO;
    
//    [self allViewUserInteractionEnable:true];
    
    self.transitionManager = [[ADPaintScreenTransitionManager alloc]init];
    self.transitionManager.delegate = self;
    
    //创建glkViewController
    self.glkViewController = [[GLKViewController alloc]init];
    self.glkViewController.view = self.projectView;
    self.glkViewController.delegate = self;
    // then add the glkview as the subview of the parent view
    //    [rootView addSubview:_myGlkViewController.view];
    // add the glkViewController as the child of self
    [self addChildViewController:self.glkViewController];
    [self.glkViewController didMoveToParentViewController:self];
    

    //创建context
    self.projectView.delegate = self;
    
    self.browseNextAction = [[ADCustomPercentDrivenInteractiveTransition alloc]init];
    self.browseNextAction.delegate = self;
    self.browseNextAction.name = @"browseNext";
    self.browseLastAction = [[ADCustomPercentDrivenInteractiveTransition alloc]init];
    self.browseLastAction.delegate = self;
    self.browseLastAction.name = @"browseLast";
    
    //TODO: 关闭水平监测，查内存持续增长问题
//    [self initMotionDetect];
    self.isReversePaint = false;
    self.isSetupMode = false;
    self.isTopViewMode = false;
    
    [self loadRefObjectUserInputParams];
    
    self.paintDocNameTextField.placeholder = NSLocalizedString(@"GiveAName", nil);
    
    //加入广告
#if UseiAd
    [self createAdBannerView];
#endif
}

- (void)viewDidUnload{
    DebugLogSystem(@"[ viewDidUnload ]");
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc{
    DebugLogSystem(@"[ dealloc ]");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];

}


#pragma mark- 主程序
- (void)unregisterDeviceRotation{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
}
- (void)registerDeviceRotation{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationChanged:)
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];
}
- (void)orientationChanged:(id)sender{
    DebugLogFuncStart(@"orientationChanged");
//    DebugLogWarn(@"rootView.frame %@", NSStringFromCGRect(self.rootView.frame));
//    DebugLogWarn(@"rootView.bounds %@", NSStringFromCGRect(self.rootView.bounds));
//    self.rootView.frame = self.rootView.bounds;
}

//运行中加载占用内存的大背景图片(如果放在nib中，presentViewController后还留在内存里)
- (void)addBackgroundView{
    ADRootCanvasBackgroundView *backgroundView = [[ADRootCanvasBackgroundView alloc]initWithFrame:self.rootView.frame];
    self.rootView.backgroundView = backgroundView;
    [self.rootView addSubview:backgroundView];
    [self.projectView removeFromSuperview];
    [backgroundView addSubview:self.projectView];
    [self.rootView sendSubviewToBack:backgroundView];
}
//运行中卸载占用内存的大背景图片
- (void)destroyBackgroundView{
    [self.projectView removeFromSuperview];
    [self.rootView addSubview:self.projectView];
    [self.rootView sendSubviewToBack:self.projectView];
    [self.rootView.backgroundView removeFromSuperview];
    self.rootView.backgroundView = nil;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)applicationDidEnterBackground:(id)sender{
    DebugLogSystem(@"applicationDidEnterBackground");

}

- (void)applicationWillEnterForeground:(NSNotification *)note{
    DebugLogSystem(@"applicationWillEnterForeground");
}

-(void)applicationWillResignActive:(id)sender{
    DebugLogSystem(@"applicationWillResignActive");
//    [self uploadAndSaveDoc];
}

-(void)applicationWillTerminate:(id)sender{
    DebugLogSystem(@"applicationWillTerminate");
}

#pragma mark- 交互控制 UserInteraction
- (void)lockButtonInteraction:(BOOL)lock{
    self.iAdBar.userInteractionEnabled = !lock;
    self.downToolBar.userInteractionEnabled = !lock;
    self.topToolBar.userInteractionEnabled = !lock;
}
- (void)lockInteraction:(BOOL)lock{
    
    if (self.isSetupMode) {
        self.projectView.userInteractionEnabled = false;
    }
    else{
        self.projectView.userInteractionEnabled = !lock;
    }
    self.iAdBar.userInteractionEnabled = !lock;
    self.downToolBar.userInteractionEnabled = !lock;
    self.topToolBar.userInteractionEnabled = !lock;
}

#pragma mark- UI动画
- (void)allViewUserInteractionEnable:(BOOL)enable{
    for (UIView* view in self.allViews) {
        view.userInteractionEnabled = enable;
    }
}

#pragma mark- 工具栏

- (IBAction)galleryButtonTouchUp:(UIButton *)sender {
//    DebugLogIBAction(sender, @"galleryButtonTouchUp");
    [RemoteLog logAction:@"CP_galleryButtonTouchUp" identifier:sender];
    
    sender.selected = true;
    [self lockInteraction:true];

    //do some work
    if (self.isSetupMode) {
        [self alvertSaveUserInputParamsWithCompletionBlock:^(BOOL confirm) {
            [self transitionToGallery];
        }];
    }
    else{
        [self transitionToGallery];
    }

}

//- (IBAction)printButtonTouchUp:(UIButton *)sender {
//    //转换到顶视图
//    if (self.sideViewButton.hidden) {
//        self.sideViewButton.hidden = false;
//        self.topViewButton.hidden = true;
//        
//        REAnimationClip *animClip = [RECamera.mainCamera.animation.clips valueForKey:@"bottomToTopAnimClip"];
//        TPPropertyAnimation *propAnim = animClip.propertyAnimations.firstObject;
//        [propAnim setCompletionBlock:^{
//            [self exportToAirPrint];
//        }];
//        RECamera.mainCamera.animation.clip = animClip;
//        RECamera.mainCamera.animation.target = self;
//        [RECamera.mainCamera.animation play];
//    }
//    else{
//        [self exportToAirPrint];
//    }
//}

- (void)setupAnamorphParamsSave{
    [ADPaintFrameManager curGroup].curPaintDoc.userInputParams = [self.userInputParams copy];
    [[ADPaintFrameManager curGroup].curPaintDoc saveInfo];
}
- (void)setupAnamorphParamsBegan{
    [self setupAnamorphParamsAnimationCompletion:^{
        //no animation
        [self lockInteraction:false];
        [self tutorialStartCurrentStep];
    }];
}
- (void)setupAnamorphParamsDone{
    [self setupAnamorphParamsDoneAnimationCompletion:^{
        [self lockInteraction:false];
        
        [self tutorialStartCurrentStep];
    }];
}

//提示是否需要保存
- (void)alvertSaveUserInputParamsWithCompletionBlock:(AutoAlertViewClickHandler)completionBlock{
    //提示是否保存到模版
    ADSimpleAlertView *alertView = [[ADSimpleAlertView alloc]initWithTitle:@"" message:NSLocalizedString(@"SaveUserInputParams", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Restore", nil) otherButtonTitles:NSLocalizedString(@"Save", nil), nil];
    alertView.delegate = alertView;
//    alertView.tag = 2;
    
    AutoAlertViewClickHandler handler = ^(BOOL confirm) {
        if (confirm) {
            //Save UserInputParams
            [self setupAnamorphParamsSave];
            completionBlock(YES);
        }
        else{
            //Dont Save. Exist to original userInputParams
            [self animationToTarget:self.userInputParams params:self.userInputParamsSrc.propertyNameValueDic duration:CylinderResetParamDuration timing:REPropertyAnimationTimingEaseOut completionDelegate:self completionBlock:^{
                [self flushUIUserInputParams];
                [UIView animateWithDuration:0 delay:CylinderResetDelay options:UIViewAnimationOptionCurveEaseInOut animations:^{
                } completion:^(BOOL finished) {
                    completionBlock(NO);
                }];
            }];
        }
    };
    
    [alertView setClickHandler:handler];
    [alertView show];
}


- (IBAction)setupButtonTouchUp:(UIButton *)sender {
    [RemoteLog logAction:@"CP_setupButtonTouchUp" identifier:sender];
    
    [self tutorialStepNextImmediate:false];

    self.isSetupMode = !self.isSetupMode;
    if (self.isSetupMode) {
        [Flurry logEvent:@"CP_inSetup" withParameters:nil timed:true];
    }
    else{
        [Flurry endTimedEvent:@"CP_inSetup" withParameters:nil];
    }
    
    [self lockInteraction:true];
    
    if (self.isSetupMode) {
        [self setupAnamorphParamsBegan];
    }
    else{
        //提示是否保存到模版
        [self alvertSaveUserInputParamsWithCompletionBlock:^(BOOL confirm) {
            [self setupAnamorphParamsDone];
       }];
    }
}

- (IBAction)shareButtonTouchUp:(UIButton *)sender {
   [RemoteLog logAction:@"CP_shareButtonTouchUp" identifier:sender];
    sender.selected = true;
    
    [self share];
}

- (IBAction)infoButtonTouchUp:(UIButton *)sender {
    [RemoteLog logAction:@"CP_infoButtonTouchUp" identifier:sender];
    sender.selected = true;
    
    //TODO:产品名称, 介绍Anamorphosis 展示产品支持主页, 欢迎界面(教程),
    [self productInfo];
}
- (void)paint{
    //开始转换到绘图
    if (self.isReversePaint) {
        //hide cylinder
        //        self.cylinder.active = false;
        //        self.cylinderInterLight.active = false;
        //        self.cylinderTopLight.active = false;
        //        self.cylinderBottom.active = false;
        //        [self glkView:self.projectView drawInRect:self.projectView.frame];
        
        //创建临时paintDoc
        ADPaintDoc* paintDoc = [ADPaintFrameManager curGroup].curPaintDoc;
        paintDoc.reverseData = [[ADPaintData alloc]init];
        paintDoc.reverseData.version = [ADPaintDoc currentVersion];
        paintDoc.reverseData.title = @"reversePaintDoc";
        
        //截取反向绘制的底图
        ADBackgroundLayer *backgroundLayer = [[ADBackgroundLayer alloc]init];
        backgroundLayer.visible = true;
        UIGraphicsBeginImageContextWithOptions(self.rootView.frame.size, false, 0);
        [self.rootView.backgroundView drawViewHierarchyInRect:self.rootView.backgroundView.bounds afterScreenUpdates:true];
        UIImage* image = UIGraphicsGetImageFromCurrentImageContext();    //origin downleft
        UIGraphicsEndImageContext();
        backgroundLayer.data = UIImagePNGRepresentation(image);
        paintDoc.reverseData.backgroundLayer = backgroundLayer;
        
        //所有图层
        ADPaintLayer *newLayer = [ADPaintLayer createBlankLayerWithSize:self.rootView.bounds.size transparent:true];
        NSMutableArray *layers = [[NSMutableArray alloc]initWithObjects:newLayer, nil];
        paintDoc.reverseData.layers = layers;
        
        [ADPaintUIKitAnimation view:self.rootView switchTopToolBarFromView:self.topToolBar completion:nil];
        [ADPaintUIKitAnimation view:self.rootView switchTopToolBarFromView:self.iAdBar completion:nil];
        [ADPaintUIKitAnimation view:self.rootView switchDownToolBarFromView:self.downToolBar completion:^{
            [self transitionToPaint:paintDoc];
        }];
    }
    else{
        //reset userinput
        if(self.isSetupMode){
            [self setupAnamorphParamsDoneAnimationCompletion:^{
                [self transitionToPaint:[ADPaintFrameManager curGroup].curPaintDoc];
            }];
        }
        else{
            [self transitionToPaint:[ADPaintFrameManager curGroup].curPaintDoc];
        }
    }
}

- (IBAction)paintButtonTouchUp:(UIButton *)sender {
    NSString *logString = self.isReversePaint ? @"CP_reversePaintButtonTouchUp" : @"CP_paintButtonTouchUp";
    [RemoteLog logAction:logString identifier:sender];
    
    [self tutorialStepNextImmediate:false];
    
    //UI
    [self lockInteraction:true];
    sender.selected = true;
    
    if (self.isSetupMode) {
        [self alvertSaveUserInputParamsWithCompletionBlock:^(BOOL confirm) {
            [self paint];
        }];
    }
    else{
        [self paint];
    }
}

#pragma mark- 转换Transition
- (void)transitionToGallery{
    //打开从paintCollectionVC transition 时添加的view
//    UIImageView *tempView = (UIImageView *)[rootView subViewWithTag:100];
//    if (tempView) {
//        //刷新的当前图片
//        NSString *path = [[Ultility applicationDocumentDirectory]stringByAppendingPathComponent:[[PaintFrameManager curGroup] curPaintDoc].thumbImagePath];
//        tempView.image = [UIImage imageWithContentsOfFile:path];
//        [UIView animateWithDuration:TempPaintFrameToGalleryFadeInDuration animations:^{
//            tempView.alpha = 1;
//        }completion:^(BOOL finished) {
//        }];
//    }
    
    //取消动画
//    REAnimationClip *animClip = [self.cylinderProjectCur.animation.clips valueForKey:@"fadeOutAnimClip"];
//    self.cylinderProjectCur.animation.clip = animClip;
//    [self.cylinderProjectCur.animation play];
    
    [self.delegate willTransitionToGallery];
    
    //ToolBar动画
    [ADPaintUIKitAnimation view:self.rootView switchTopToolBarFromView:self.topToolBar completion:nil];
    [ADPaintUIKitAnimation view:self.rootView switchTopToolBarFromView:self.iAdBar completion:nil];
    
    [ADPaintUIKitAnimation view:self.rootView switchDownToolBarFromView:self.downToolBar completion:^{
        [self lockInteraction:false];
    }];
}

- (void)transitionToPaint:(ADPaintDoc*)paintDoc{
    if (!paintDoc.userInputParams) {
        paintDoc.userInputParams = self.userInputParams;
    }
    
    //更新临时view
    NSString *path = [[ADPaintFrameManager curGroup] curPaintDoc].thumbImagePath;
    path = [[ADUltility applicationDocumentDirectory] stringByAppendingPathComponent:path];
    UIImageView *transitionImageView = (UIImageView *)[self.rootView subViewWithTag:100];
    transitionImageView.image = nil;
    transitionImageView.image = [UIImage imageWithContentsOfFile:path];
    
    //打开paintDoc
    if (self.isReversePaint) {
        [self openPaintDoc:paintDoc];
    }
    else{
        //打开动画
        REAnimationClip *animClip = [self.cylinder.animation.clips valueForKey:@"reflectionFadeInOutAnimClip"];
        REPropertyAnimation *propAnim = animClip.propertyAnimations.firstObject;
        propAnim.duration = 0.5;
        propAnim.fromValue = [NSNumber numberWithFloat:1];
        propAnim.toValue = [NSNumber numberWithFloat:1];
        [self.cylinder.animation play];
        
        //确定fromView的锚点，和放大缩小的尺寸
        CGRect rect = [self willGetCylinderMirrorFrame];
        CGFloat scale = self.rootView.frame.size.width / rect.size.width;
        CGPoint rectCenter = CGPointMake(rect.origin.x + rect.size.width * 0.5, rect.origin.y + rect.size.height * 0.5);
        rectCenter = CGPointMake(rectCenter.x, rectCenter.y);

        //调整:
        if ([ADDeviceHardware sharedInstance].isMini) {
            rectCenter.y += TransitionToPaintPixelOffsetY_Mini;
        }
        else{
            rectCenter.y += TransitionToPaintPixelOffsetY;
        }
        
        
        UIView *fromView = self.rootView;
        fromView.layer.anchorPoint = CGPointMake(rectCenter.x / fromView.frame.size.width, rectCenter.y / fromView.frame.size.height);
        fromView.layer.position = rectCenter;
        
        DebugLog(@"transitionToPaint fromView layer anchorPoint %@ position %@", NSStringFromCGPoint(fromView.layer.anchorPoint), NSStringFromCGPoint(fromView.layer.position));
        
        //透明度动画
        transitionImageView.alpha = 0;
        //    DebugLogWarn(@"fromView anchorPoint %@", NSStringFromCGPoint(fromView.layer.anchorPoint));
        
        [UIView animateWithDuration:TempPaintFrameToPaintFadeInDuration delay:TempPaintFrameToPaintFadeInDelay options:UIViewAnimationOptionCurveEaseOut animations:^{
            transitionImageView.alpha = 1;
            [fromView.layer setValue:[NSNumber numberWithFloat:scale] forKeyPath:@"transform.scale"];
        } completion:^(BOOL finished) {
            [self openPaintDoc:paintDoc];
        }];
    }
}
#pragma mark- 分享Share
- (void)share{
    ADShareTableViewController* shareTableViewController = [[ADShareTableViewController alloc]initWithStyle:UITableViewStylePlain];
    shareTableViewController.delegate = self;
    
    //align to down toolbar icon
    shareTableViewController.preferredContentSize = CGSizeMake(PopoverFrameWithIconAlignedWidth, shareTableViewController.tableViewHeight);
    
    self.sharedPopoverController = [[ADSharedPopoverController alloc]initWithContentViewController:shareTableViewController];
    self.sharedPopoverController.delegate = self;
    [self.sharedPopoverController presentPopoverFromRect:self.shareButton.bounds inView:self.shareButton permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}
#pragma mark- 分享 share Delegate
-(void)didSelectPostToSocialName:(NSString*)socialName{
    [RemoteLog logAction:[NSString stringWithFormat:@"CP_didSelectPostToSocialName:%@", socialName] identifier:nil];
    NSString *serviceType = nil;
    if ([socialName isEqualToString:@"Facebook"]) {
        serviceType = SLServiceTypeFacebook;
    }
    else if ([socialName isEqualToString:@"Twitter"]) {
        serviceType = SLServiceTypeTwitter;
    }
    else if ([socialName isEqualToString:@"SinaWeibo"]) {
        serviceType = SLServiceTypeSinaWeibo;
    }
    else if ([socialName isEqualToString:@"TencentWeibo"]) {
        serviceType = SLServiceTypeTencentWeibo;
    }
    
    if([SLComposeViewController isAvailableForServiceType:serviceType]) {
        SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:serviceType];
        
        NSString *postText = NSLocalizedString(@"ShareMessageBody", nil);
        [controller setInitialText:postText];
        
        BOOL topToolBarHidden = self.topToolBar.hidden;
        BOOL downToolBarHidden = self.downToolBar.hidden;
        BOOL iAdBarHidden = self.iAdBar.hidden;
        self.topToolBar.hidden = self.downToolBar.hidden = self.iAdBar.hidden = true;
        
        @autoreleasepool {
//            UIImage *image = [self.projectView snapshot];
            UIImage *image = [self.rootView snapshotImageAfterScreenUpdate:true];
            [controller addImage:image];
        }
        
        self.topToolBar.hidden = topToolBarHidden;
        self.downToolBar.hidden = downToolBarHidden;
        self.iAdBar.hidden = iAdBarHidden;
        
        NSURL *appURL = [NSURL URLWithString:PRODUCT_INFO_INTRODUCTION];
        [controller addURL:appURL];
        
        [controller setCompletionHandler:^(SLComposeViewControllerResult result){
            [self sharedToSocial:socialName completion:result];
            //iRate
            [[iRate sharedInstance] logEvent:false];
        }];
        [self.sharedPopoverController dismissPopoverAnimated:true];
        self.shareButton.selected = false;
        [self presentViewController:controller animated:YES completion:^{
        }];
    }
    else{
        [self.sharedPopoverController dismissPopoverAnimated:true];
        self.shareButton.selected = false;
        NSString *messageKey = [NSString stringWithFormat:@"%@NotInstalled", socialName];
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"" message:NSLocalizedString(messageKey, nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        [alertView show];
    }
}
-(void)sharedToSocial:(NSString*)socialName completion:(SLComposeViewControllerResult) result{
    if (result == SLComposeViewControllerResultCancelled) {
        [RemoteLog logAction:[NSString stringWithFormat:@"CP_sharedToSocial:%@ canceled", socialName] identifier:nil];
    }
    else{
        [RemoteLog logAction:[NSString stringWithFormat:@"CP_sharedToSocial:%@", socialName] identifier:nil];
    }
}

-(void)didSelectPostToEmail {
    [RemoteLog logAction:@"CP_didSelectPostToEmail" identifier:nil];
    if (![MFMailComposeViewController canSendMail]) {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"" message:NSLocalizedString(@"MailAccountNotAvailabel", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    NSString *postText = NSLocalizedString(@"EmailMessageSubject", nil);
    [picker setSubject:postText];
    NSString *messageBody = NSLocalizedString(@"EmailMessageBody", nil);
    
    //在顶视图状态下加入图片实际尺寸，方便于打印
    if (self.isTopViewMode) {
        NSString *realWidth = [NSString unitStringFromFloat:DeviceWidth / self.userInputParams.unitZoom];
        NSString *realHeight = [NSString unitStringFromFloat:(DeviceWidth / self.eyeTopAspect) / self.userInputParams.unitZoom];
        NSString *deviceDiameter = [NSString unitStringFromFloat:self.userInputParams.cylinderDiameter];
        NSString *messageDetail = [NSString stringWithFormat:@"<br>%@<br>%@: %@<br> %@: %@<br> %@: %@", NSLocalizedString(@"ExportHint", nil),
                                   NSLocalizedString(@"RealWidth", nil), realWidth, NSLocalizedString(@"RealHeight", nil), realHeight, NSLocalizedString(@"DeviceDiameter", nil), deviceDiameter];
        
        messageBody = [messageBody stringByAppendingString:messageDetail];
    }

    [picker setMessageBody:messageBody isHTML:YES];

    BOOL topToolBarHidden = self.topToolBar.hidden;
    BOOL downToolBarHidden = self.downToolBar.hidden;
    BOOL iAdBarHidden = self.iAdBar.hidden;
    self.topToolBar.hidden = self.downToolBar.hidden = self.iAdBar.hidden = true;
    
    @autoreleasepool {
//        UIImage *image = [self.projectView snapshot];
        UIImage *image = [self.rootView snapshotImageAfterScreenUpdate:true];
        //convert UIImage to NSData to add it as attachment
        NSData *imageData = UIImagePNGRepresentation(image);
        
        //this is how to attach any data in mail, remember mimeType will be different
        //for other data type attachment.
        [picker addAttachmentData:imageData mimeType:@"image/png" fileName:@"image.png"];
    }

    self.topToolBar.hidden = topToolBarHidden;
    self.downToolBar.hidden = downToolBarHidden;
    self.iAdBar.hidden = iAdBarHidden;
    
    //showing MFMailComposerView here
    [self.sharedPopoverController dismissPopoverAnimated:true];
    self.shareButton.selected = false;
    [self presentViewController:picker animated:true completion:^{
    }];
}
#pragma mark- 邮件代理 Email Delegate
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if(result == MFMailComposeResultCancelled)
        [RemoteLog logAction:@"CP_Mail cancelled" identifier:controller];
    else if(result == MFMailComposeResultSaved)
        [RemoteLog logAction:@"CP_Mail saved" identifier:controller];
    else if(result == MFMailComposeResultSent)
        [RemoteLog logAction:@"CP_Mail sent" identifier:controller];
    else if(result == MFMailComposeResultFailed)
        [RemoteLog logAction:@"CP_Mail failed" identifier:controller];
    
    [self dismissViewControllerAnimated:true completion:^{
    }];
}
#pragma mark- 设置Setup
- (void)setIsSetupMode:(BOOL)isSetupMode{
    _isSetupMode = isSetupMode;
    self.setupButton.selected = isSetupMode;
}

- (void)setupAnamorphParamsAnimationCompletion: (void (^) (void)) block{
    self.isSetupMode = true;
    //加载paintDoc保存的状态
    [self loadInputParams];
    [self displayTitle:false withPaintDoc:[ADPaintFrameManager curGroup].curPaintDoc];
    [ADPaintUIKitAnimation view:self.rootView switchTopToolBarToView:self.topToolBar completion:^{
        if (block != nil) {
            block();
        }
        
    }];
    
//    [self openVirtualDevice];
}

- (void)setupAnamorphParamsDoneAnimationCompletion: (void (^) (void)) block{
    self.isSetupMode = false;
    //恢复到初始状态
    [self resetInputParams];
    [ADPaintUIKitAnimation view:self.rootView switchTopToolBarFromView:self.topToolBar completion:^{
        [self displayTitle:true withPaintDoc:[ADPaintFrameManager curGroup].curPaintDoc];
        if (block != nil) {
            block();
        }

    }];
}

- (void)openUserInputParamValueSlider:(NSString*)keyPath minValue:(CGFloat)minValue maxValue:(CGFloat)maxValue{
    self.valueSlider.hidden = false;
    self.valueSlider.minimumValue = minValue;
    self.valueSlider.maximumValue = maxValue;
    NSNumber *num = [self valueForKeyPath:keyPath];
    self.valueSlider.value = num.floatValue;
    self.userInputParamkeyPath = keyPath;
}

- (void)deselectUserInputParams{
    for (UIButton *button in self.allUserInputParamButtons) {
        button.selected = false;
    }
    self.valueSlider.hidden = true;
}
- (void)closeUserInputParamValueSlider{
    self.valueSlider.hidden = true;
}

- (IBAction)userInputParamButtonTouchUp:(UIButton *)sender {
    NSString *logString = [NSString stringWithFormat:@"CP_userInputParamButtonTouchUp tag:%d", sender.tag];
    [RemoteLog logAction:logString identifier:sender];
    
    for (UIButton *button in self.allUserInputParamButtons) {
        if (![button isEqual:sender]) {
            button.selected = false;
        }
    }
    sender.selected = !sender.selected;
    //    DebugLog(@"sender.selected %i", sender.selected);
    
    NSString *userInputParamKey = nil;
    CGFloat minValue = 0;
    CGFloat maxValue = 1;
    if ([sender isEqual:self.cylinderDiameterButton]) {
        userInputParamKey = @"userInputParams.cylinderDiameter";
        minValue = 0.01;
        maxValue = 0.2;
    }
    else if ([sender isEqual:self.cylinderHeightButton]) {
        userInputParamKey = @"userInputParams.cylinderHeight";
        minValue = 0.01;
        maxValue = 0.5;
    }
    else if ([sender isEqual:self.imageWidthButton]) {
        userInputParamKey = @"userInputParams.imageWidth";
        minValue = 0.01;
        maxValue = 0.2;
    }
    else if ([sender isEqual:self.imageHeightButton]) {
        userInputParamKey = @"userInputParams.imageCenterOnSurfHeight";
        minValue = 0.01;
        maxValue = 0.25;
    }
//    else if ([sender isEqual:self.eyeDistanceButton]) {
//        userInputParamKey = @"userInputParams.eyeHonrizontalDistance";
//        minValue = 0.35;
//        maxValue = 1.75;
//    }
//    else if ([sender isEqual:self.eyeHeightButton]) {
//        userInputParamKey = @"userInputParams.eyeVerticalHeight";
//        minValue = 0.4;
//        maxValue = 2.0;
//    }
    else if ([sender isEqual:self.eyeZoomButton]) {
        userInputParamKey = @"userInputParams.eyeZoom";
        minValue = 0.1;
        maxValue = 2;
    }
    else if ([sender isEqual:self.projectZoomButton]) {
        userInputParamKey = @"userInputParams.unitZoom";
        minValue = 0.1;
        maxValue = 2;
    }
    
    if (sender.selected) {
        [self openUserInputParamValueSlider:userInputParamKey minValue:minValue maxValue:maxValue];
    }
    else{
        [self closeUserInputParamValueSlider];
    }
    
    //在确定排版之后确定教程
    [self tutorialStepNextImmediate:true];

}

- (IBAction)userInputParamSliderValueChanged:(UISlider *)sender {
    [RemoteLog logAction:@"CP_userInputParamSliderValueChanged" identifier:sender];

    [self setValue:[NSNumber numberWithFloat:sender.value] forKeyPath:self.userInputParamkeyPath];
    
    //更新paintDoc的userInputParams
//    [ADPaintFrameManager curGroup].curPaintDoc.userInputParams = [self.userInputParams copy];
    
//    ADCylinderProjectUserInputParams *param = [ADPaintFrameManager curGroup].curPaintDoc.userInputParams;
    
    [self flushUIUserInputParams];
}

- (IBAction)userInputParamSliderTouchUp:(UISlider *)sender {
    [RemoteLog logAction:@"CP_userInputParamSliderTouchUp" identifier:sender];
    [self tutorialStartCurrentStep];
    
    [self userInputParamSliderTouchEnd];
}

- (IBAction)userInputParamSliderTouchUpOutside:(UISlider *)sender {
    [RemoteLog logAction:@"CP_userInputParamSliderTouchUpOutside" identifier:sender];
    [self tutorialStartCurrentStep];
    
    [self userInputParamSliderTouchEnd];
}

- (IBAction)userInputParamSliderTouchCancel:(UISlider *)sender {
    [RemoteLog logAction:@"CP_userInputParamSliderTouchCancel" identifier:sender];
    [self tutorialStartCurrentStep];
    
    [self userInputParamSliderTouchEnd];
}

- (void)userInputParamSliderTouchEnd{
//    [[ADPaintFrameManager curGroup].curPaintDoc saveUserInputParams];
}
- (IBAction)userInputParamSliderTouchDown:(UISlider *)sender {
    [RemoteLog logAction:@"CP_userInputParamSliderTouchDown" identifier:sender];
    [self tutorialStepNextImmediate:false];
}

//载入paintDoc保存的inputParams
-(void)loadInputParams{
    self.userInputParamsSrc = [[ADPaintFrameManager curGroup].curPaintDoc openInfo];
    if (!self.userInputParamsSrc) {
        return;
    }
    
    [self animationToTarget:self.userInputParams params:self.userInputParamsSrc.propertyNameValueDic duration:CylinderResetParamDuration timing:REPropertyAnimationTimingEaseOut completionDelegate:self completionBlock:^{
        [self flushUIUserInputParams];
    }];
    
}

//重置到默认的inputParams
-(void)resetInputParams{
    [self animationToTarget:self.userInputParams params:self.userInputParamsBrowse.propertyNameValueDic duration:CylinderResetParamDuration timing:REPropertyAnimationTimingEaseOut completionDelegate:self completionBlock:^{
        for (UIButton *button in self.allUserInputParamButtons) {
            button.selected = false;
        }
        [self closeUserInputParamValueSlider];
        
        [self flushUIUserInputParams];
    }];
}

#pragma mark- 设置场景 Setup Scene
- (IBAction)setupCylinderButtonTouchUp:(UIButton *)sender {
    [RemoteLog logAction:@"CP_setupCylinderButtonTouchUp" identifier:sender];
    
    [self tutorialStepNextImmediate:false];
    
    [self setupCylinderSceneStart];
}

- (void)setupCylinderSceneStart{
    [self lockInteraction:true];
    
    //关闭按钮调整
    for (UIButton *button in self.allUserInputParamButtons) {
        button.selected = false;
    }
    [self closeUserInputParamValueSlider];

    [ADPaintUIKitAnimation view:self.rootView switchDownToolBarFromView:self.downToolBar completion:nil];
    
    [ADPaintUIKitAnimation view:self.rootView slideToolBarRightDirection:false outView:self.setupParamsView inView:self.setupSceneView completion:^{
        [self lockInteraction:false];
        
        [self tutorialStartCurrentStep];

    }];
}

- (void)setupCylinderSceneDone{
    
    [ADPaintUIKitAnimation view:self.rootView slideToolBarRightDirection:false outView:self.setupSceneView inView:self.setupParamsView completion:^{
        [self tutorialStartCurrentStep];
    }];
    
    [ADPaintUIKitAnimation view:self.rootView switchDownToolBarToView:self.downToolBar completion:nil];
}

- (IBAction)setupCylinderRefObjectButtonTouchUp:(UIButton *)sender {
    NSString *logString = [NSString stringWithFormat:@"CP_setupCylinderRefObjectButtonTouchUp tag:%d", sender.tag];
    [RemoteLog logAction:logString identifier:sender];
    
    ADCylinderProjectUserInputParams *params = nil;
    switch (sender.tag) {
        case 4://mac pro
            params = self.userInputParamsMacPro;
            break;
        case 3://tea cup
            params = self.userInputParamsTeaCup;
            break;
        case 2://drink can
            params = self.userInputParamsCan;

            break;
        case 1://pen
            params = self.userInputParamsPen;
            [self tutorialStepNextImmediate:false];
            
            break;
        case 5://base mirror
            params = self.userInputParamsNormal;
            break;
        default:
            break;
    }
    
    [self animationToTarget:self.userInputParams params:params.propertyNameValueDic duration:CylinderResetParamDuration timing:REPropertyAnimationTimingEaseOut completionDelegate:self completionBlock:^{
        //更新paintDoc的userInputParams
//        [ADPaintFrameManager curGroup].curPaintDoc.userInputParams = [self.userInputParams copy];

        [self flushUIUserInputParams];

//        [[ADPaintFrameManager curGroup].curPaintDoc saveUserInputParams];
    }];
    
    [self setupCylinderSceneDone];
}

- (IBAction)setupCylinderRefBackButtonTouchUp:(UIButton *)sender{
    [self setupCylinderSceneDone];
}
- (void)loadRefObjectUserInputParams{
    BOOL isDeviceMini = [ADDeviceHardware sharedInstance].isMini;
    
    //default for browse
    ADCylinderProjectUserInputParams *params = [[ADCylinderProjectUserInputParams alloc]init];

    if (isDeviceMini) {
        DeviceWidth = 0.12;
        params.cylinderDiameter = 0.03;
        params.cylinderHeight = 0.055;
        params.imageWidth = 0.03;
        params.imageCenterOnSurfHeight = 0.027;
        params.eyeHonrizontalDistance = 0.27;
        params.eyeVerticalHeight = 0.31;
        params.eyeTopZ = 0.01;
        params.eyeZoom = 1;
        params.unitZoom = 1;
    }
    else{
        DeviceWidth = 0.154;
        params.cylinderDiameter = 0.038;
        params.cylinderHeight = 0.07;
        params.imageWidth = 0.038;
        params.imageCenterOnSurfHeight = 0.035;
        params.eyeHonrizontalDistance = 0.35;
        params.eyeVerticalHeight = 0.4;
        params.eyeTopZ = 0.01;
        params.eyeZoom = 1;
        params.unitZoom = 1;
    }
    self.userInputParamsBrowse = params;
    

    //mac pro
    params = [[ADCylinderProjectUserInputParams alloc]init];
    params.cylinderDiameter = 0.168;
    params.cylinderHeight = 0.258;
    params.imageWidth = 0.16;
    params.imageCenterOnSurfHeight = 0.158;
    if (isDeviceMini) {
        params.eyeZoom = 0.21;
        params.unitZoom = 0.17;
    }
    else{
        params.eyeZoom = 0.27;
        params.unitZoom = 0.18;
    }
    self.userInputParamsMacPro = params;
    
    //tea cup
    params = [[ADCylinderProjectUserInputParams alloc]init];
    params.cylinderDiameter = 0.1;
    params.cylinderHeight = 0.14;
    params.imageWidth = 0.1;
    params.imageCenterOnSurfHeight = 0.08;
    if (isDeviceMini) {
        params.eyeZoom = 0.38;
        params.unitZoom = 0.3;
    }
    else{
        params.eyeZoom = 0.5;
        params.unitZoom = 0.3;
    }
    self.userInputParamsTeaCup = params;
    
    //drink can
    params = [[ADCylinderProjectUserInputParams alloc]init];
    params.cylinderDiameter = 0.066;
    params.cylinderHeight = 0.123;
    params.imageWidth = 0.066;
    params.imageCenterOnSurfHeight = 0.064;
    if (isDeviceMini) {
        params.eyeZoom = 0.53;
        params.unitZoom = 0.4;
    }
    else{
        params.eyeZoom = 0.7;
        params.unitZoom = 0.4;
    }
    self.userInputParamsCan = params;
    
    //pen
    params = [[ADCylinderProjectUserInputParams alloc]init];
    params.cylinderDiameter = 0.01;
    params.cylinderHeight = 0.12;
    params.imageWidth = 0.01;
    params.imageCenterOnSurfHeight = 0.03;
    if (isDeviceMini) {
        params.eyeZoom = 1;
        params.unitZoom = 1;
    }
    else{
        params.eyeZoom = 1;
        params.unitZoom = 1;
    }
    self.userInputParamsPen = params;
    
    //base mirror
    params = [[ADCylinderProjectUserInputParams alloc]init];
    params.cylinderDiameter = 0.038;
    params.cylinderHeight = 0.07;
    params.imageWidth = 0.038;
    params.imageCenterOnSurfHeight = 0.035;
    if (isDeviceMini) {
        params.eyeZoom = 1;
        params.unitZoom = 1;
    }
    else{
        params.eyeZoom = 1;
        params.unitZoom = 1;
    }
    self.userInputParamsNormal = params;
}
#pragma mark- 产品信息ProductInfo
- (void)productInfo{
    ADProductInfoTableViewController* productInfoTableViewController = [[ADProductInfoTableViewController alloc]initWithStyle:UITableViewStylePlain];
    productInfoTableViewController.delegate = self;
    //align to downtoolbar icon
    productInfoTableViewController.preferredContentSize = CGSizeMake(PopoverFrameWithIconAlignedWidth, productInfoTableViewController.tableViewHeight);
    
    self.sharedPopoverController = [[ADSharedPopoverController alloc]initWithContentViewController:productInfoTableViewController];
    self.sharedPopoverController.delegate = self;
    [self.sharedPopoverController presentPopoverFromRect:self.infoButton.bounds inView:self.infoButton permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

#pragma mark- 产品信息代理 info Delegate

- (void) willOpenWelcomGuideURL{
    [RemoteLog logAction:@"CP_willOpenWelcomGuideURL" identifier:nil];
    NSURL *url = [NSURL URLWithString:PRODUCT_INFO_INTRODUCTION];
    if([[UIApplication sharedApplication] canOpenURL:url]){
        [[UIApplication sharedApplication] openURL:url];
    }
}
- (void) willOpenUserManualURL{
    [RemoteLog logAction:@"CP_willOpenUserManualURL" identifier:nil];
    NSURL *url = [NSURL URLWithString:PRODUCT_INFO_USERMANUAL];
    if([[UIApplication sharedApplication] canOpenURL:url]){
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void) willOpenSupportURL{
    [RemoteLog logAction:@"CP_willOpenSupportURL" identifier:nil];
    NSURL *url = [NSURL URLWithString:PRODUCT_INFO_COMMUNITY];
    if([[UIApplication sharedApplication] canOpenURL:url]){
        [[UIApplication sharedApplication] openURL:url];
    }
}
- (void) willOpenGalleryURL{
    [RemoteLog logAction:@"CP_willOpenGalleryURL" identifier:nil];
    NSURL *url = [NSURL URLWithString:PRODUCT_INFO_GALLERY];
    if([[UIApplication sharedApplication] canOpenURL:url]){
        [[UIApplication sharedApplication] openURL:url];
    }
}

#if TESTFLIGHT
- (void) willOpenBetaTestFeedback{
    [self.sharedPopoverController dismissPopoverAnimated:true];
    self.infoButton.selected = false;
    [[Questionnaire sharedInstance] show];
}
#endif
- (void)willOpenTutorial{
    [RemoteLog logAction:@"CP_willOpenTutorial" identifier:nil];

    [self.sharedPopoverController dismissPopoverAnimated:true];
    self.infoButton.selected = false;
    AppDelegate *appDelegate = (AppDelegate *)([UIApplication sharedApplication].delegate);
    [appDelegate initTutorialManager];

    if (self.isSetupMode) {
        [self alvertSaveUserInputParamsWithCompletionBlock:^(BOOL confirm) {
            if (self.delegate) {
                [self.delegate willTransitionToTutorial];
            }
        }];
    }
    else{
        if (self.delegate) {
            [self.delegate willTransitionToTutorial];
        }
    }
}
#pragma mark- 内容CylinderProject View

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    
    if (context == &ItemStatusContext) {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self syncPlayUI];
                       });
        return;
    }

    if ([keyPath isEqualToString:@"userInputParams.cylinderDiameter"]) {
        if (self.cylinder) {
            self.cylinder.transform.scale = GLKVector3Make(self.userInputParams.cylinderDiameter, self.userInputParams.cylinderHeight, self.userInputParams.cylinderDiameter);
        }
        if (self.cylinderProjectCur) {
            self.cylinderProjectCur.radius = self.userInputParams.cylinderDiameter * 0.5;
        }
    }
    else if ([keyPath isEqualToString:@"userInputParams.cylinderHeight"]) {
        if (self.cylinder) {
            self.cylinder.transform.scale = GLKVector3Make(self.userInputParams.cylinderDiameter, self.userInputParams.cylinderHeight, self.userInputParams.cylinderDiameter);
        }
    }
    else if ([keyPath isEqualToString:@"userInputParams.imageWidth"]) {
        if (self.cylinderProjectCur) {
            self.cylinderProjectCur.imageWidth = self.userInputParams.imageWidth;
        }
    }
    else if ([keyPath isEqualToString:@"userInputParams.imageCenterOnSurfHeight"]) {
        if (self.cylinderProjectCur) {
            self.cylinderProjectCur.imageCenterOnSurfHeight = self.userInputParams.imageCenterOnSurfHeight;
        }
    }
//    else if ([keyPath isEqualToString:@"userInputParams.eyeHonrizontalDistance"] ||
//             [keyPath isEqualToString:@"userInputParams.eyeVerticalHeight"]) {
//
//        
//        GLKVector3 eyeBottom = GLKVector3Make(0, self.userInputParams.eyeVerticalHeight, -self.userInputParams.eyeHonrizontalDistance);
//        GLKVector3 eyeTop = GLKVector3Make(0, self.userInputParams.eyeHonrizontalDistance, -self.userInputParams.eyeTopZ);
//        self.topCamera.position = eyeTop;
//        RECamera.mainCamera.position = GLKVector3Lerp(eyeBottom, eyeTop, self.eyeBottomTopBlend);
//
//        
//        
//        if (self.cylinder) {
//            self.cylinder.reflectionTexUVSpace = GLKVector4Make(self.topCamera.focus.x - self.topCamera.orthoWidth * 0.5,
//                                                                self.topCamera.focus.y - self.topCamera.orthoHeight * 0.5 + self.topCamera.position.z,
//                                                                self.topCamera.orthoWidth,
//                                                                self.topCamera.orthoHeight);
//        }
//    }
    else if ([keyPath isEqualToString:@"userInputParams.eyeZoom"]){
        //更改输入参数
        float h = 0.4 - 0.035;
        float w = 0.35 - 0.038;
        GLKVector3 imageCenterOnSurf = GLKVector3Make(0, 0.035, - 0.038);
        if ([ADDeviceHardware sharedInstance].isMini) {
            h = 0.31 - 0.027;
            w = 0.27 - 0.03;
            imageCenterOnSurf = GLKVector3Make(0, 0.027, - 0.03);
        }
        
        GLKVector3 vImageCenterToEye = GLKVector3Make(0, h, -w);
        CGFloat dist = GLKVector3Length(vImageCenterToEye);
        GLKVector3 eyeZoomed = GLKVector3Add(GLKVector3MultiplyScalar(GLKVector3Normalize(vImageCenterToEye), dist / self.userInputParams.eyeZoom), imageCenterOnSurf);
        self.userInputParams.eyeHonrizontalDistance = -eyeZoomed.z;
        self.userInputParams.eyeVerticalHeight = eyeZoomed.y;

        //修改了eye position imageCenterOnSurfHeight radius中的任何一项, 都会导致vImageCenterToEye发生变化，导致image transformMatrix变化
        //更改Camera
        GLKVector3 eyeBottom = GLKVector3Make(0, self.userInputParams.eyeVerticalHeight, -self.userInputParams.eyeHonrizontalDistance);
        GLKVector3 eyeTop = GLKVector3Make(0, self.userInputParams.eyeHonrizontalDistance, -self.userInputParams.eyeTopZ);
        self.topCamera.position = eyeTop;
        self.topCamera.focus = GLKVector3Make(0, 0, -self.userInputParams.eyeTopZ);
        
        RECamera.mainCamera.position = GLKVector3Lerp(eyeBottom, eyeTop, self.eyeBottomTopBlend);
        
        //更改Cylinder
        if (self.cylinder) {
            self.cylinder.reflectionTexUVSpace = GLKVector4Make(self.topCamera.focus.x - self.topCamera.orthoWidth * 0.5,
                                                                self.topCamera.focus.z - self.topCamera.orthoHeight * 0.5,
                                                                self.topCamera.orthoWidth,
                                                                self.topCamera.orthoHeight);
        }
        
        if (self.cylinderProjectCur) {
            self.cylinderProjectCur.eye = eyeBottom;
        }
        if (self.cylinder) {
            self.cylinder.eye = eyeBottom;
        }
    }
    else if ([keyPath isEqualToString:@"userInputParams.unitZoom"]) {
        if (self.topCamera) {
            self.topCamera.orthoWidth = DeviceWidth / self.userInputParams.unitZoom;
            self.topCamera.orthoHeight = (DeviceWidth / self.eyeTopAspect) / self.userInputParams.unitZoom;
            [self.topCamera updateProjMatrix];
            
            if (self.cylinder) {
                self.cylinder.reflectionTexUVSpace = GLKVector4Make(self.topCamera.focus.x - self.topCamera.orthoWidth * 0.5,
                                                                    self.topCamera.focus.z - self.topCamera.orthoHeight * 0.5,
                                                                    self.topCamera.orthoWidth,
                                                                    self.topCamera.orthoHeight);
            }

        }
    }
    else{
//        [super observeValueForKeyPath:keyPath
//                             ofObject:object
//                               change:change
//                              context:context];
    }
    
    return;
}



- (void)setupBaseParams{
    DebugLogFuncStart(@"setupBaseParams");
    //顶视图视口比例
    self.eyeTopAspect = fabsf(self.projectView.bounds.size.width / (self.projectView.bounds.size.height + ToSeeCylinderTopPixelOffset));
    
    [self addObserver:self forKeyPath:@"eyeTop" options:NSKeyValueObservingOptionOld context:nil];
}
- (void)destroyBaseParams{
    [self removeObserver:self forKeyPath:@"eyeTop"];
}

- (void)setupInputParams{
    DebugLogFuncStart(@"setupInputParams");
    if (!self.userInputParams) {
        self.userInputParams = [self.userInputParamsBrowse copy];
//        self.userInputParams = [[ADCylinderProjectUserInputParams alloc]init];
//        NSEnumerator *enumeratorKey = [self.userInputParamsBrowse.propertyNameValueDic keyEnumerator];
//        for (NSObject *key in enumeratorKey) {
//            NSNumber *num = [self.userInputParamsBrowse.propertyNameValueDic objectForKey:key];
//            [self.userInputParams setValue:num forKeyPath:(NSString*)key];
//        }
    }
    
    [self addObserver:self forKeyPath:@"userInputParams.cylinderDiameter" options:NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"userInputParams.cylinderHeight" options:NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"userInputParams.imageWidth" options:NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"userInputParams.imageCenterOnSurfHeight" options:NSKeyValueObservingOptionOld context:nil];
//    [self addObserver:self forKeyPath:@"userInputParams.eyeHonrizontalDistance" options:NSKeyValueObservingOptionOld context:nil];
//    [self addObserver:self forKeyPath:@"userInputParams.eyeVerticalHeight" options:NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"userInputParams.eyeZoom" options:NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"userInputParams.unitZoom" options:NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"userInputParams.eyeTopZ" options:NSKeyValueObservingOptionOld context:nil];

    //setup panel
    [self flushUIUserInputParams];
}
- (void)destroyInputParams{
    [self removeObserver:self forKeyPath:@"userInputParams.cylinderDiameter"];
    [self removeObserver:self forKeyPath:@"userInputParams.cylinderHeight"];
    [self removeObserver:self forKeyPath:@"userInputParams.imageWidth"];
    [self removeObserver:self forKeyPath:@"userInputParams.imageCenterOnSurfHeight"];
//    [self removeObserver:self forKeyPath:@"userInputParams.eyeHonrizontalDistance"];
//    [self removeObserver:self forKeyPath:@"userInputParams.eyeVerticalHeight"];
    [self removeObserver:self forKeyPath:@"userInputParams.eyeZoom"];
    [self removeObserver:self forKeyPath:@"userInputParams.unitZoom"];
    [self removeObserver:self forKeyPath:@"userInputParams.eyeTopZ"];
}

-(void)flushUIUserInputParams{
    [self.cylinderDiameterButton setTitle:[NSString unitStringFromFloat:self.userInputParams.cylinderDiameter] forState:UIControlStateNormal];
    [self.cylinderDiameterButton setTitle:[NSString unitStringFromFloat:self.userInputParams.cylinderDiameter] forState:UIControlStateSelected];
    
    [self.cylinderHeightButton setTitle:[NSString unitStringFromFloat:self.userInputParams.cylinderHeight] forState:UIControlStateNormal];
    [self.cylinderHeightButton setTitle:[NSString unitStringFromFloat:self.userInputParams.cylinderHeight] forState:UIControlStateSelected];

    [self.imageWidthButton setTitle:[NSString unitStringFromFloat:self.userInputParams.imageWidth] forState:UIControlStateNormal];
    [self.imageWidthButton setTitle:[NSString unitStringFromFloat:self.userInputParams.imageWidth] forState:UIControlStateSelected];
    
    [self.imageHeightButton setTitle:[NSString unitStringFromFloat:self.userInputParams.imageCenterOnSurfHeight] forState:UIControlStateNormal];
    [self.imageHeightButton setTitle:[NSString unitStringFromFloat:self.userInputParams.imageCenterOnSurfHeight] forState:UIControlStateSelected];
    
    [self.eyeDepthButton setTitle:[NSString unitStringFromFloat:self.userInputParams.eyeHonrizontalDistance] forState:UIControlStateNormal];
    [self.eyeDepthButton setTitle:[NSString unitStringFromFloat:self.userInputParams.eyeHonrizontalDistance] forState:UIControlStateSelected];
    
    [self.eyeHeightButton setTitle:[NSString unitStringFromFloat:self.userInputParams.eyeVerticalHeight] forState:UIControlStateNormal];
    [self.eyeHeightButton setTitle:[NSString unitStringFromFloat:self.userInputParams.eyeVerticalHeight] forState:UIControlStateSelected];

    [self.eyeZoomButton setTitle:[NSString stringWithFormat:@"%.0f%%", self.userInputParams.eyeZoom * 100] forState:UIControlStateNormal];
    [self.eyeZoomButton setTitle:[NSString stringWithFormat:@"%.0f%%", self.userInputParams.eyeZoom * 100] forState:UIControlStateSelected];
    
    [self.projectZoomButton setTitle:[NSString stringWithFormat:@"%.0f%%", self.userInputParams.unitZoom * 100] forState:UIControlStateNormal];
    [self.projectZoomButton setTitle:[NSString stringWithFormat:@"%.0f%%", self.userInputParams.unitZoom * 100] forState:UIControlStateSelected];
    
    [self.projectWidthButton setTitle:[NSString unitStringFromFloat:DeviceWidth / self.userInputParams.unitZoom] forState:UIControlStateNormal];
    [self.projectWidthButton setTitle:[NSString unitStringFromFloat:DeviceWidth / self.userInputParams.unitZoom] forState:UIControlStateSelected];
    
    [self.projectHeightButton setTitle:[NSString unitStringFromFloat:(DeviceWidth / self.eyeTopAspect) / self.userInputParams.unitZoom] forState:UIControlStateNormal];
    [self.projectHeightButton setTitle:[NSString unitStringFromFloat:(DeviceWidth / self.eyeTopAspect) / self.userInputParams.unitZoom] forState:UIControlStateSelected];
}

-(void)destroySceneCameras{
    DebugLogFuncStart(@"destroySceneCameras");
    [RECamera.mainCamera destroy];
    RECamera.mainCamera = nil;
    RECamera.current = nil;
    
    [self.topCamera destroy];
    self.topCamera = nil;
}
-(void)initSceneCameras{
    DebugLogFuncStart(@"initSceneCameras");
    //eyeBottom should be output of userInputParams
    
    RECamera.mainCamera.name = @"mainCamera";
    RECamera.mainCamera.position = GLKVector3Make(0, self.userInputParams.eyeVerticalHeight, -self.userInputParams.eyeHonrizontalDistance);
    RECamera.mainCamera.focus = GLKVector3Make(0, 0, -self.userInputParams.eyeTopZ);
    
    //如果中心点反向，则up向量反向
    if (RECamera.mainCamera.focus.z >= 0) {
        RECamera.mainCamera.up = GLKVector3Make(0, 0, -1);
    }
    else{
        RECamera.mainCamera.up = GLKVector3Make(0, 0, 1);
    }
    RECamera.mainCamera.nearClip = NearClipDistance;
    RECamera.mainCamera.farClip = FarClipDistance;
    RECamera.mainCamera.aspect = self.eyeTopAspect;
    RECamera.mainCamera.fov = GLKMathDegreesToRadians(29);
    RECamera.mainCamera.backgroundColor = GLKVector4Make(0/255.0, 0/255.0, 0/255.0, 0);
    RECamera.mainCamera.cullingMask = Culling_Everything & (~Culling_CylinderImage);
    self.bottomCameraProjMatrix = RECamera.mainCamera.projMatrix;
    
    float orthoWidth = DeviceWidth / self.userInputParams.unitZoom;
    float orthoHeight = (DeviceWidth / self.eyeTopAspect) / self.userInputParams.unitZoom;
    
    self.topCamera = [[RECamera alloc]initOrthorWithPosition:GLKVector3Make(0, self.userInputParams.eyeHonrizontalDistance, -self.userInputParams.eyeTopZ)
                                                     focus:GLKVector3Make(0, 0, -self.userInputParams.eyeTopZ)
                                                        up:GLKVector3Make(0, 0, 1)
                                                orthoWidth:orthoWidth
                                               orthoHeight:orthoHeight
                                                  nearClip:NearClipDistance
                                                   farClip:FarClipDistance];
    
    self.topCamera.name = @"topCamera";
    RERenderTexture *renderTex = [RERenderTexture textureWithName:@"topCameraTex" width:1024 height:1024 mipmap:Interpolation_Linear wrapMode:WrapMode_Clamp];
    self.topCamera.targetTexture = renderTex;
    self.topCamera.cullingMask = Culling_Reflection;
    
    //add camera by rendering sequence
    [self.curScene addCamera:self.topCamera];
    [self.curScene addCamera:RECamera.mainCamera];
    
    if (!self.isReversePaint) {
        self.eyeBottomTopBlend = 0.0;
    }
    
//    else{
//        self.eyeBottomTopBlend = 1.0;
//    }
    
    REPropertyAnimation *topToBottomPropAnim = [REPropertyAnimation propertyAnimationWithKeyPath:@"eyeBottomTopBlend"];
    topToBottomPropAnim.delegate = self;
    topToBottomPropAnim.fromValue = [NSNumber numberWithFloat:1];
    topToBottomPropAnim.toValue = [NSNumber numberWithFloat:0];
    topToBottomPropAnim.duration = CylinderViewChangeDuration;
    topToBottomPropAnim.timing = REPropertyAnimationTimingEaseOut;
    [topToBottomPropAnim setCompletionBlock:^{
        
        [self lockInteraction:false];

        [self tutorialStartCurrentStep];
    }];
    REAnimationClip *animClip = [REAnimationClip animationClipWithPropertyAnimation:topToBottomPropAnim];
    animClip.name = @"topToBottomAnimClip";
    RECamera.mainCamera.animation = [REAnimation animationWithAnimClip:animClip];
    
    REPropertyAnimation *bottomToTopPropAnim = [REPropertyAnimation propertyAnimationWithKeyPath:@"eyeBottomTopBlend"];
    bottomToTopPropAnim.delegate = self;
    bottomToTopPropAnim.fromValue = [NSNumber numberWithFloat:0];
    bottomToTopPropAnim.toValue = [NSNumber numberWithFloat:1];
    bottomToTopPropAnim.duration = CylinderViewChangeDuration;
    bottomToTopPropAnim.timing = REPropertyAnimationTimingEaseOut;
    [bottomToTopPropAnim setCompletionBlock:^{
        
        [self lockInteraction:false];

        [self tutorialStartCurrentStep];
    }];
    animClip = [REAnimationClip animationClipWithPropertyAnimation:bottomToTopPropAnim];
    animClip.name = @"bottomToTopAnimClip";
    [RECamera.mainCamera.animation addClip:animClip];
}

- (void)createCylinderBackup{
    
}

- (void)createCylinder{
    //create cylinder
    
    ADShaderCylinder *shaderCylinder = (ADShaderCylinder *)[[REGLWrapper current]createShader:@"ADShaderCylinder"];
    REMaterial *matMain = [[REMaterial alloc]initWithShader:shaderCylinder];
    RETexture *texMain = [[RETexture alloc]init];
    texMain.texID = [RETextureManager textureInfoFromImageName:@"cylinderMain.png" reload:false].name;
    matMain.mainTexture = texMain;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Models/cylinder" ofType:@"obj"];
    ADCylinder *cylinder = (ADCylinder *)[REAssetDatabase LoadAssetAtPath:path ofType:[ADCylinder class]];
    

    cylinder.name = @"cylinder";
    cylinder.renderer.sharedMaterial = matMain;
    cylinder.layerMask = Layer_Default;
    cylinder.eye = RECamera.mainCamera.position;
    cylinder.reflectionTex = self.topCamera.targetTexture;
    cylinder.transform.scale = GLKVector3Make(self.userInputParams.cylinderDiameter, self.userInputParams.cylinderHeight, self.userInputParams.cylinderDiameter);
    cylinder.reflectionTexUVSpace = GLKVector4Make(self.topCamera.focus.x - self.topCamera.orthoWidth * 0.5,
                                                   self.topCamera.focus.z - self.topCamera.orthoHeight * 0.5,
                                                   self.topCamera.orthoWidth,
                                                   self.topCamera.orthoHeight);
    
    REPropertyAnimation *propAnim = [REPropertyAnimation propertyAnimationWithKeyPath:@"reflectionStrength"];
    propAnim.delegate = self;
    propAnim.timing = REPropertyAnimationTimingEaseInEaseOut;
    propAnim.target = cylinder;
    REAnimationClip *animClip = [REAnimationClip animationClipWithPropertyAnimation:propAnim];
    animClip.name = @"reflectionFadeInOutAnimClip";
    REAnimation *anim = [REAnimation animationWithAnimClip:animClip];
    cylinder.animation = anim;
    self.cylinder = cylinder;
    [self.curScene addEntity:cylinder];
    

    [self createCylinderTopLight];
    [self createCylinderBottom];
    [self createCylinderInterLight];
    
    //debug
//    cylinder.active = false;
}

- (void)destroyCylinder{
    [self.curScene removeEntity:self.cylinder];
    self.cylinder = nil;

    [self destroyCylinderInterLight];
    [self destroyCylinderTopLight];
    [self destroyCylinderBottom];
}

- (void)createCylinderTopLight{
    //加入圆柱体的顶部光效
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Models/cylinderTopLight" ofType:@"obj"];
    REModelEntity *cylinderTopLight = [REAssetDatabase LoadAssetAtPath:path ofType:[REModelEntity class]];
    cylinderTopLight.transform.parent = self.cylinder.transform;
    
    ADShaderUnlitTransparentAdditive *shader = (ADShaderUnlitTransparentAdditive *)[[REGLWrapper current]createShader:@"ADShaderUnlitTransparentAdditive"];
    REMaterial *mat = [[REMaterial alloc]initWithShader:shader];
    mat.transparent = true;
    RETexture *texMain = [[RETexture alloc]init];
    texMain.texID = [RETextureManager textureInfoFromImageName:@"cylinderTopLight.png" reload:false].name;
    mat.mainTexture = texMain;
    cylinderTopLight.renderer.material = mat;
    
    REPropertyAnimation *propAnim = [REPropertyAnimation propertyAnimationWithKeyPath:@"transform.eulerAngles.y"];
    propAnim.delegate = self;
    propAnim.timing = REPropertyAnimationTimingLinear | REPropertyAnimationOptionRepeat;
    propAnim.fromValue = [NSNumber numberWithFloat:0];
    propAnim.toValue = [NSNumber numberWithFloat:360];
    propAnim.duration = 5;
    propAnim.target = cylinderTopLight;
    REAnimationClip *animClip = [REAnimationClip animationClipWithPropertyAnimation:propAnim];
    animClip.name = @"cylinderTopLightRotation";
    REAnimation *anim = [REAnimation animationWithAnimClip:animClip];
    cylinderTopLight.animation = anim;
    [cylinderTopLight.animation play];
    self.cylinderTopLight = cylinderTopLight;
    [self.curScene addEntity:cylinderTopLight];
    
}

- (void)destroyCylinderTopLight{
    REPropertyAnimation* propAnim = (REPropertyAnimation*)(self.cylinderTopLight.animation.clip.propertyAnimations[0]);
    [propAnim cancel];
    [self.curScene removeEntity:self.cylinderTopLight];
    self.cylinderTopLight = nil;
}

- (void)createCylinderBottom{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Models/cylinderBottom" ofType:@"obj"];
    REModelEntity *cylinderBottom = [REAssetDatabase LoadAssetAtPath:path ofType:[REModelEntity class]];
    cylinderBottom.transform.parent = self.cylinder.transform;
    ADShaderNoLitTexture *shader = (ADShaderNoLitTexture *)[[REGLWrapper current]createShader:@"ADShaderNoLitTexture"];
    REMaterial *mat = [[REMaterial alloc]initWithShader:shader];
    RETexture *texMain = [[RETexture alloc]init];
    texMain.texID = [RETextureManager textureInfoFromImageName:@"cylinderBottom.png" reload:false].name;
    mat.mainTexture = texMain;
    cylinderBottom.renderer.material = mat;
    self.cylinderBottom = cylinderBottom;
    [self.curScene addEntity:cylinderBottom];
}

- (void)destroyCylinderBottom{
    [self.curScene removeEntity:self.cylinderBottom];
    self.cylinderBottom = nil;
}

- (void)createCylinderInterLight{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Models/cylinderInterLight" ofType:@"obj"];
    REModelEntity *cylinderInterLight = [REAssetDatabase LoadAssetAtPath:path ofType:[REModelEntity class]];
    cylinderInterLight.transform.parent = self.cylinder.transform;
    ADShaderUnlitTransparentAdditive *shader = (ADShaderUnlitTransparentAdditive *)[[REGLWrapper current]createShader:@"ADShaderUnlitTransparentAdditive"];
    REMaterial *mat = [[REMaterial alloc]initWithShader:shader];
    RETexture *texMain = [[RETexture alloc]init];
    texMain.texID = [RETextureManager textureInfoFromImageName:@"cylinderInterLight.png" reload:false].name;
    mat.mainTexture = texMain;
    cylinderInterLight.renderer.material = mat;
    
    REPropertyAnimation *propAnim = [REPropertyAnimation propertyAnimationWithKeyPath:@"transform.eulerAngles.y"];
    propAnim.delegate = self;
    propAnim.timing = REPropertyAnimationTimingLinear | REPropertyAnimationOptionRepeat;
    propAnim.fromValue = [NSNumber numberWithFloat:0];
    propAnim.toValue = [NSNumber numberWithFloat:360];
    propAnim.duration = 5;
    propAnim.target = cylinderInterLight;
    REAnimationClip *animClip = [REAnimationClip animationClipWithPropertyAnimation:propAnim];
    animClip.name = @"cylinderInterLightRotation";
    REAnimation *anim = [REAnimation animationWithAnimClip:animClip];
    cylinderInterLight.animation = anim;
    [cylinderInterLight.animation play];
    self.cylinderInterLight = cylinderInterLight;
    [self.curScene addEntity:cylinderInterLight];
}

- (void)destroyCylinderInterLight{
    REPropertyAnimation* propAnim = (REPropertyAnimation*)(self.cylinderInterLight.animation.clip.propertyAnimations[0]);
    [propAnim cancel];
    [self.curScene removeEntity:self.cylinderInterLight];
    self.cylinderInterLight = nil;
}
- (ADCylinderProject *)createCylinderProjectShadow{
    ADCylinderProject *cylinderProjectShadow = [self createCylinderProjectWithRow:25 Column:25];
    //修改Transform
    cylinderProjectShadow.floorOffset = GLKVector3Make(0, -0.005, 0);
    //修改Material
    cylinderProjectShadow.layerMask = Layer_Default;

    cylinderProjectShadow.renderer.material.transparent = true;
    cylinderProjectShadow.renderer.material.mainTexture = [RETexture textureFromImageName:@"cylinderProjectShadow.png" reload:false];
    
    [self.curScene addEntity:cylinderProjectShadow];
    return cylinderProjectShadow;
}

- (ADCylinderProject *)createCylinderProjectWithRow:(NSInteger)row Column:(NSInteger)column{
    
    ADShaderCylinderProject *shaderCylinderProject = (ADShaderCylinderProject *)[[REGLWrapper current]createShader:@"ADShaderCylinderProject"];
    REMaterial *matCylinderProject = [[REMaterial alloc]initWithShader:shaderCylinderProject];
//    matCylinderProject.faceMode = RE_DoubleFace;
    
    NSString *path = [[ADUltility applicationDocumentDirectory] stringByAppendingPathComponent:[[ADPaintFrameManager curGroup] curPaintDoc].thumbImagePath];
    matCylinderProject.mainTexture = [RETexture textureFromImagePath:path reload:true];
    ADPlaneMesh *planeMesh = [[ADPlaneMesh alloc]initWithRow:row column:column];
    [planeMesh create];
    REMeshFilter *meshFilter = [[REMeshFilter alloc]initWithMesh:planeMesh];
    REMeshRenderer *meshRenderer = [[REMeshRenderer alloc]initWithMeshFilter:meshFilter];
    meshRenderer.sharedMaterial = matCylinderProject;
    
    ADCylinderProject *cylinderProject = [[ADCylinderProject alloc]init];
    cylinderProject.name = @"cylinderProject";
    cylinderProject.renderer = meshRenderer;
    cylinderProject.radius = self.userInputParams.cylinderDiameter * 0.5;
    cylinderProject.eye = RECamera.mainCamera.position;
    cylinderProject.imageWidth = self.userInputParams.imageWidth;
    cylinderProject.imageCenterOnSurfHeight = self.userInputParams.imageCenterOnSurfHeight;
    cylinderProject.imageRatio = self.rootView.bounds.size.height / self.rootView.bounds.size.width;
    cylinderProject.layerMask = Layer_Reflection;
//    DebugLog(@"cylinderProjectDefaultAlphaBlend %.1f", self.cylinderProjectDefaultAlphaBlend);
    cylinderProject.alphaBlend = self.cylinderProjectDefaultAlphaBlend;
    self.cylinderProjectDefaultAlphaBlend = 1;
    
//animation
    REPropertyAnimation *fadeInPropAnim = [REPropertyAnimation propertyAnimationWithKeyPath:@"alphaBlend"];
    fadeInPropAnim.delegate = self;
    fadeInPropAnim.toValue = [NSNumber numberWithFloat:1];
    fadeInPropAnim.fromValue = [NSNumber numberWithFloat:0];
    fadeInPropAnim.duration = CylinderFadeInOutDuration;
    fadeInPropAnim.timing = REPropertyAnimationTimingEaseOut;

    REAnimationClip *fadeInAnimClip = [REAnimationClip animationClipWithPropertyAnimation:fadeInPropAnim];
    fadeInAnimClip.name = @"fadeInAnimClip";
    REAnimation *anim = [REAnimation animationWithAnimClip:fadeInAnimClip];
    cylinderProject.animation = anim;
    
    
    REPropertyAnimation *fadeOutPropAnim = [REPropertyAnimation propertyAnimationWithKeyPath:@"alphaBlend"];
    fadeOutPropAnim.delegate = self;
    fadeOutPropAnim.toValue = [NSNumber numberWithFloat:0];
    fadeOutPropAnim.fromValue = [NSNumber numberWithFloat:1];
    fadeOutPropAnim.duration = CylinderFadeInOutDuration;
    fadeOutPropAnim.timing = REPropertyAnimationTimingEaseOut;
    [fadeOutPropAnim setCompletionBlock:^{
        [self.delegate willTransitionToGallery];
    }];
    REAnimationClip *fadeOutAnimClip = [REAnimationClip animationClipWithPropertyAnimation:fadeOutPropAnim];
    fadeOutAnimClip.name = @"fadeOutAnimClip";
    [anim addClip:fadeOutAnimClip];
    
    
    REPropertyAnimation *browsePropAnim = [REPropertyAnimation propertyAnimationWithKeyPath:@"transform.translate.x"];
    browsePropAnim.name = @"browseAnimClipKeyPathTx";
    browsePropAnim.delegate = self;
    browsePropAnim.timing = REPropertyAnimationTimingEaseOut;
    REAnimationClip *browseAnimClip = [REAnimationClip animationClipWithPropertyAnimation:browsePropAnim];
    browseAnimClip.name = @"browseAnimClip";
    [anim addClip:browseAnimClip];
  
//add to scene
    meshRenderer.delegate = cylinderProject;
//    self.cylinderProjectCur = cylinderProject;
    
    [self.curScene addEntity:cylinderProject];
    
    return cylinderProject;
}
- (void)destroyCylinderProject{
    [self.curScene removeEntity:self.cylinderProjectCur];
    self.cylinderProjectCur = nil;
}

- (void)createTestObj{
//    CylinderMesh *mesh = [[CylinderMesh alloc]initWithRadius:0.5 sides:60 height:1];
//    [mesh create];
//    MeshFilter *meshFilter = [[MeshFilter alloc]initWithMesh:mesh];
//    MeshRenderer *meshRenderer = [[MeshRenderer alloc]initWithMeshFilter:meshFilter];
//    meshRenderer.sharedMaterial = matMain;
//    
//    //cap
//    BaseEffect *effect = [[BaseEffect alloc]init];
//    ShaderNoLitTexture *shaderNoLitTex = [[ShaderNoLitTexture alloc]init];
//    Material *matCap = [[Material alloc]initWithShader:shaderNoLitTex];
//    Texture *texCap = [[Texture alloc]init];
//    texCap.texID = [TextureManager textureInfoFromImageName:@"cylinderCap.png" reload:false].name;
//    matCap.mainTexture = texCap;
//    [meshRenderer.sharedMaterials addObject:matCap];
//    Cylinder *cylinder = [[Cylinder alloc]init];
//    cylinder.renderer = meshRenderer;

}

- (void)setupScene {
    DebugLogFuncStart(@"setupScene");
    REScene *scene = [[REScene alloc]init];
    self.curScene = scene;
    
    [self initSceneCameras];
    
    DebugLog(@"init Scene Entities ");
    self.cylinderProjectCur = [self createCylinderProjectWithRow:25 Column:1600];
    
    [self createCylinder];
    
    [self initOtherParams];
    
    [self.curScene flushAll];
    DebugLog(@"init Scene finished");
    
    [self updateRenderViewParams];
}

- (void)destroyScene{
    DebugLogFuncStart(@"destroyScene");
    [self.curScene destroy];
    self.curScene = nil;
    
    [self destroySceneCameras];
    
    [self destroyCylinderProject];
    
    [self destroyCylinder];

}
-(void)initOtherParams{

}

#pragma mark- 更换虚拟设备显示VirtualDevice
- (void)fitBrightness{
    self.baseBrightness = [UIScreen mainScreen].brightness;
    [self fullBrightness:nil];
}

- (void)restoreBrightness{
    [self toBaseBrightness:nil];
}

- (void)fullBrightness:(id)sender{
    if ([UIScreen mainScreen].brightness < 1) {
        [UIScreen mainScreen].brightness += 0.016;
        [self performSelector:@selector(fullBrightness:) withObject:nil afterDelay:0.016];
    }
}

- (void)toBaseBrightness:(id)sender{
    if ([UIScreen mainScreen].brightness > self.baseBrightness) {
        [UIScreen mainScreen].brightness -= 0.016;
        [self performSelector:@selector(toBaseBrightness:) withObject:nil afterDelay:0.016];
    }
}

- (void)openVirtualDevice{
    
}

- (void)closeVirtualDevice{
    
}

#pragma mark- 操作主屏幕CylinderProject View
- (void)rotateViewInAxisX:(float)percent{
    self.eyeBottomTopBlend = MIN(1, MAX(0, self.toEyeBottomTopBlend + percent));
}

#if DEBUG
- (CGFloat)getPercent:(UIPanGestureRecognizer *)sender{
    CGPoint center = self.rootView.center;
    CGPoint touchPoint =  [sender locationInView:self.rootView];
    GLKVector2 touchDirection = GLKVector2Make(touchPoint.x - center.x, touchPoint.y - center.y);
    touchDirection = GLKVector2Normalize(touchDirection);
    
    //    float dir = touchDirection.x - self.touchDirectionBegin.x;
    //    DebugLog(@"dir %.2f", dir);
    
    CGFloat angle = acosf(GLKVector2DotProduct(touchDirection, self.touchDirectionBegin));
    //移动速度过快情况下，会造成无法得到angle=0的情况
    
    CGFloat percent = MAX(0, MIN(angle / (M_PI) , 1));
    
    return percent;
}
#else
- (CGFloat)getPercent:(UIPanGestureRecognizer *)sender{
    CGPoint translation = [sender translationInView:sender.view];
    CGFloat fullTranslation = DefaultScreenWidth * 0.5;
    float percent = fabsf(translation.x) / fullTranslation;
    percent = MAX(0, MIN(percent, 1));
    return percent;
}
#endif

- (IBAction)handlePanCylinderProjectView:(UIPanGestureRecognizer *)sender {
    [RemoteLog logAction:@"CP_handlePanCylinderProjectView" identifier:sender];
    
    //顶视图模式下忽略圆柱体区域的触摸手势
    if (!self.eyePerspectiveView.hidden) {
        //ignoreCylinderRectTouch
        CGPoint location = [sender locationInView:sender.view];
        CGRect cylinderTopRect = [self getCylinderMirrorTopFrame];
        if(CGRectContainsPoint(cylinderTopRect, location)){
            return;
        }
    }
    
    CGPoint touchPoint = CGPointZero;
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:{
            [self lockButtonInteraction:true];
            touchPoint = [sender locationInView:self.rootView];
            //根据区域判断
//            if ( touchPoint.y < rootView.bounds.size.height * 0.5) {
//                sender.state = UIGestureRecognizerStateFailed;
//                return;
//            }
            self.touchDirectionBegin = GLKVector2Make(touchPoint.x - self.rootView.center.x, touchPoint.y - self.rootView.center.y);
            self.touchDirectionBegin = GLKVector2Normalize(self.touchDirectionBegin);
        }
            break;
        case UIGestureRecognizerStateChanged:{
            CGPoint translation = [sender translationInView:sender.view];
            CGFloat percent = 0.0;
            if (translation.x > 0){
                if (self.browseNextAction.interactionEnable) {
                    [self.browseNextAction updateInteractiveTransition:0];
                }
                if (self.browseLastAction.interactionEnable) {
//                    DebugLog(@"browse last");
                    //FIXME:保证pecent能走到％0
                    percent = [self getPercent:sender];
                    [self.browseLastAction updateInteractiveTransition:percent];
                }
 
            }
            else if(translation.x < 0){
                if (self.browseLastAction.interactionEnable) {
                    [self.browseLastAction updateInteractiveTransition:0];
                }
                if (self.browseNextAction.interactionEnable) {
                    //                    DebugLog(@"browse next");
                    //FIXME:保证pecent能走到％0
                    percent = [self getPercent:sender];
                    [self.browseNextAction updateInteractiveTransition:percent];
                }
            }
        }
            break;
        case UIGestureRecognizerStateEnded:{
            [self lockButtonInteraction:false];
            CGFloat percent;
            CGPoint translation = [sender translationInView:sender.view];
            if (translation.x > 0) {
//                DebugLog(@"end browse last");
                percent = [self getPercent:sender];
                if (percent > self.browseLastAction.completeThresold) {
                    if ([[ADPaintFrameManager curGroup] lastPaintDoc]) {
                        [self.browseLastAction finishInteractiveTransition];
                    }
                    else{
                        [self.browseLastAction cancelInteractiveTransition];
                    }
                }
                else{
                    [self.browseLastAction cancelInteractiveTransition];
                }
            }
            else if (translation.x < 0) {
//                DebugLog(@"end browse next");
                percent = [self getPercent:sender];
                if (percent > self.browseNextAction.completeThresold) {
                    if ([[ADPaintFrameManager curGroup] nextPaintDoc]) {
                        [self.browseNextAction finishInteractiveTransition];
                    }
                    else{
                        [self.browseNextAction cancelInteractiveTransition];
                    }
                }
                else{
                    [self.browseNextAction cancelInteractiveTransition];
                }
            }
        }
            break;
        case UIGestureRecognizerStateCancelled:{
            [self lockButtonInteraction:false];
        }
            break;
        case UIGestureRecognizerStateFailed:{
        }
            break;
        default:
            break;
    }
}


#pragma mark- 绘图设置
- (void)updateRenderViewParams{
//    DebugLogFuncUpdate(@"updateRenderViewParams");
    GLKVector3 eyeBottom = GLKVector3Make(0, self.userInputParams.eyeVerticalHeight, -self.userInputParams.eyeHonrizontalDistance);
    GLKVector3 eyeTop = GLKVector3Make(0, self.userInputParams.eyeHonrizontalDistance, -self.userInputParams.eyeTopZ);
    eyeTop.z += ToSeeCylinderTopPosOffset;
    RECamera.mainCamera.position = GLKVector3Lerp(eyeBottom, eyeTop, self.eyeBottomTopBlend);
    GLKVector3 eyeTopFocus = self.topCamera.focus;
    eyeTopFocus.z += ToSeeCylinderTopPosOffset;
    RECamera.mainCamera.focus = GLKVector3Lerp(self.topCamera.focus, eyeTopFocus, self.eyeBottomTopBlend);
    
    GLKMatrix4 matrix = [ADUltility MatrixLerpFrom:self.bottomCameraProjMatrix to:self.topCamera.projMatrix blend:self.eyeBottomTopBlend];
    RECamera.mainCamera.projMatrix = matrix;
}

#pragma mark- 显示代理DisplayDelegate
- (CGRect)willGetViewport{
    CGFloat scale = self.projectView.contentScaleFactor;
    CGRect frame = CGRectMake(0, ToSeeCylinderTopViewportPixelOffsetY * scale, self.rootView.bounds.size.width * scale, (self.rootView.bounds.size.height + ToSeeCylinderTopPixelOffset) * scale);
    return frame;
}

#pragma mark- 更新 Update
- (void)glkViewControllerUpdate:(GLKViewController *)controller{
//    DebugLog(@"glkViewControllerUpdate");

    //重新设置投影地面的参数
    [self updateRenderViewParams];
    
    [self.curScene update];
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
//    DebugLog(@"drawInRect");
    [self.curScene render];
}

#pragma mark- Opengles Shader相关
-(EAGLContext *)createBestEAGLContext{
    DebugLogFuncStart(@"createBestEAGLContext");
    EAGLContext * context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if(context == nil){
        DebugLogError(@"Failed to create ES context");
    }
    else{
        DebugLog(@"create kEAGLRenderingAPIOpenGLES2 context success");
    }
    return context;
}

- (void)initGLState{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_BLEND);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    
    [[REGLWrapper current] blendFunc:BlendFuncAlphaBlendPremultiplied];
}

- (void)setupGL {
    DebugLogFuncStart(@"setupGL");
    
//    [GLWrapper destroy];
    [REGLWrapper initialize];
    [[REGLWrapper current].context setDebugLabel:@"CylinderProjectView Context"];
    self.projectView.context = [REGLWrapper current].context;
    [self initGLState];
    
    [REResources initialize];
    
    [RETextureManager initialize];

    REDisplay.main = [[REDisplay alloc]initWithGLKView:self.projectView];
    REDisplay.main.delegate = self;
}

- (void)tearDownGL {
    DebugLog(@"tearDownGL");
    
    [EAGLContext setCurrentContext:[REGLWrapper current].context];
    
    [REResources unloadAllAsset];
    [REResources destroy];
    
    [RETextureManager destroy];
    
    REDisplay.main = nil;
    
    RECamera.mainCamera = nil;
    
    [REGLWrapper destroy];
}


#pragma mark- 核心变换
//-(void)viewPaintDoc:(PaintDoc*)paintDoc{
//    self.curPaintDoc = paintDoc;
//    //TODO:导致CylinderProject dismiss后不能被release
//    //TODO:当新建图片时thumbImage为nil,而thumbImagePath有数值
//    if (self.paintTexture) {
//        self.paintTexture.texID = [TextureManager textureInfoFromFileInDocument:paintDoc.thumbImagePath reload:true].name;
//    }
//}

//主题Logo
//- (void)loadLogoWithAnimation:(BOOL)anim{
//}

- (void)reloadLogo{
}


//在project plane上生成图片
-(void)closeImage{

}

//在project plane上生成视频影像
-(void)anamorphVideo{
    NSURL *url = [[NSBundle mainBundle]
                  URLForResource: @"Collection/jerryfish1" withExtension:@"mov"];
    
    self.asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    
    [self generateImage];

    self.playState = PS_Stopped;
}
#pragma mark- 视频
//- (IBAction)playbackButtonTouchUp:(UIButton *)sender {
//    [IBActionReport logAction:@"playbackButtonTouchUp" identifier:sender];
//    [self.player play];
//}

- (void)textureFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
//    glBindTexture(GL_TEXTURE_2D, self.paintTexture);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 520, 520, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(pixelBuffer));
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    
    /*We release some components*/
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    
//    self.paintTexture.texID = [TextureManager textureInfoFromCGImage:newImage].name;
    
    CGImageRelease(newImage);
}

-(UIImage *)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer{
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer.
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    // Get the number of bytes per row for the pixel buffer.
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height.
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space.
    static CGColorSpaceRef colorSpace = NULL;
    if (colorSpace == NULL) {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        if (colorSpace == NULL) {
            // Handle the error appropriately.
            return nil;
        }
    }
    
    // Get the base address of the pixel buffer.
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // Get the data size for contiguous planes of the pixel buffer.
    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    
    // Create a Quartz direct-access data provider that uses data we supply.
    CGDataProviderRef dataProvider =
    CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);
    // Create a bitmap image from data supplied by the data provider.
    CGImageRef cgImage =
    CGImageCreate(width, height, 8, 32, bytesPerRow,
                  colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little,
                  dataProvider, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    
    // Create and return an image object to represent the Quartz image.
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    return image;
}

- (void) readNextMovieFrame
{
    //readNextMovieFrame
    switch (self.assetReader.status) {
        case AVAssetReaderStatusReading:{
//            DebugLog(@"AVAssetReaderStatusReading");
            AVAssetReaderTrackOutput * output = [self.assetReader.outputs objectAtIndex:0];
            CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer];
            if (sampleBuffer)
            {
                [self textureFromSampleBuffer:sampleBuffer];
                
                CMSampleBufferInvalidate(sampleBuffer);
                CFRelease(sampleBuffer);
                sampleBuffer = NULL;
            }
            else{
                //退到后台会导致output copyNextSampleBuffer null
                DebugLog(@"no sampleBuffer");
            }
        }
            break;
        case AVAssetReaderStatusCompleted:{
            DebugLog(@"AVAssetReaderStatusCompleted");
            self.assetReader = nil;
            
            //loop循环播放
            dispatch_async(dispatch_get_main_queue(),^{
                [self readMovie];
            });
        }
        case AVAssetReaderStatusFailed:{
            DebugLog(@"AVAssetReaderStatusFailed: %@", [self.assetReader.error description]);
            //退到后台会导致Failed
            self.assetReader = nil;
            
            //loop循环播放
            dispatch_async(dispatch_get_main_queue(),^{
                [self readMovie];
            });
        }
            break;                                    
        case AVAssetReaderStatusCancelled:{
            self.assetReader = nil;
        }
            break;            
        default:
            break;
    }
}

- (void)readMovie{
    NSArray *tracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
    if (tracks.count == 1) {
        AVAssetTrack *track = [tracks objectAtIndex:0];
        NSMutableDictionary* videoSettings = [[NSMutableDictionary alloc] init];
        [videoSettings setObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        //audio
//        [videoSettings setObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        AVAssetReaderTrackOutput *output = [[AVAssetReaderTrackOutput alloc]initWithTrack:track outputSettings:videoSettings];
        NSError * error = nil;
        self.assetReader = [[AVAssetReader alloc]initWithAsset:self.asset error:&error];
        if (error){
            DebugLog(@"Error loading file: %@", [error localizedDescription]);
        }
        
        [self.assetReader addOutput:output];
        //test
        Float64 durationSeconds = CMTimeGetSeconds([self.asset duration]);
        self.assetReader.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(durationSeconds * 0.67, 24), CMTimeMakeWithSeconds((durationSeconds/3.0), 24));
        
        if ([self.assetReader startReading]) {
            self.playState = PS_Playing;
            [self.playButton setIsPlaying:true];
        }
        else{
            DebugLog(@"assetReader startReading failed");
        }
    }
    //audio
    NSError *error;
    
    AVKeyValueStatus status = [self.asset statusOfValueForKey:@"tracks" error:&error];
    
    if (status == AVKeyValueStatusLoaded) {
        self.playerItem = [AVPlayerItem playerItemWithAsset:self.asset];
        [self.playerItem addObserver:self forKeyPath:@"status"
                             options:0 context:&ItemStatusContext];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:self.playerItem];
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        [self.player play];
    }
    else {
        // You should deal with the error appropriately.
        DebugLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
    }
    
//    NSArray *soundTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
//    if (soundTracks.count >=1) {
//        AVAssetTrack *soundTrack = [soundTracks objectAtIndex:0];
//
//    }
}

//截取静态图片
-(void)generateImage{
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:self.asset];
    
//    Float64 durationSeconds = CMTimeGetSeconds([self.asset duration]);
//    CMTime midpoint = CMTimeMakeWithSeconds(durationSeconds/2.0, 600);
    CMTime midpoint = CMTimeMakeWithSeconds( 0.0, 600);
    NSError *error;
    CMTime actualTime;
    
    CGImageRef halfWayImage = [imageGenerator copyCGImageAtTime:midpoint actualTime:&actualTime error:&error];
    
    if (halfWayImage != NULL) {
        
#if DEBUG
        NSString *actualTimeString = (__bridge NSString *)CMTimeCopyDescription(NULL, actualTime);
        NSString *requestedTimeString = (__bridge NSString *)CMTimeCopyDescription(NULL, midpoint);
#endif
        DebugLog(@"Got halfWayImage: Asked for %@, got %@", requestedTimeString, actualTimeString);
        
        // Do something interesting with the image.
        
        CGImageRelease(halfWayImage);
    }
}

- (void)playVideo{
    [self.asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^() {
        dispatch_async(dispatch_get_main_queue(),^{
            [self readMovie];
        });
    }];

}
- (void)stopVideo{
    [self.asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^() {
        dispatch_async(dispatch_get_main_queue(),^{
            [self readMovie];
        });
    }];
    
}

- (void)pauseVideo{
    [self.assetReader cancelReading];
    [self.player pause];
    self.playState = PS_Pause;
    [self.playButton setIsPlaying:false];
}

//- (IBAction)playButtonTouchUp:(UIButton *)sender {
//    [IBActionReport logAction:@"playButtonTouchUp" identifier:sender];
//    if (self.playState == PS_Stopped) {
//        [self playVideo];
//    }
//    else if (self.playState == PS_Playing) {
//        [self pauseVideo];
//    }
//    else if (self.playState == PS_Pause) {
//        [self playVideo];
//    }
//}

- (void)flushAllUI {
    if(self.eyeBottomTopBlend > 0.0){
        self.isTopViewMode = true;
    }
    else{
        self.isTopViewMode = false;
    }
//    [self syncPlayUI];
}

- (void)syncPlayUI {
    if ((self.player.currentItem != nil) &&
        ([self.player.currentItem status] == AVPlayerItemStatusReadyToPlay)) {
        self.playButton.enabled = YES;
    }
    else {
        self.playButton.enabled = NO;
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self.player seekToTime:kCMTimeZero];
}
- (CGRect)getCylinderMirrorFrame{
//    return CGRectMake(307, 285, 154, 154 / rootView.bounds.size.width * rootView.bounds.size.height);
//    return CGRectMake(308, 286, 150, 150 / rootView.bounds.size.width * rootView.bounds.size.height);
//    return CGRectMake(311, 270, 146, 146 / rootView.bounds.size.width * rootView.bounds.size.height);
    
    if ([ADDeviceHardware sharedInstance].isMini) {
        return CGRectMake(311, 344, 146, 146 / self.rootView.bounds.size.width * self.rootView.bounds.size.height);
    }
    else{
        return CGRectMake(311, 351, 146, 146 / self.rootView.bounds.size.width * self.rootView.bounds.size.height);
    }

}

- (CGRect)getCylinderMirrorTopFrame{
    CGFloat margin = 5;
    return CGRectMake(289 - margin, 220 - margin, 192 + margin * 2, 192 + margin * 2);
}

- (ADCylinderProject*)dequeueReusableCylinderProject{
    for (REEntity *entity in self.curScene.aEntities) {
        if ([entity isKindOfClass:[ADCylinderProject class]]) {
            ADCylinderProject *cylinderProject = (ADCylinderProject *)entity;
            if (!cylinderProject.isActive) {
                cylinderProject.active = true;
                return cylinderProject;
            }
        }
    }
    
    //no inactive cylinderProject, alloc new
    DebugLog(@"no inactive cylinderProject, alloc new");
    ADCylinderProject *cylinderProjectCopy = [self.cylinderProjectCur copy];
    cylinderProjectCopy.name = @"cylinderProjectCopy";
    [self.curScene addEntity:cylinderProjectCopy];
    
    return cylinderProjectCopy;
}

#pragma mark- CustomPercentDrivenInteractiveTransition
- (void)willUpdatingInteractiveTransition:(ADCustomPercentDrivenInteractiveTransition*)transition{
//    DebugLogFuncUpdate(@"willUpdatingInteractiveTransition");
    if ([transition.name isEqualToString:@"browseNext"]) {
//        DebugLog(@"browsing Next");
        CGFloat x = transition.percentComplete * self.cylinderProjectCur.imageWidth;
        [self.cylinderProjectCur setValue:[NSNumber numberWithFloat:x] forKeyPath:@"transform.translate.x"];
        
        
        //查询是否有下一张图片
        if (transition.percentComplete > 0) {
            if ([[ADPaintFrameManager curGroup] nextPaintDoc]) {
                //清空上一张图片资源
                self.cylinderProjectLast.active = false;
                self.cylinderProjectLast = nil;
                
                if (!self.cylinderProjectNext) {
                    self.cylinderProjectNext = [self dequeueReusableCylinderProject];
                    REPropertyAnimation *browsePropAnim = [REPropertyAnimation propertyAnimationWithKeyPath:@"transform.translate.x"];
                    browsePropAnim.delegate = self;
                    browsePropAnim.timing = REPropertyAnimationTimingEaseOut;
                    REAnimationClip *animclip = [REAnimationClip animationClipWithPropertyAnimation:browsePropAnim];
                    animclip.name = @"browseAnimClip";
                    [self.cylinderProjectNext.animation removeClip:@"browseAnimClip"];
                    [self.cylinderProjectNext.animation addClip:animclip];
                    
                    
                    NSString *path = [[ADPaintFrameManager curGroup] nextPaintDoc].thumbImagePath;
                    path = [[ADUltility applicationDocumentDirectory] stringByAppendingPathComponent:path];
                    self.cylinderProjectNext.renderer.material.mainTexture = [RETexture textureFromImagePath:path reload:false];
                }
            }
        }
        
        x = (transition.percentComplete - 1) * self.cylinderProjectCur.imageWidth;
        if (self.cylinderProjectNext) {
            [self.cylinderProjectNext setValue:[NSNumber numberWithFloat:x] forKeyPath:@"transform.translate.x"];
        }
        
    }
    else if ([transition.name isEqualToString:@"browseLast"]) {
//        DebugLog(@"browsing Last");
        CGFloat x = -transition.percentComplete * self.cylinderProjectCur.imageWidth;
        [self.cylinderProjectCur setValue:[NSNumber numberWithFloat:x] forKeyPath:@"transform.translate.x"];
        
        if (transition.percentComplete > 0) {
            //查询是否有上一张图片
            if ([[ADPaintFrameManager curGroup] lastPaintDoc]) {
                //清空下一张图片资源
                self.cylinderProjectNext.active = false;
                self.cylinderProjectNext = nil;
                
                if (!self.cylinderProjectLast) {
                    self.cylinderProjectLast = [self dequeueReusableCylinderProject];
                    REPropertyAnimation *browsePropAnim = [REPropertyAnimation propertyAnimationWithKeyPath:@"transform.translate.x"];
                    browsePropAnim.delegate = self;
                    browsePropAnim.timing = REPropertyAnimationTimingEaseOut;
                    REAnimationClip *animclip = [REAnimationClip animationClipWithPropertyAnimation:browsePropAnim];
                    animclip.name = @"browseAnimClip";
                    [self.cylinderProjectLast.animation removeClip:@"browseAnimClip"];
                    [self.cylinderProjectLast.animation addClip:animclip];

                    
                    NSString *path = [[ADPaintFrameManager curGroup] lastPaintDoc].thumbImagePath;
                    path = [[ADUltility applicationDocumentDirectory] stringByAppendingPathComponent:path];
                    self.cylinderProjectLast.renderer.material.mainTexture = [RETexture textureFromImagePath:path reload:false];
                    
                }
            }
        }

        x = -(transition.percentComplete - 1) * self.cylinderProjectCur.imageWidth;
        if (self.cylinderProjectLast) {
            [self.cylinderProjectLast setValue:[NSNumber numberWithFloat:x] forKeyPath:@"transform.translate.x"];
        }
    }
}

- (void)willFinishInteractiveTransition:(ADCustomPercentDrivenInteractiveTransition*)transition completion: (void (^)(void))completion{
    DebugLogFuncStart(@"willFinishInteractiveTransition");
    
    REAnimationClip *curAnimClip = [self.cylinderProjectCur.animation.clips valueForKey:@"browseAnimClip"];
    REPropertyAnimation *curPropAnim = curAnimClip.propertyAnimations.firstObject;

    if ([transition.name isEqualToString:@"browseNext"]) {
        curPropAnim.fromValue = [self.cylinderProjectCur valueForKeyPath:@"transform.translate.x"];
        curPropAnim.toValue = [NSNumber numberWithFloat:self.cylinderProjectCur.imageWidth];
        [curPropAnim setCompletionBlock:^{
            DebugLog(@"browse Next anim finished");
            self.cylinderProjectCur.active = false;
            self.cylinderProjectCur = self.cylinderProjectNext;
            self.cylinderProjectNext = nil;
            self.cylinderProjectLast = nil;
            [ADPaintFrameManager curGroup].curPaintIndex ++;
            
            //更新显示
            [self changeTitleWithPaintDoc:[ADPaintFrameManager curGroup].curPaintDoc];
            
            //结束教程
            if([[ADSimpleTutorialManager current] isActive]){
                if ([[ADSimpleTutorialManager current].curTutorial.curStep.name isEqualToString:@"CylinderProjectNextImage"]) {
                    [self tutorialStepNextImmediate:YES];
                }
            }
            
            completion();
        }];
        self.cylinderProjectCur.animation.clip = curAnimClip;
        [self.cylinderProjectCur.animation play];

        DebugLog(@"playing browse Next anim");
        REAnimationClip *nextAnimClip = [self.cylinderProjectNext.animation.clips valueForKey:@"browseAnimClip"];
        REPropertyAnimation *nextPropAnim = nextAnimClip.propertyAnimations.firstObject;
        nextPropAnim.fromValue = [self.cylinderProjectNext valueForKeyPath:@"transform.translate.x"];
        nextPropAnim.toValue = [NSNumber numberWithFloat:0];
        self.cylinderProjectNext.animation.clip = nextAnimClip;
        [self.cylinderProjectNext.animation play];
        
    }
    else if ([transition.name isEqualToString:@"browseLast"]) {

        curPropAnim.fromValue = [self.cylinderProjectCur valueForKeyPath:@"transform.translate.x"];
        curPropAnim.toValue = [NSNumber numberWithFloat:-self.cylinderProjectCur.imageWidth];
        
        [curPropAnim setCompletionBlock:^{
            DebugLog(@"browse Last anim finished");
            self.cylinderProjectCur.active = false;
            self.cylinderProjectCur = self.cylinderProjectLast;
            self.cylinderProjectNext = nil;
            self.cylinderProjectLast = nil;
            [ADPaintFrameManager curGroup].curPaintIndex --;
            
            //更新显示
            [self changeTitleWithPaintDoc:[ADPaintFrameManager curGroup].curPaintDoc];
            
            //结束教程
            if([[ADSimpleTutorialManager current] isActive]){
                if ([[ADSimpleTutorialManager current].curTutorial.curStep.name isEqualToString:@"CylinderProjectPreviousImage"]) {
                    [self tutorialStepNextImmediate:YES];
                }
            }
            
            completion();
        }];
        self.cylinderProjectCur.animation.clip = curAnimClip;
        [self.cylinderProjectCur.animation play];

        DebugLog(@"playing browse Last anim");

        REAnimationClip *lastAnimClip = [self.cylinderProjectLast.animation.clips valueForKey:@"browseAnimClip"];
        REPropertyAnimation *lastPropAnim = lastAnimClip.propertyAnimations.firstObject;
        lastPropAnim.fromValue = [self.cylinderProjectLast valueForKeyPath:@"transform.translate.x"];
        lastPropAnim.toValue = [NSNumber numberWithFloat:0];
        self.cylinderProjectLast.animation.clip = lastAnimClip;
        [self.cylinderProjectLast.animation play];
    }
}

- (void)willCancelInteractiveTransition:(ADCustomPercentDrivenInteractiveTransition *)transition completion: (void (^)(void))completion{
    DebugLogFuncStart(@"willCancelInteractiveTransition");
    
    REAnimationClip *animClip = [self.cylinderProjectCur.animation.clips valueForKey:@"browseAnimClip"];
    REPropertyAnimation *propAnim = animClip.propertyAnimations.firstObject;
    if ([transition.name isEqualToString:@"browseNext"]) {
        DebugLog(@"canceling browse Next");
        propAnim.fromValue = [self.cylinderProjectCur valueForKeyPath:@"transform.translate.x"];
        propAnim.toValue = [NSNumber numberWithFloat:0];
        [propAnim setCompletionBlock:^{
            completion();
        }];
        self.cylinderProjectCur.animation.clip = animClip;
        [self.cylinderProjectCur.animation play];
        
        REAnimationClip *nextAnimClip = [self.cylinderProjectNext.animation.clips valueForKey:@"browseAnimClip"];
        REPropertyAnimation *propAnim = nextAnimClip.propertyAnimations.firstObject;
        propAnim.fromValue = [self.cylinderProjectNext valueForKeyPath:@"transform.translate.x"];
        propAnim.toValue = [NSNumber numberWithFloat:-self.cylinderProjectNext.imageWidth];
        self.cylinderProjectNext.animation.clip = nextAnimClip;
        [self.cylinderProjectNext.animation play];
    }
    else if ([transition.name isEqualToString:@"browseLast"]) {
        DebugLog(@"canceling browse Last");
        propAnim.fromValue = [self.cylinderProjectCur valueForKeyPath:@"transform.translate.x"];
        propAnim.toValue = [NSNumber numberWithFloat:0];
        [propAnim setCompletionBlock:^{
            completion();
        }];
        self.cylinderProjectCur.animation.clip = animClip;
        [self.cylinderProjectCur.animation play];
        
        REAnimationClip *lastAnimClip = [self.cylinderProjectLast.animation.clips valueForKey:@"browseAnimClip"];
        REPropertyAnimation *propAnim = lastAnimClip.propertyAnimations.firstObject;
        propAnim.fromValue = [self.cylinderProjectLast valueForKeyPath:@"transform.translate.x"];
        propAnim.toValue = [NSNumber numberWithFloat:self.cylinderProjectLast.imageWidth];
        self.cylinderProjectLast.animation.clip = lastAnimClip;
        [self.cylinderProjectLast.animation play];
    }
}

#pragma mark- ADPropertyAnimationDelegate
-(void)willBeginPropertyAnimation:(REPropertyAnimation *)propertyAnimation{
    DebugLogFuncStart(@"willBeginPropertyAnimation keyPath:%@ target:%@", propertyAnimation.keyPath, propertyAnimation.target);
    if ((propertyAnimation.timing & REPropertyAnimationOptionRepeat) != REPropertyAnimationOptionRepeat) {
        [self lockInteraction:true];
    }
}

-(void)propertyAnimationDidFinish:(REPropertyAnimation *)propertyAnimation{
    DebugLogFuncStart(@"propertyAnimationDidFinish keyPath:%@ target:%@", propertyAnimation.keyPath, propertyAnimation.target);
    if (self.paintDirectly) {
        [self lockInteraction:true];
        self.paintDirectly = false;
    }
    else if (self.isTopViewMode) {
        [self lockInteraction:false];
        self.projectView.userInteractionEnabled = false;
    }
    else{
        [self lockInteraction:false];
    }
    
    //FIXME:教程操作问题打补丁
    if ([[ADSimpleTutorialManager current] isActive]) {
        if(!([[ADSimpleTutorialManager current].curTutorial.curStep.name isEqualToString:@"CylinderProjectPreviousImage"] ||
             [[ADSimpleTutorialManager current].curTutorial.curStep.name isEqualToString:@"CylinderProjectNextImage"])){
            self.projectView.userInteractionEnabled = false;
        }
    }
}

#pragma mark- PaintScreenTransitionManagerDelegate
- (CGRect)willGetCylinderMirrorFrame{
    return [self getCylinderMirrorFrame];
}

#pragma mark- UIViewControllerTransitioningDelegate
- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    self.transitionManager.isPresenting = YES;
    return self.transitionManager;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    self.transitionManager.isPresenting = NO;
    return self.transitionManager;
}

#pragma mark- 购买代理InAppPurchaseTableViewControllerDelegate
- (ADBrush*) willGetBrushByIAPFeatureIndex:(IAPProPackageFeature)feature{
    return nil;
}
- (void)willIAPPurchaseDone{
    [self.iapVC dismissViewControllerAnimated:true completion:^{
        DebugLog(@"willIAPPurchaseDone");
    }];
    
    
    if([[NSUserDefaults standardUserDefaults]boolForKey:@"AnamorphosisSetup"]){
        self.topToolBar.userInteractionEnabled = true;
    }
    else{
        [self setupAnamorphParamsDoneAnimationCompletion:nil];        
    }
}
#pragma mark- 绘画Paint
-(void)openPaintDoc:(ADPaintDoc*)paintDoc {
    //    self.curPaintDoc = paintDoc;
    self.paintScreenVC =  [self.storyboard instantiateViewControllerWithIdentifier:@"paintScreen"];
    self.paintScreenVC.delegate = self;
    self.paintScreenVC.isReversePaint = self.isReversePaint;
    self.paintScreenVC.transitioningDelegate = self;
    
    //prepare for presentation
    GLKVector4 uvSpace; CGFloat imageRatio = 1;
//    ADPaintDoc *reversePaintDocSrc = nil;
    if (self.isReversePaint) {
        uvSpace = self.cylinder.reflectionTexUVSpace;
        imageRatio = self.projectView.bounds.size.height / self.projectView.bounds.size.width;
        
//        reversePaintDocSrc = [ADPaintFrameManager curGroup].curPaintDoc;
    }
    
    //打开绘图面板动画，从cylinder的中心放大过度到paintScreenViewController
//    DebugLogWarn(@"openPaintDoc fromVC scale %.1f", ((NSNumber*)[self.rootView.layer valueForKeyPath:@"transform.scale"]).floatValue);
    [self presentViewController:self.paintScreenVC animated:true completion:^{
        DebugLog(@"presentViewController paintScreenVC completionBlock");
        self.paintButton.selected = false;
        [self lockInteraction:false];
        
        self.paintScreenVC.closeButton.isReversePaint = self.isReversePaint;
        [self.paintScreenVC openDoc:paintDoc];
        
        if (self.isReversePaint) {
            self.paintScreenVC.reversePaint.reversePaintInputData = [[ADReversePaintInputData alloc]init];
            self.paintScreenVC.reversePaint.reversePaintInputData.radius = self.userInputParams.cylinderDiameter * 0.5;
            self.paintScreenVC.reversePaint.reversePaintInputData.eye = GLKVector3Make(0, self.userInputParams.eyeVerticalHeight, -self.userInputParams.eyeHonrizontalDistance);
            self.paintScreenVC.reversePaint.reversePaintInputData.imageWidth = self.userInputParams.imageWidth;
            self.paintScreenVC.reversePaint.reversePaintInputData.imageCenterOnSurfHeight = self.userInputParams.imageCenterOnSurfHeight;
            self.paintScreenVC.reversePaint.reversePaintInputData.imageRatio = imageRatio;
            self.paintScreenVC.reversePaint.reversePaintInputData.reflectionTexUVSpace = uvSpace;
            
            //reversePaint IAP
            if ([ADSimpleTutorialManager current].isActive) {
                //教程免费试用
            }
            else{
                if(![[NSUserDefaults standardUserDefaults] boolForKey:@"ReversePaint"]){
                    [self.paintScreenVC openIAPWithProductFeatureIndex:0];
                }
            }
        }
    }];
}

- (void)setIsReversePaint:(BOOL)isReversePaint{
    _isReversePaint = isReversePaint;
    self.paintButton.isReversePaint = isReversePaint;
}
#pragma mark- 绘画代理PaintScreenDelegate
- (EAGLContext*) createEAGleContextWithShareGroup{
    return [self createBestEAGLContext];
}

- (void) willPaintScreenDissmissWithPaintDoc:(ADPaintDoc *)paintDoc{
//    self.cylinderProjectDefaultAlphaBlend = 1;
    
    //刷新当前画框内容
    if (self.isReversePaint) {
    }
    else{
        NSString *path = [[ADUltility applicationDocumentDirectory] stringByAppendingPathComponent:paintDoc.thumbImagePath];
        UIImageView *transitionImageView = (UIImageView *)[self.rootView subViewWithTag:100];
        transitionImageView.image = [UIImage imageWithContentsOfFile:path];
        transitionImageView.alpha = 1;
    }
}

- (void) willPaintScreenDissmissDoneWithPaintDoc:(ADPaintDoc *)paintDoc{
    DebugLogFuncStart(@"willPaintScreenDissmissDoneWithPaintDoc");
    NSString *path = [[ADUltility applicationDocumentDirectory] stringByAppendingPathComponent:paintDoc.thumbImagePath];
    UIImageView *transitionImageView = (UIImageView *)[self.rootView subViewWithTag:100];
    self.cylinderProjectCur.renderer.material.mainTexture = [RETexture textureFromImagePath:path reload:true];
    
    if(self.isSetupMode){
        //设定到默认的userInputParams
        [ADPaintUIKitAnimation view:self.rootView switchTopToolBarToView:self.topToolBar completion:nil];
    }
    
    if (self.isReversePaint) {
    }
    else{
        //变换反射图动画
//        transitionImageView.image = [UIImage imageWithContentsOfFile:path];
        self.cylinder.reflectionStrength = 0;
        REAnimationClip *animClip = [self.cylinder.animation.clips valueForKey:@"reflectionFadeInOutAnimClip"];
        REPropertyAnimation *propAnim = animClip.propertyAnimations.firstObject;
        propAnim.duration = CylinderFadeInOutDuration;
        propAnim.fromValue = [NSNumber numberWithFloat:0];
        propAnim.toValue = [NSNumber numberWithFloat:1];
        [self.cylinder.animation play];
        
        [UIView animateWithDuration:CylinderFadeInOutDuration delay:CylinderFadeInOutDeallocDelay options:UIViewAnimationOptionCurveEaseInOut animations:^{
            transitionImageView.alpha = 0;
        } completion:^(BOOL finished) {
        }];
        
        UIView *fromView = self.rootView;
        CGRect rect = [self willGetCylinderMirrorFrame];
        CGFloat scale = self.rootView.frame.size.width / rect.size.width;
        [fromView.layer setValue:[NSNumber numberWithFloat:scale] forKeyPath:@"transform.scale"];
        DebugLog(@"willPaintScreenDissmissDoneWithPaintDoc translating");
        [UIView animateWithDuration:CylinderFadeInOutDuration delay:CylinderFadeInOutDeallocDelay options:UIViewAnimationOptionCurveEaseOut animations:^{
            [fromView.layer setValue:[NSNumber numberWithFloat:1] forKeyPath:@"transform.scale"];
        } completion:^(BOOL finished) {
            //实际动画时间超过设定时间，中间有class dealloc发生
            DebugLog(@"willPaintScreenDissmissDoneWithPaintDoc translation done");
            fromView.layer.anchorPoint = CGPointMake(0.5, 0.5);
            fromView.layer.position = CGPointMake(fromView.bounds.size.width * 0.5, fromView.bounds.size.height * 0.5);
        }];
    }
    
    [paintDoc closeData];
}


#pragma mark- 调整视角View
- (void)setIsTopViewMode:(BOOL)isTopViewMode{
    _isTopViewMode = isTopViewMode;
    self.topPerspectiveView.hidden = isTopViewMode;
    self.eyePerspectiveView.hidden = !isTopViewMode;
}

- (IBAction)sideViewButtonTouchUp:(UIButton *)sender {
    [RemoteLog logAction:@"CP_sideViewButtonTouchUp" identifier:sender];
    
    [self tutorialStepNextImmediate:false];
    
//    [self restoreBrightness];
    
    [self deselectUserInputParams];
    
    //visibility
    self.isTopViewMode = self.isReversePaint = false;
    
    //interaction
    [self lockInteraction:true];
    
    //animation
    REAnimationClip *animClip = [RECamera.mainCamera.animation.clips valueForKey:@"topToBottomAnimClip"];
    RECamera.mainCamera.animation.clip = animClip;
    RECamera.mainCamera.animation.target = self;
    [RECamera.mainCamera.animation play];

    
    //transition backgroundView
//    [CATransaction begin];
//    [CATransaction setAnimationDuration:0.6];
//    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
//    [CATransaction setCompletionBlock:^{
//        ((ADRootCanvasBackgroundViewLayer*)(self.rootView.backgroundView.layer)).blend = 0;
//    }];
//    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"blend"];
//    anim.toValue = [NSNumber numberWithFloat:0];
//    anim.removedOnCompletion = NO;
//    anim.fillMode = kCAFillModeForwards;
//    [self.rootView.backgroundView.layer addAnimation:anim forKey:@"blend"];
//    
//    [((ADRootCanvasBackgroundViewLayer*)(self.rootView.backgroundView.layer)) addAnimation:anim forKey:@"blend"];
//    [CATransaction commit];
    
    
    
    //setup
    UIColor *color = [UIColor colorWithRed:72/255.0 green:110/255.0 blue:224/255.0 alpha:1];
//    self.eyeDistanceButton.userInteractionEnabled = self.eyeHeightButton.userInteractionEnabled = true;
//    [self.eyeDistanceButton setTitleColor:color forState:UIControlStateNormal];
//    [self.eyeDistanceButton setTitleColor:color forState:UIControlStateHighlighted];
//    [self.eyeHeightButton setTitleColor:color forState:UIControlStateNormal];
//    [self.eyeHeightButton setTitleColor:color forState:UIControlStateHighlighted];
    self.eyeZoomButton.userInteractionEnabled = true;    
    [self.eyeZoomButton setTitleColor:color forState:UIControlStateNormal];
    [self.eyeZoomButton setTitleColor:color forState:UIControlStateHighlighted];
}

- (IBAction)topViewButtonTouchUp:(UIButton *)sender {
    [RemoteLog logAction:@"CP_topViewButtonTouchUp" identifier:sender];
    
    [self tutorialStepNextImmediate:false];
    
    //MARK:在以后的版本中打开
//    [self fitBrightness];
    
    [self deselectUserInputParams];
    
    //visibility
    self.isTopViewMode = self.isReversePaint = true;

    //interaction
    [self lockInteraction:true];
    
    //animation
    REAnimationClip *animClip = [RECamera.mainCamera.animation.clips valueForKey:@"bottomToTopAnimClip"];
    RECamera.mainCamera.animation.clip = animClip;
    RECamera.mainCamera.animation.target = self;
    [RECamera.mainCamera.animation play];
    
    //transition backgroundView
//    [CATransaction begin];
//    [CATransaction setAnimationDuration:0.6];
//    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
//    [CATransaction setCompletionBlock:^{
//        ((ADRootCanvasBackgroundViewLayer*)(self.rootView.backgroundView.layer)).blend = 1;
//    }];
//    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"blend"];
//    anim.toValue = [NSNumber numberWithFloat:1];
//    anim.removedOnCompletion = NO;
//    anim.fillMode = kCAFillModeForwards;
//    [self.rootView.backgroundView.layer addAnimation:anim forKey:@"blend"];
//    
//    [((ADRootCanvasBackgroundViewLayer*)(self.rootView.backgroundView.layer)) addAnimation:anim forKey:@"blend"];
//    [CATransaction commit];
    
    
    
    //setup
//    self.eyeDistanceButton.userInteractionEnabled = self.eyeHeightButton.userInteractionEnabled = false;
    //    [self.eyeDistanceButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    //    [self.eyeDistanceButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
    //    [self.eyeHeightButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    //    [self.eyeHeightButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
    
    self.eyeZoomButton.userInteractionEnabled = false;
    [self.eyeZoomButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.eyeZoomButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
}

#pragma mark- 打印Print
//- (void)exportToAirPrint{
//    //TODO:转换到顶视图，在放圆柱体的位置画上圈，并打印
//    UIImage *image = [self.projectView snapshot];
//    
//    //convert UIImage to NSData to add it as attachment
//    NSData *data = UIImagePNGRepresentation(image);
//    
//    UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
//    
//    if  (pic && [UIPrintInteractionController canPrintData: data] ) {
//        
//        pic.delegate = self;
//        
//        UIPrintInfo *printInfo = [UIPrintInfo printInfo];
//        printInfo.outputType = UIPrintInfoOutputGeneral;
//        printInfo.jobName = [NSString stringWithFormat:@"image%lu", (unsigned long)image.hash];
//        printInfo.duplex = UIPrintInfoDuplexLongEdge;
//        pic.printInfo = printInfo;
//        pic.showsPageRange = YES;
//        pic.printingItem = data;
//        
//        void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) = ^(UIPrintInteractionController *pic, BOOL completed, NSError *error) {
//            
//            if (!completed && error)
//                DebugLog(@"FAILED! due to error in domain %@ with error code %u",error.domain, error.code);
//        };
//        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//            [pic presentFromRect:self.printButton.bounds inView:self.printButton animated:true completionHandler:completionHandler];
//        } else {
//            [pic presentAnimated:YES completionHandler:completionHandler];
//        }
//    }
//}

#pragma mark- 陀螺仪代理MotionDelegate
- (void)initMotionDetect{
    self.motionManager = [[CMMotionManager alloc]init];
    NSOperationQueue *aQueue=[[NSOperationQueue alloc]init];
    if (!self.motionManager.deviceMotionAvailable) {
        //pop message box
        DebugLog(@"motion manager not available!");
    }
    
    self.motionManager.deviceMotionUpdateInterval = 0.033;
    if (![self.motionManager isDeviceMotionActive]) {
        [self.motionManager startDeviceMotionUpdatesToQueue:aQueue withHandler:
         ^(CMDeviceMotion *motion, NSError *error){
             if (motion) {
//                 DebugLog(@"attitude yaw: %.1f  pitch: %.1f  roll: %.1f", motion.attitude.yaw, motion.attitude.pitch, motion.attitude.roll);
                 
                 //监测未在动画中到角度的变化到固定值
                 //TODO: do with TPPropertyAnimation
//                 if (self.state == CP_Projected){
//                     if (motion.attitude.pitch < 0.1 && self.lastPitch >= 0.1  && self.eyeBottomTopBlend <1.0) {
//                         self.state = CP_PitchingToTopView;
//                     }
//                     else if (motion.attitude.pitch >= 0.1 && self.lastPitch < 0.1 && self.eyeBottomTopBlend > 0.0){
//                         self.state = CP_PitchingToBottomView;
//                     }
//                 }

                 self.lastPitch = motion.attitude.pitch;

//                 UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
//                 DebugLog(@"UIDeviceOrientation %d", deviceOrientation);
//                 dispatch_async(dispatch_get_main_queue(), ^{
//                     self.eyeTopBottomBlend = MIN(MAX(0, 1 - (self.lastPitch / M_PI_2)), 1) ;
//                 });
             }
         }];
        
    }
}

- (void)openIAP{
    [RemoteLog logAction:@"CP_OpenIAP" identifier:nil];
    self.iapVC =  [self.storyboard instantiateViewControllerWithIdentifier:@"inAppPurchaseTableViewController"];
    self.iapVC.delegate = self;
    [self presentViewController:self.iapVC animated:true completion:^{
    }];
}

#pragma mark- 处理警告 UIAlertViewDelegate
//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
//    
//    if (alertView.tag == 2) {
//
//        switch (buttonIndex) {
//            case 0:
//            {
//                //Dont Save. Exist to original userInputParams
//                [self animationToTarget:self.userInputParams params:self.userInputParamsSrc.propertyNameValueDic duration:CylinderResetParamDuration timing:REPropertyAnimationTimingEaseOut completionDelegate:self completionBlock:^{
//                    [self flushUIUserInputParams];
//                    [self setupAnamorphParamsDone];
//                    //        [[ADPaintFrameManager curGroup].curPaintDoc saveUserInputParams];
//                }];
//            }
//            break;
//            case 1:
//            {
//                //Save UserInputParams
//                [self setupAnamorphParamsSave];
//                [self setupAnamorphParamsDone];
//            }
//            break;
//
//            default:
//                break;
//        }
//        
//    }
//}

#pragma mark- 弹出框代理 UIPopoverViewControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    if([popoverController.contentViewController isKindOfClass:[ADShareTableViewController class]]){
        self.shareButton.selected = false;
    }
    else if([popoverController.contentViewController isKindOfClass:[ADProductInfoTableViewController class]]){
        self.infoButton.selected = false;
    }
}

- (IBAction)virtualDeviceButtonTouchUp:(UIButton *)sender {
    [RemoteLog logAction:@"CP_virtualDeviceButtonTouchUp" identifier:sender];
    
    ADCylinderProjectVirtualDeviceCollectionViewController* virtualDeviceCollectionViewController =  [self.storyboard instantiateViewControllerWithIdentifier:@"CylinderProjectVirtualDeviceCollectionViewController"];
//    virtualDeviceCollectionViewController.delegate = self;
    
    
    virtualDeviceCollectionViewController.preferredContentSize = CGSizeMake(DefaultScreenWidth, 150);
    
    self.sharedPopoverController = [[ADSharedPopoverController alloc]initWithContentViewController:virtualDeviceCollectionViewController];
    CGRect rect = CGRectMake(self.virtualDeviceButton.bounds.origin.x, self.virtualDeviceButton.bounds.origin.y, self.virtualDeviceButton.bounds.size.width, self.virtualDeviceButton.bounds.size.height);
    [self.sharedPopoverController presentPopoverFromRect:rect inView:self.virtualDeviceButton permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
    
}

#pragma mark- 命名框UITextFieldDelegate
- (void)setPaintDocNameTextFieldRect{
    NSDictionary *attribute = @{NSFontAttributeName: [UIFont systemFontOfSize:30]};
    CGSize size = CGSizeMake(self.rootView.bounds.size.width, self.paintDocNameTextField.bounds.size.height);
    CGRect rect = [self.paintDocNameTextField.text boundingRectWithSize:size options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attribute context:nil];
    [self.paintDocNameTextField setFrameSizeWidth:MIN(self.rootView.bounds.size.width, MAX(PaintDocTitleMinWidth, rect.size.width + 30*2))];
    [self.paintDocNameTextField setCenterX:self.rootView.center.x];
}
- (void)changeTitleWithPaintDoc:(ADPaintDoc*)paintDoc{
    NSString *title = paintDoc.title;

    [UIView animateWithDuration:PaintDocTitleFadeInOutDuration animations:^{
        self.paintDocNameTextField.alpha = 0;
    }completion:^(BOOL finished) {
        self.paintDocNameTextField.text = title;
        [self setPaintDocNameTextFieldRect];
        [UIView animateWithDuration:PaintDocTitleFadeInOutDuration animations:^{
            self.paintDocNameTextField.alpha = 1;
        }completion:^(BOOL finished) {
        }];
    }];
    
}

- (void)displayTitle:(BOOL)display withPaintDoc:(ADPaintDoc*)paintDoc{
    [self changeTitleWithPaintDoc:paintDoc];
    
    if (display) {
        self.paintDocNameTextField.alpha = 0;
        self.paintDocNameTextField.hidden = false;
        [UIView animateWithDuration:CylinderFadeInOutDuration animations:^{
            self.paintDocNameTextField.alpha = 1;
        }];
    }
    else{
        self.paintDocNameTextField.alpha = 1;
        [UIView animateWithDuration:CylinderFadeInOutDuration animations:^{
            self.paintDocNameTextField.alpha = 0;
        }completion:^(BOOL finished) {
            self.paintDocNameTextField.hidden = true;
        }];
    }

}
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    [Flurry logEvent:@"CP_inChangeTitle" withParameters:nil timed:true];
    [self lockInteraction:true];
    
    self.paintDocTitle = [ADPaintFrameManager curGroup].curPaintDoc.title;
    self.paintDocNameTextField.textColor = [UIColor whiteColor];
}

- (BOOL)textFieldShouldClear:(UITextField *)textField{
    return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self lockInteraction:false];
    self.paintDocTitle = textField.text;
    [self.paintDocNameTextField endEditing:true];
    return YES;
}
- (void)textFieldDidEndEditing:(UITextField *)textField{
    [Flurry endTimedEvent:@"CP_inChangeTitle" withParameters:nil];
    [ADPaintFrameManager curGroup].curPaintDoc.title = self.paintDocTitle;
    textField.text = self.paintDocTitle;

    [[ADPaintFrameManager curGroup].curPaintDoc saveInfo];
    [self lockInteraction:false];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{

    [self setPaintDocNameTextFieldRect];
    return YES;
}


#pragma mark- 教程 Tutorial
//主教程入口设置
//主教程入口设置
- (void)tutorialLayout:(ADTutorial*)tutorial{
    ADSimpleTutorial *simpleTutorial = (ADSimpleTutorial *)tutorial;
    [simpleTutorial.cancelView removeFromSuperview];
    simpleTutorial.cancelView.center = CGPointMake(TutorialNextButtonHeight*0.5, self.rootView.bounds.size.height - self.downToolBar.frame.size.height - simpleTutorial.cancelView.frame.size.height);
    simpleTutorial.cancelView.hidden = false;
    [self.rootView addSubview:simpleTutorial.cancelView];
    
}

- (void)tutorialSetup{
    DebugLogFuncStart(@"tutorialSetup");
    if (![[ADSimpleTutorialManager current] isActive]) {
        return;
    }
    
    for (ADSimpleTutorial *tutorial in [ADSimpleTutorialManager current].tutorials.objectEnumerator) {
        tutorial.curViewController = self;
        for (ADTutorialStep *step in tutorial.steps) {
            if ([step.name rangeOfString:@"CylinderProject"].length > 0) {
                step.delegate = self;
            }
        }
    }
    
    [self tutorialLayout:[ADSimpleTutorialManager current].curTutorial];
}

//在排版等准备完成以后,检查是否需要开始教程
- (void)tutorialStartCurrentStep{
    DebugLogFuncStart(@"tutorialStartCurrentStep");
    if (![[ADSimpleTutorialManager current] isActive]) {
        return;
    }
    
    [[ADSimpleTutorialManager current].curTutorial startCurrentStep];
}

- (void)tutorialStartFromStepName:(NSString *)name{
    DebugLogFuncStart(@"tutorialStartFromStepName %@", name);
    if (![[ADSimpleTutorialManager current] isActive]) {
        return;
    }
    
    if ([[ADSimpleTutorialManager current].curTutorial.curStep.name isEqualToString:name]) {
        [[ADSimpleTutorialManager current].curTutorial startFromStepName:name];
    }
}

- (void)tutorialStepNextImmediate:(BOOL)immediate{
    DebugLogFuncStart(@"tutorialStepNext");
    if (![[ADSimpleTutorialManager current] isActive]) {
        return;
    }
    
   //isCheckTutorialStep
    if (immediate) {
        [[ADSimpleTutorialManager current].curTutorial stepNextImmediate];
    }
    else{
        [[ADSimpleTutorialManager current].curTutorial stepNext:nil];
    }


}
#pragma mark- 教程步骤代理 TutorialStepDelegate
- (void)willTutorialEnableUserInteraction:(BOOL)enable withStep:(ADTutorialStep *)step{
    DebugLogFuncStart(@"willTutorialEnableUserInteraction");
    //需要关闭所有其他工具交互
    for (UIButton *button in self.downTooBarButtons) {
        button.userInteractionEnabled = enable;
    }
    for (UIButton *button in self.allUserInputParamButtons) {
        button.userInteractionEnabled = enable;
    }
    for (UIButton *button in self.setupCylinderRefObjButtons) {
        button.userInteractionEnabled = enable;
    }
    self.setupCylinderRefBackButton.userInteractionEnabled = enable;
    self.valueSlider.userInteractionEnabled = enable;
    self.projectView.userInteractionEnabled = enable;
    self.paintDocNameTextField.userInteractionEnabled = enable;
    
    //打开制定按钮交互
    if ([step.name isEqualToString:@"CylinderProjectNextImage"] ||
        [step.name isEqualToString:@"CylinderProjectPreviousImage"]) {
        self.projectView.userInteractionEnabled = true;
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetup"]) {
        self.setupButton.userInteractionEnabled = true;
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupScene"]) {
        self.setupCylinderButton.userInteractionEnabled = true;
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupSceneDone"]) {
        self.setupCylinderRefPenButton.userInteractionEnabled = true;
    }
    if ([step.name isEqualToString:@"CylinderProjectPutDevice"]) {
        self.topPerspectiveView.userInteractionEnabled = true;
    }
    else if ([step.name isEqualToString:@"CylinderProjectViewDevice"]) {
        self.eyePerspectiveView.userInteractionEnabled = true;
    }
    else if ([step.name isEqualToString:@"CylinderProjectTutorialDone"]) {
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupCylinderDiameter"]) {
        self.cylinderDiameterButton.userInteractionEnabled = true;
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupCylinderHeight"]) {
        self.cylinderHeightButton.userInteractionEnabled = true;
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupImageWidth"]) {
        self.imageWidthButton.userInteractionEnabled = true;
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupImageCenter"]) {
        self.imageHeightButton.userInteractionEnabled = true;
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupEyeZoom"]) {
        self.eyeZoomButton.userInteractionEnabled = true;
    }
//    else if ([step.name isEqualToString:@"CylinderProjectSetupEyeHeight"]) {
//        self.eyeHeightButton.userInteractionEnabled = true;
//    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupZoom"] ||
             [step.name isEqualToString:@"CylinderProjectSetupZoomFixDisplay"]) {
        self.projectZoomButton.userInteractionEnabled = true;
    }
    else if ([step.name isEqualToString:@"CylinderProjectTopViewForZoom"]) {
        self.topPerspectiveView.userInteractionEnabled = true;
    }
    else if ([step.name isEqualToString:@"CylinderProjectSideViewForEye"]) {
        self.eyePerspectiveView.userInteractionEnabled = true;
    }
    else if ([step.name isEqualToString:@"CylinderProjectSideViewAfterDraw"]) {
        self.eyePerspectiveView.userInteractionEnabled = true;
    }
    else if ([step.name isEqualToString:@"CylinderProjectCloseSetup"]) {
        self.setupButton.userInteractionEnabled = true;
    }
//    else if ([step.name isEqualToString:@"CylinderProjectCloseSetupSave"]) {
        //关闭alertView的dont save
//        UIButton *cancelButton = self.saveAlertView.subviews[0];
//        cancelButton.userInteractionEnabled = false;
//    }
    else if ([step.name isEqualToString:@"CylinderProjectTopViewForPaint"]) {
        self.topPerspectiveView.userInteractionEnabled = true;
    }
    else if ([step.name isEqualToString:@"CylinderProjectSideViewForPaint"]) {
        self.eyePerspectiveView.userInteractionEnabled = true;
    }
    else if ([step.name isEqualToString:@"CylinderProjectPaint"]) {
        self.paintButton.userInteractionEnabled = true;
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupCylinderDiameterValue"] ||
             [step.name isEqualToString:@"CylinderProjectSetupCylinderHeightValue"] ||
             [step.name isEqualToString:@"CylinderProjectSetupImageWidthValue"] ||
             [step.name isEqualToString:@"CylinderProjectSetupImageCenterValue"] ||
             [step.name isEqualToString:@"CylinderProjectSetupEyeZoomValue"] ||
//             [step.name isEqualToString:@"CylinderProjectSetupEyeDistanceValue"] ||
//             [step.name isEqualToString:@"CylinderProjectSetupEyeHeightValue"] ||
             [step.name isEqualToString:@"CylinderProjectSetupZoomValue"] ||
             [step.name isEqualToString:@"CylinderProjectSetupZoomFixDisplayValue"])
    {
        self.valueSlider.userInteractionEnabled = true;
    }
}

- (void)willTutorialLayoutWithStep:(ADTutorialStep *)step{
    DebugLogFuncStart(@"willLayoutWithStep");
    
    if ([step.name isEqualToString:@"CylinderProjectNextImage"] ||
        [step.name isEqualToString:@"CylinderProjectPreviousImage"]) {
        CGRect mirrorRect = [self willGetCylinderMirrorFrame];
        mirrorRect.origin.y += 200;
        [step.indicatorView targetViewFrame:mirrorRect inRootView:self.rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetup"]) {
        [step.indicatorView targetView:self.setupButton inRootView:self.rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupScene"]) {
        CGRect frame = self.setupCylinderButton.frame;
        frame.origin.x += 5;
        [step.indicatorView targetViewFrame:frame inRootView:self.rootView];
//        [step.indicatorView targetView:self.setupCylinderButton inRootView:rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupSceneDone"]) {
        [step.indicatorView targetView:self.setupCylinderRefPenButton inRootView:self.rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectPutDevice"]) {

        
        [step.indicatorView targetView:self.topPerspectiveView inRootView:self.rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectViewDevice"]) {

        [step.indicatorView targetView:self.eyePerspectiveView inRootView:self.rootView];
        
        ADTutorialIndicatorView *indicatorView = (ADTutorialIndicatorView *)step.indicatorViews[1];
        CGRect mirrorRect = [self willGetCylinderMirrorFrame];
        mirrorRect.origin.y += 100;
        [indicatorView targetViewFrame:mirrorRect inRootView:self.rootView];

        __weak ADTutorialIndicatorView * weakIndicatorView = indicatorView;
        [indicatorView setLayoutCompletionBlock:^{
            CGRect frame = weakIndicatorView.textLabel.frame;
            frame.origin.y = 100;
            weakIndicatorView.textLabel.frame = frame;
        }];
            
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupCylinderDiameter"]) {
        [step.indicatorView targetView:self.cylinderDiameterButton inRootView:self.rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupCylinderDiameterValue"]) {
        CGRect thumbRect = [self.valueSlider convertRect:self.valueSlider.thumbRect toView:self.rootView];
        [step.indicatorView targetViewFrame:thumbRect inRootView:self.rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupCylinderHeight"]) {
        [step.indicatorView targetView:self.cylinderHeightButton inRootView:self.rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupCylinderHeightValue"]) {
        CGRect thumbRect = [self.valueSlider convertRect:self.valueSlider.thumbRect toView:self.rootView];
        [step.indicatorView targetViewFrame:thumbRect inRootView:self.rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupImageWidth"]) {
        [step.indicatorView targetView:self.imageWidthButton inRootView:self.rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupImageWidthValue"]) {
//        CGRect thumbRect = [self.valueSlider convertRect:self.valueSlider.thumbRect toView:rootView];
//        [step.indicatorView targetViewFrame:thumbRect inRootView:rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupImageCenter"]) {
        [step.indicatorView targetView:self.imageHeightButton inRootView:self.rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupImageCenterValue"]) {
//        CGRect thumbRect = [self.valueSlider convertRect:self.valueSlider.thumbRect toView:rootView];
//        [step.indicatorView targetViewFrame:thumbRect inRootView:rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupEyeZoom"]) {
        [step.indicatorView targetView:self.eyeZoomButton inRootView:self.rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupEyeZoomValue"]) {
//        CGRect thumbRect = [self.valueSlider convertRect:self.valueSlider.thumbRect toView:rootView];
//        [step.indicatorView targetViewFrame:thumbRect inRootView:rootView];
    }
//    else if ([step.name isEqualToString:@"CylinderProjectSetupEyeDistance"]) {
//        [step.indicatorView targetView:self.eyeDistanceButton inRootView:rootView];
//    }
//    else if ([step.name isEqualToString:@"CylinderProjectSetupEyeDistanceValue"]) {
//        CGRect thumbRect = [self.valueSlider convertRect:self.valueSlider.thumbRect toView:rootView];
//        [step.indicatorView targetViewFrame:thumbRect inRootView:rootView];
//    }
//    else if ([step.name isEqualToString:@"CylinderProjectSetupEyeHeight"]) {
//        [step.indicatorView targetView:self.eyeHeightButton inRootView:rootView];
//    }
//    else if ([step.name isEqualToString:@"CylinderProjectSetupEyeHeightValue"]) {
//        CGRect thumbRect = [self.valueSlider convertRect:self.valueSlider.thumbRect toView:rootView];
//        [step.indicatorView targetViewFrame:thumbRect inRootView:rootView];
//    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupZoom"] ||
             [step.name isEqualToString:@"CylinderProjectSetupZoomFixDisplay"]) {
        [step.indicatorView targetView:self.projectZoomButton inRootView:self.rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectSetupZoomValue"] ||
            [step.name isEqualToString:@"CylinderProjectSetupZoomFixDisplayValue"]) {
//        CGRect thumbRect = [self.valueSlider convertRect:self.valueSlider.thumbRect toView:rootView];
//        [step.indicatorView targetViewFrame:thumbRect inRootView:rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectSideViewForEye"] ||
            [step.name isEqualToString:@"CylinderProjectSideViewAfterDraw"]) {
        [step.indicatorView targetView:self.eyePerspectiveView inRootView:self.rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectTopViewForZoom"]) {
        [step.indicatorView targetView:self.topPerspectiveView inRootView:self.rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectCloseSetup"]) {
        [step.indicatorView targetView:self.setupButton inRootView:self.rootView];
    }
//    else if ([step.name isEqualToString:@"CylinderProjectCloseSetupSave"]) {
//        CGRect frame = CGRectMake(375, 450, 200, 100);//hard coded
//        [step.indicatorView targetViewFrame:frame inRootView:rootView];
//    }
    else if ([step.name isEqualToString:@"CylinderProjectTopViewForPaint"]) {
        [step.indicatorView targetView:self.topPerspectiveView inRootView:self.rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectSideViewForPaint"]) {
        [step.indicatorView targetView:self.eyePerspectiveView inRootView:self.rootView];
        [step.indicatorViews[1] targetView:self.paintButton inRootView:self.rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectPaint"]) {
        [step.indicatorView targetView:self.paintButton inRootView:self.rootView];
    }
    else if ([step.name isEqualToString:@"CylinderProjectTutorialDone"]) {
        step.contentView.center = CGPointMake(self.rootView.center.x, self.rootView.bounds.size.height - self.downToolBar.frame.size.height - step.contentView.frame.size.height);
        
        UIView *cancelView = ((ADSimpleTutorial*)[ADSimpleTutorialManager current].curTutorial).cancelView;
        [UIView animateWithDuration:TutorialButtonFadeInDuration animations:^{
            cancelView.alpha = 0;
        }completion:^(BOOL finished) {
            ((ADSimpleTutorial*)[ADSimpleTutorialManager current].curTutorial).cancelView.hidden = true;
            cancelView.alpha = 1;
        }];
        
        if(step.indicatorView){
            [step.indicatorView targetView:self.paintButton inRootView:self.rootView];
        }
    }
    
    [step addToRootView:self.rootView];
}


- (void)willTutorialEndWithStep:(ADTutorialStep*)step{
    if ([step.name isEqualToString:@"CylinderProjectTutorialDone"] ||
        [step.name isEqualToString:@"CylinderProjectTutorialDone"]) {
        self.transitioningDelegate = nil;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;        
    }
}

#if UseiAd
#pragma mark- 广告iAd

- (void)createAdBannerView {
    // On iOS 6 ADBannerView introduces a new initializer, use it when available.
    if ([ADBannerView instancesRespondToSelector:@selector(initWithAdType:)]) {
        _bannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
    } else {
        _bannerView = [[ADBannerView alloc] init];
    }
    _bannerView.delegate = self;

    [self.iAdBar addSubview:_bannerView];
//    [self.rootView insertSubview:_bannerView belowSubview:self.topToolBar];
}

#pragma mark- 广告代理ADBannerViewDelegate
- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave{
    [RemoteLog logAction:@"CP_bannerViewActionShouldBegin" identifier:nil];
    
    [ADPaintUIKitAnimation view:rootView switchDownToolBarFromView:self.downToolBar completion:nil];
    [ADPaintUIKitAnimation view:rootView switchTopToolBarFromView:self.iAdBar completion:nil];
    return true;
}
#endif
@end
