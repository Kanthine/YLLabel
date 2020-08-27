//
//  YLLabel.m
//  YLLabel
//
//  Created by 苏沫离 on 2020/8/18.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "YLLabel.h"

@implementation YLLabel

- (void)dealloc{
    if (_frameRef) {
        CFRelease(_frameRef);
    }
}

- (instancetype)init{
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;

        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerClick:)];
        [self addGestureRecognizer:tapRecognizer];
    }
    return self;
}

- (void)tapGestureRecognizerClick:(UITapGestureRecognizer *)tapRecognizer{
    CGPoint point = [tapRecognizer locationInView:self];
    YLAttachment *attachment = getTouchAttachment(point, _frameRef);
    if (attachment && attachment.url) {
         if (self.delegate && [self.delegate respondsToSelector:@selector(touchYLLabel:url:)]) {
             [self.delegate touchYLLabel:self url:attachment.url];
         }
     }
}


/// 绘制
- (void)drawRect:(CGRect)rect{
    if (_frameRef == nil) {
        return;
    }
     //1.获取当前绘图上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //2.旋转坐坐标系(默认和UIKit坐标是相反的)
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);//设置当前文本矩阵
    CGContextTranslateCTM(context, 0, CGRectGetHeight(rect));//文本沿y轴移动
    CGContextScaleCTM(context, 1.0, -1.0);//文本翻转成为CoreText坐标系
    
    //3.绘制文字
    CTFrameDraw(_frameRef, context);
    
    //4.绘制图片
    [[YLCoreText getImagesWithCTFrame:_frameRef] enumerateObjectsUsingBlock:^(YLAttachment * _Nonnull attachment, NSUInteger idx, BOOL * _Nonnull stop) {
        CGContextDrawImage(context, attachment.imageFrame, attachment.image.CGImage);
    }];
}

- (void)setFrameRef:(CTFrameRef)frameRef{
    if (_frameRef) {
        CFRelease(_frameRef);
    }
    _frameRef = frameRef;
    CFRetain(frameRef);
    if (frameRef) {
        [self setNeedsDisplay];
    }
}

@end
