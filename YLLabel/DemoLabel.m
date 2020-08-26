//
//  DemoLabel.m
//  YLLabel
//
//  Created by 苏沫离 on 2020/8/25.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "DemoLabel.h"

@implementation DemoLabel

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.whiteColor;

        [self setNeedsDisplay];
    }
    return self;
}

/// 绘制
- (void)drawRect:(CGRect)rect{
     //1.获取当前绘图上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //2.旋转坐坐标系(默认和UIKit坐标是相反的)
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);//设置当前文本矩阵
    CGContextTranslateCTM(context, 0, CGRectGetHeight(rect));//文本沿y轴移动
    CGContextScaleCTM(context, 1.0, -1.0);//文本翻转成为CoreText坐标系
    
    NSString *string = @"The 1896 Cedar Keys hurricane was a powerful tropical cyclone that devastated much of the East Coast of the United States, starting with Florida's Cedar Keys, near the end of September. The storm's rapid movement allowed it to maintain much of its intensity after landfall, becoming one of the costliest United States hurricanes at the time. ";
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName: [UIFont fontWithName:@"PingFang SC" size:15],NSForegroundColorAttributeName: [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0]}];
    
    CTTypesetterRef typesetterRef = CTTypesetterCreateWithAttributedString((CFAttributedStringRef)attributedString);///排版类
    
    CFIndex start = 0;
    CGPoint textPosition = CGPointMake(0, 55);
    double width = CGRectGetWidth(self.bounds);
    width = 200;
    double height = CGRectGetHeight(self.bounds);
    
    BOOL isCharLineBreak = YES;//断行：是否断字符
    BOOL isJustifiedLine = NO; //两端对齐：填充空白符，文字之间等间距
    float flush = 0.5;//对齐：0 是左对齐，1 是右对齐，0.5 居中
    while (start < string.length) {
       CFIndex count;
       if (isCharLineBreak) {
           count = CTTypesetterSuggestClusterBreak(typesetterRef, start, width);
       }else {
           count = CTTypesetterSuggestLineBreak(typesetterRef, start, width);
       }
       CTLineRef line = CTTypesetterCreateLine(typesetterRef, CFRangeMake(start, count));
       if (isJustifiedLine) {
           line = CTLineCreateJustifiedLine(line, 1, width);
       }
       double penOffset = CTLineGetPenOffsetForFlush(line, flush, width);
       CGContextSetTextPosition(context, textPosition.x + penOffset, height - textPosition.y);
       CTLineDraw(line, context);
       textPosition.y += CTLineGetBoundsWithOptions(line, 0).size.height;
       start += count;
    }
}

@end
