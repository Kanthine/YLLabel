//
//  YLLabel.m
//  YLLabel
//
//  Created by 苏沫离 on 2020/8/18.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "YLLabel.h"

@interface YLLabel ()
{
    UITapGestureRecognizer *_tapGestureRecognizer;
}
@property (nonatomic ,assign) BOOL isTap;

@end

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
        
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerClick:)];
        [self addGestureRecognizer:_tapGestureRecognizer];
    }
    return self;
}

//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer{
//    if ([gestureRecognizer isKindOfClass:UITapGestureRecognizer.class] &&
//        [gestureRecognizer isEqual:_tapGestureRecognizer]) {
//        CGPoint touchPoint = [_tapGestureRecognizer locationInView:self];
//        YLAttachment *attachment = getTouchAttachment(touchPoint, _frameRef);
//        if (attachment && attachment.url) {
//            return YES;
//        }
//    }
//    return NO;
//}

//- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
//    if (!_isTap && self.delegate && [self.delegate respondsToSelector:@selector(touchYLLabel:url:)]) {
//        _isTap = YES;
//        YLAttachment *attachment = getTouchAttachment(point, _frameRef);
//        if (attachment && attachment.url) {
//            [self.delegate touchYLLabel:self url:attachment.url];
//        }
//
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            self->_isTap = NO;
//        });
//    }
//    return [super hitTest:point withEvent:event];
//}

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
