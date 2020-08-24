//
//  YLModel.h
//  YLLabel
//
//  Created by 苏沫离 on 2020/8/19.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

NS_ASSUME_NONNULL_BEGIN


//CoreText实际上并没有相应API直接将一个图片转换为CTRun并进行绘制，它所能做的只是为图片预留响应的空白区域，而真正的绘制则是交由CoreGraphics完成。
@interface YLImage : NSObject

@property (nonatomic ,strong) UIImage *image;
@property (nonatomic ,copy) NSString *url;
@property (nonatomic ,assign) CGRect imageFrame;

@end

@interface YLWeb : NSObject

@property (nonatomic ,copy) NSString *title;
@property (nonatomic ,copy) NSString *url;
@property (nonatomic ,assign) NSRange range;

@end

@interface YLPageModel : NSObject

/// 当前页富文本
@property (nonatomic, strong) NSAttributedString *content;
/// 当前页码
@property (nonatomic, assign) NSInteger page;
/// 当前页文字范围
@property (nonatomic, assign) NSRange range;
/// 当前页 CTFrame
@property (nonatomic ,assign) CTFrameRef frameRef;
/// 当前页高度
@property (nonatomic, assign) CGFloat contentHeight;

@end

NS_ASSUME_NONNULL_END


