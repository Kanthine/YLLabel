//
//  YLCoreText.h
//  YLLabel
//
//  Created by 苏沫离 on 2020/8/18.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "YLModel.h"


UIKIT_EXTERN NSAttributedStringKey const _Nonnull kYLAttributeName;


NS_ASSUME_NONNULL_BEGIN

@interface NSString (YLLabel)
/// 正则搜索相关字符位置
- (NSArray<NSTextCheckingResult *> *)matchesWithPattern:(NSString *)pattern;

@end

@interface YLCoreText : NSObject


/** 获取 CTFrame
 * @param attrString 绘制内容
 * @param rect 绘制区域
 */
CTFrameRef getFrameRefByAttrString(NSAttributedString *attrString, CGRect rect);

/** 获得内容分页列表
 * @param attrString 内容
 * @param rect 显示范围
 */
NSMutableArray<NSValue *> *getPageingRanges(NSAttributedString *attrString, CGRect rect);


/** 获取指定内容高度
 * @param attrString 内容
 * @param maxW 宽度限制
 */
CGFloat getAttrStringHeight(NSAttributedString *attrString,CGFloat maxW);


/// 通过 [CGRect] 获得合适的 MenuRect
///
/// - Parameter rects: [CGRect]
/// - Parameter viewFrame: 目标ViewFrame
/// - Returns: MenuRect
CGRect getMenuRect(NSArray<NSValue *> *rects,CGRect viewFrame);


/** 获取触摸位置在哪一行
 * @param point 触摸点
 * @param frameRef
 */
CTLineRef getTouchLine(CGPoint point,CTFrameRef frameRef);


/** 获得触摸位置那一行文字的Range
 * @param point 触摸点
 * @param frameRef
 */
NSRange getTouchLineRange(CGPoint point,CTFrameRef frameRef);


/** 获得触摸位置文字的Location
 * @param point 触摸点
 * @param frameRef
 */
signed long getTouchLocation(CGPoint point,CTFrameRef frameRef);

/// 通过 range 返回字符串所覆盖的位置 [CGRect]
///
/// - Parameter range: NSRange
/// - Parameter frameRef: CTFrame
/// - Parameter content: 内容字符串(有值则可以去除选中每一行区域内的 开头空格 - 尾部换行符 - 所占用的区域,不传默认返回每一行实际占用区域)
/// - Returns: 覆盖位置
NSMutableArray<NSValue *> *getRangeRects_0(NSRange range,CTFrameRef frameRef);
NSMutableArray<NSValue *> *getRangeRects(NSRange range,CTFrameRef frameRef,NSString *content);

@end


///分页
@interface YLCoreText (Page)

/** 处理文本
 * 将原文本的 图片、链接转为 待处理格式
 */
void handleAttrString(NSMutableAttributedString *attrString, CGRect rect);


/** 将内容分为多页
 * @param attrString 展示的内容
 * @prama rect 显示范围
 */
NSMutableArray<YLPageModel *> *pageingWithAttrString(NSMutableAttributedString *attrString, CGRect rect);

@end



@interface YLCoreText (ImageHandler)

+ (void)setImageFrametWithCTFrame:(CTFrameRef)frame;

+ (NSAttributedString *)parseImageFromeTextWithURL:(NSString *)url drawSize:(CGSize)drawSize;

@end


NS_ASSUME_NONNULL_END
