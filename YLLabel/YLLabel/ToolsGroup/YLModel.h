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

UIKIT_EXTERN NSAttributedStringKey const _Nonnull kYLAttachmentAttributeName;

NS_ASSUME_NONNULL_BEGIN

//富文本中的链接（图片、网页）
@interface YLAttachment : NSObject

//链接
@property (nonatomic ,copy) NSString *url;

//网页的标题
@property (nonatomic ,copy) NSString *title;

//图片的相关信息
@property (nonatomic ,strong) UIImage *image;
@property (nonatomic ,assign) CGRect imageFrame;

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


