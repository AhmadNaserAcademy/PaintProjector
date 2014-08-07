//
//  TutorialView.m
//  PaintProjector
//
//  Created by 胡 文杰 on 6/15/14.
//  Copyright (c) 2014 WenjiHu. All rights reserved.
//

#import "ADTutorialView.h"

@implementation ADTutorialView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self initCustom];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        [self initCustom];
    }
    return self;
}

- (void)initCustom{
//    self.textLabelAutoLayout = true;
}
//决定tutorialView下的nextButton是内置的button，还是界面上的某个button,
//如果是界面上的某个button,加上事件后,在dealloc tutorialView后需要移除这个事件
- (void)initWithTutorial:(ADTutorial*)tutorial description:(NSString *)desc bgImage:(UIImage*)image{
    self.delegate = tutorial;
    
    if (desc) {
        UILabel *label = [[UILabel alloc]init];
        self.textLabel = label;
        label.textColor = [UIColor darkGrayColor];
        label.text = desc;
        [label setNumberOfLines:10];
        [label setLineBreakMode:NSLineBreakByTruncatingTail];

        [self addSubview:label];
        [self setNeedsLayout];
        
    }
    if (image) {
        UIImageView *imageView = [[UIImageView alloc]initWithImage:image];
        self.imageView = imageView;

        [self addSubview:imageView];
        [self sendSubviewToBack:imageView];
    }
}

- (void)layoutSubviews{
    CGRect frame = self.imageView.frame;
    frame.size = self.frame.size;
    self.imageView.frame = frame;
    
    if (self.layoutCompletionBlock) {
        self.layoutCompletionBlock();
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
