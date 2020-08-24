//
//  YLCoreText.m
//  YLLabel
//
//  Created by 苏沫离 on 2020/8/18.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "YLCoreText.h"


NSAttributedStringKey const kYLAttributeName = @"com.yl.attribute";

NSString * const kYLImageLinkRegula = @"(?<=\\<ImageLink:).*?(?=\\>)";
NSString * const kYLWebLinkRegula = @"(?<=\\<WebLink:).*?(?=\\>)";


@implementation NSString (YLLabel)

/// 正则搜索相关字符位置
- (NSArray<NSTextCheckingResult *> *)matchesWithPattern:(NSString *)pattern{
    if (self.length < 1) {return @[];}
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    return [regularExpression matchesInString:self options:NSMatchingReportProgress range:NSMakeRange(0, self.length)];
}

@end


@implementation YLCoreText

/** 获取 CTFrame
 * @param attrString 绘制内容
 * @param rect 绘制区域
 */
CTFrameRef getCTFrameWithAttrString(NSAttributedString *attrString, CGRect rect){
    CGPathRef path = CGPathCreateWithRect(rect, nil);///绘制局域
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attrString);//设置绘制内容
    CTFrameRef frameRef = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil);
    CFRelease(framesetter);
    CGPathRelease(path);
    return frameRef;
}

/// 通过 [CGRect] 获得合适的 MenuRect
///
/// - Parameter rects: [CGRect]
/// - Parameter viewFrame: 目标ViewFrame
/// - Returns: MenuRect
CGRect getMenuRect(NSArray<NSValue *> *rects,CGRect viewFrame){
    CGRect menuRect = CGRectZero;
    if (rects.count < 1) {
        return menuRect;
    }
    menuRect = rects.firstObject.CGRectValue;

    if (rects.count > 1) {
        NSInteger count = rects.count;
        
        for (int i = 0; i < count; i++) {
            CGRect rect = rects[i].CGRectValue;
            
            CGFloat minX = MIN(menuRect.origin.x, rect.origin.x);
            CGFloat maxX = MAX(menuRect.origin.x + menuRect.size.width, rect.origin.x + rect.size.width);
            CGFloat minY = MIN(menuRect.origin.y, rect.origin.y);
            CGFloat maxY = MAX(menuRect.origin.y + menuRect.size.height, rect.origin.y + rect.size.height);
            
            menuRect.origin.x = minX;
            menuRect.origin.y = minY;
            menuRect.size.width = maxX - minX;
            menuRect.size.height = maxY - minY;
        }
    }
    menuRect.origin.y = viewFrame.size.height - menuRect.origin.y - menuRect.size.height;
    return menuRect;
}




/// 通过 range 返回字符串所覆盖的位置 [CGRect]
///
/// - Parameter range: NSRange
/// - Parameter frameRef: CTFrame
/// - Parameter content: 内容字符串(有值则可以去除选中每一行区域内的 开头空格 - 尾部换行符 - 所占用的区域,不传默认返回每一行实际占用区域)
/// - Returns: 覆盖位置
NSMutableArray<NSValue *> *getRangeRects_0(NSRange range,CTFrameRef frameRef){
    return getRangeRects(range, frameRef,nil);
}

NSMutableArray<NSValue *> *getRangeRects(NSRange range,CTFrameRef frameRef,NSString *content){
    NSMutableArray<NSValue *> *rects = [NSMutableArray array];
    if (frameRef == nil) { return rects; }
    if (range.length == 0 || range.location == NSNotFound) { return rects; }
    
    CFArrayRef lines = CTFrameGetLines(frameRef);
    int lineCount = (int)CFArrayGetCount(lines);
    
    if (lineCount < 1) {

        return rects;
    }
    
    CGPoint origins[lineCount];
    for (int i = 0; i < lineCount; i++) {
        origins[i] = CGPointZero;
    }
    CTFrameGetLineOrigins(frameRef, CFRangeMake(0, 0), origins);
    
    for (int i = 0; i < lineCount; i ++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CFRange lineCFRange = CTLineGetStringRange(line);
        NSRange lineRange = NSMakeRange(lineCFRange.location == kCFNotFound ? NSNotFound : lineCFRange.location, lineCFRange.length);
        NSRange contentRange = NSMakeRange(NSNotFound, 0);
        
        if ((lineRange.location + lineRange.length) > range.location &&
            lineRange.location < (range.location + range.length)) {
            contentRange.location = MAX(lineRange.location, range.location);
            CGFloat end = MIN(lineRange.location + lineRange.length, range.location + range.length);
            contentRange.length = end - contentRange.location;
        }
        
        if (contentRange.length > 0) {
            
            // 去掉 -> 开头空格 - 尾部换行符 - 所占用的区域
            if (content.length > 0) {
                NSString *tempContent = [content substringWithRange:contentRange];
                NSArray<NSTextCheckingResult *> *spaceRanges = [tempContent matchesWithPattern:@"\\s\\s"];
                if (spaceRanges.count) {
                    NSRange spaceRange = spaceRanges.firstObject.range;
                    contentRange = NSMakeRange(contentRange.location + spaceRange.length, contentRange.length - spaceRange.length);
                }
                NSArray<NSTextCheckingResult *> *enterRanges = [tempContent matchesWithPattern:@"\\n"];
                if (enterRanges.count) {
                    NSRange enterRange = enterRanges.firstObject.range;
                    contentRange = NSMakeRange(contentRange.location, contentRange.length - enterRange.length);
                }
            }
            
            // 正常使用(如果不需要排除段头空格跟段尾换行符可将上面代码删除)
            
            CGFloat xStart = CTLineGetOffsetForStringIndex(line, contentRange.location, nil);
            CGFloat xEnd = CTLineGetOffsetForStringIndex(line, contentRange.location + contentRange.length, nil);
            CGPoint origin = origins[i];
            CGFloat lineAscent = 0;
            CGFloat lineDescent = 0;
            CGFloat lineLeading = 0;
            CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
            
            CGRect contentRect = CGRectMake(origin.x + xStart, origin.y - lineDescent, fabs(xEnd - xStart),lineAscent + lineDescent + lineLeading);
            [rects addObject:[NSValue valueWithCGRect:contentRect]];
        }
    }
    return rects;
}

void handleAttrString(NSMutableAttributedString *attrString, CGRect rect){
    NSString *string = [attrString.string copy];
    NSString *regula = [NSString stringWithFormat:@"%@|%@",kYLImageLinkRegula,kYLWebLinkRegula];
    NSError *error;
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:regula options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray<NSTextCheckingResult *> *matches = [regularExpression matchesInString:string options:0 range:NSMakeRange(0, [string length])];
    
    if (matches.count) {
        [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
               NSString *matchString = [string substringWithRange:obj.range];
               NSString *imageFormat = [NSString stringWithFormat:@"<ImageLink:%@>",matchString];//图片格式
               NSString *webFormat = [NSString stringWithFormat:@"<WebLink:%@>",matchString];//网页格式

               if ([string containsString:imageFormat]) {
                   //文字中插入的图片
                   NSRange subAllRange = [attrString.string rangeOfString:imageFormat];//在修改后的文本中查找替代的位置
                   [attrString replaceCharactersInRange:subAllRange withAttributedString:[YLCoreText parseImageFromeTextWithURL:matchString drawSize:rect.size]];
               }else if ([string containsString:webFormat]) {
                   //文字中插入的链接
                   NSRange subAllRange = [attrString.string rangeOfString:webFormat];//在修改后的文本中查找替代的位置
                   NSArray *itemArray = [matchString componentsSeparatedByString:@","];
                   
                   YLWeb *web = [[YLWeb alloc] init];
                   [itemArray enumerateObjectsUsingBlock:^(NSString * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
                       NSArray *itemDict = [item componentsSeparatedByString:@"="];
                       NSString *key = itemDict.firstObject;
                       NSString *value = itemDict.lastObject;
                       if ([key isEqualToString:@"link"]) {
                           web.url = value;
                       }else if ([key isEqualToString:@"title"]){
                           web.title = value;
                       }
                   }];
                   NSLog(@"webFormat === %@",matchString);
                                      
                   [attrString replaceCharactersInRange:subAllRange withAttributedString:[[NSAttributedString alloc]initWithString:web.title attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:UIColor.redColor,kYLAttributeName:web}]];
               }
           }];
    }
}

@end







@implementation YLCoreText (Page)

/** 根据页面 rect 将文本分页
 * @param attrString 内容
 * @param rect 显示范围
 * @return 返回每页需要展示的 Range
 */
NSMutableArray<NSValue *> *getPageRanges(NSAttributedString *attrString, CGRect rect){
    NSMutableArray *rangeArray = [NSMutableArray array];
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attrString);
    CGPathRef path = CGPathCreateWithRect(rect, nil);
    CFRange range = CFRangeMake(0, 0);
    NSInteger rangeOffset = 0;
    do {
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(rangeOffset, 0), path, nil);
        range = CTFrameGetVisibleStringRange(frame);
        [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(rangeOffset, range.length)]];
        CFRelease(frame);
        rangeOffset += range.length;
    } while (range.location + range.length < attrString.length);
    CFRelease(framesetter);
    CGPathRelease(path);
    return rangeArray;
}

/** 将内容分为多页
 * @param attrString 展示的内容
 * @prama rect 显示范围
 */
NSMutableArray<YLPageModel *> * getPageModels(NSMutableAttributedString *attrString, CGRect rect){
    NSMutableArray<YLPageModel *> *pageModels = [NSMutableArray array];

    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attrString);
    CGPathRef path = CGPathCreateWithRect(rect, nil);
    CFRange range = CFRangeMake(0, 0);
    NSInteger rangeOffset = 0;
    do {
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(rangeOffset, 0), path, nil);
        range = CTFrameGetVisibleStringRange(frame);/// 获取实际填充 CTFrameRef 的字符范围
                
        YLPageModel *pageModel = [[YLPageModel alloc]init];
        pageModel.range = NSMakeRange(rangeOffset, range.length);
        pageModel.content = [attrString attributedSubstringFromRange:pageModel.range];;
        pageModel.page = pageModels.count;
        pageModel.frameRef = frame;
        [YLCoreText setImageFrametWithCTFrame:pageModel.frameRef];
        pageModel.contentHeight = getHeightWithCTFrame(pageModel.frameRef);
        [pageModels addObject:pageModel];
        
        rangeOffset += range.length;
    } while (range.location + range.length < attrString.length);
    CFRelease(framesetter);
    CGPathRelease(path);
    
    return pageModels;
}

///每页的 CTFrame 高度自适应内容
NSMutableArray<YLPageModel *> *getPageModelsAutoHeight(NSMutableAttributedString *attrString, CGRect rect){
    NSMutableArray<YLPageModel *> *pageModels = [NSMutableArray array];

    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attrString);
    CGPathRef path = CGPathCreateWithRect(rect, nil);
    CFRange range = CFRangeMake(0, 0);
    NSInteger rangeOffset = 0;
    do {
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(rangeOffset, 0), path, nil);
        range = CTFrameGetVisibleStringRange(frame);/// 获取实际填充 CTFrameRef 的字符范围
        
        
        YLPageModel *pageModel = [[YLPageModel alloc]init];
        pageModel.range = NSMakeRange(rangeOffset, range.length);
        pageModel.content = [attrString attributedSubstringFromRange:pageModel.range];;
        pageModel.page = pageModels.count;
        
        [YLCoreText setImageFrametWithCTFrame:frame];
        pageModel.contentHeight = getHeightWithCTFrame(frame);
                
        if (fabs(CGRectGetHeight(rect) - pageModel.contentHeight) < 10) {
            pageModel.frameRef = frame;
        }else{
            pageModel.frameRef = getCTFrameWithAttrString(pageModel.content, CGRectMake(0, 0, CGRectGetWidth(rect), pageModel.contentHeight));
            [YLCoreText setImageFrametWithCTFrame:pageModel.frameRef];
        }
        [pageModels addObject:pageModel];
        
        
        rangeOffset += range.length;
    } while (range.location + range.length < attrString.length);
    CFRelease(framesetter);
    CGPathRelease(path);
    return pageModels;
}

@end

/// 获取高度
@implementation YLCoreText (ContentHeight)

/** 获取 CTFrameRef 的内容高度
 * @note CTFrameRef 的坐标系是以左下角为原点
 */
CGFloat getHeightWithCTFrame(CTFrameRef frameRef){
    
    CFArrayRef lines = CTFrameGetLines(frameRef);
    int lineCount = (int)CFArrayGetCount(lines);
    
    CGPoint origins[lineCount];//以左下角为原点的坐标系
    for (int i = 0; i < lineCount; i++) {
        origins[i] = CGPointZero;
    }
    CTFrameGetLineOrigins(frameRef, CFRangeMake(0, 0), origins);
    
    CGPoint point = origins[lineCount - 1];//最后一行的 point.y 是最小值
    CGFloat lineAscent = 0;  //上行高度
    CGFloat lineDescent = 0; //下行高度
    CGFloat lineLeading = 0; //行距
    CTLineRef line = CFArrayGetValueAtIndex(lines, lineCount - 1);
    CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
    
    /// 获取该页面的高度 pageHeight
    CGPathRef path = CTFrameGetPath(frameRef);
    CGRect bounds = CGPathGetBoundingBox(path);
    CGFloat pageHeight = CGRectGetHeight(bounds);
    
    /// 空白高度 = point.y 是最小值 - 下行高度 - 行距
    /// 内容高度 = 页面高度 - 空白高度
    return pageHeight - (point.y - ceil(lineDescent) - lineLeading);
}

/** 获取指定内容高度
 * @param attrString 内容
 * @param widthLimit 宽度限制
 */
CGFloat getHeightWithAttributedString(NSAttributedString *attrString,CGFloat widthLimit){
    CGFloat height = 0;
    if (attrString.length > 0){
        // 注意设置的高度必须大于文本高度
        CGRect drawingRect = CGRectMake(0, 0, widthLimit, 1000);
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attrString);
        CGPathRef path = CGPathCreateWithRect(drawingRect, nil);
        CTFrameRef frameRef = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil);
        height = getHeightWithCTFrame(frameRef);
        
        /// 释放资源
        CFRelease(framesetter);
        CGPathRelease(path);
        CFRelease(frameRef);
    }
    return height;
}

@end

@implementation YLCoreText (ImageHandler)

/** 矫正 CTFrame 中的图片坐标
 * 思路： 遍历 CTFrameRef 中的所有 CTRun，检查 CTRun 否绑定图片，
 *       如果是，根据 CTRun 所在 CTLine 的 origin 以及在 CTLine 中的横向偏移量计算出 CTRun 的原点，
 *       加上其尺寸即为该CTRun的尺寸
 */
+ (void)setImageFrametWithCTFrame:(CTFrameRef)frame{
    CFArrayRef lines = CTFrameGetLines(frame);
    int lineCount = (int)CFArrayGetCount(lines);
    CGPoint points[lineCount];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), points);
    for (int i = 0; i < lineCount; i ++) {//外层for循环，为了取到所有的 CTLine
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        
        CFArrayRef glyphRuns = CTLineGetGlyphRuns(line);
        int runCount = (int)CFArrayGetCount(glyphRuns);
        for (int j = 0; j < runCount ; j ++) {//内层for循环，检查每个 CTRun
            CTRunRef run = CFArrayGetValueAtIndex(glyphRuns, j);
            CFDictionaryRef attributes = CTRunGetAttributes(run);
            CTRunDelegateRef delegate = CFDictionaryGetValue(attributes, kCTRunDelegateAttributeName);;//获取代理属性
            if (delegate == nil) {
                continue;
            }
            YLImage *model = CTRunDelegateGetRefCon(delegate);
            if (![model isKindOfClass:[YLImage class]]) {
                continue;
            }
            
            CGPoint linePoint = points[i];//获取当前 CTLine 的原点
            CGFloat ascent;  //上行高度
            CGFloat descent; //下行高度
            CGFloat leading = 0; //行距
            CGRect boundsRun;
            //获取宽、高
            boundsRun.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, &leading);
            boundsRun.size.height = ascent + fabs(descent) + leading;
            //获取对应 CTRun 的 X 偏移量
            CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
            boundsRun.origin.x = linePoint.x + xOffset;
            boundsRun.origin.y = linePoint.y - descent - leading;//图片原点
            CGPathRef path = CTFrameGetPath(frame);//获取绘制区域
            CGRect colRect = CGPathGetBoundingBox(path);//获取绘制区域边框
            model.imageFrame = CGRectOffset(boundsRun, colRect.origin.x, colRect.origin.y);//设置图片坐标
        }
    }
}

///上行高度
static CGFloat ascentCallback(void *ref){
    YLImage *model = (__bridge YLImage *)ref;
    return model.imageFrame.size.height;
}

///下行高度
static CGFloat descentCallback(void *ref){
    return 0;
}

///图片宽度
static CGFloat widthCallback(void *ref){
    YLImage *model = (__bridge YLImage *)ref;
    return model.imageFrame.size.width;
}

+ (NSAttributedString *)parseImage:(UIImage *)image drawSize:(CGSize)drawSize{
    /**************** 计算图片宽高 **************/
    CGSize imageShowSize = image.size;//屏幕上展示的图片尺寸
    if (image.size.width > drawSize.width) {
        imageShowSize = CGSizeMake(drawSize.width, image.size.height / image.size.width * drawSize.width);
    }
    
    YLImage *model = [[YLImage alloc]init];
    model.image = image;
    model.imageFrame = CGRectMake(0, 0, imageShowSize.width, imageShowSize.height);
    
    //注意：此处返回的富文本，最主要的作用是占位！
    //为图片的绘制留下空白区域
    CTRunDelegateCallbacks callbacks;
    memset(&callbacks, 0, sizeof(CTRunDelegateCallbacks));
    callbacks.version = kCTRunDelegateVersion1;//设置回调版本，默认这个
    callbacks.getAscent = ascentCallback;//上行高度
    callbacks.getDescent = descentCallback;//下行高度
    callbacks.getWidth = widthCallback;//图片宽度
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, (__bridge void *)model);
    
    //使用0xFFFC作为空白占位符
    unichar objectReplacementChar = 0xFFFC;
    NSString *content = [NSString stringWithCharacters:&objectReplacementChar length:1];
    NSMutableAttributedString *placeholder = [[NSMutableAttributedString alloc] initWithString:content attributes:@{kYLAttributeName:model}];
    CFAttributedStringSetAttribute((CFMutableAttributedStringRef)placeholder, CFRangeMake(0, 1), kCTRunDelegateAttributeName, delegate);
    CFRelease(delegate);
    return placeholder;
}

+ (NSAttributedString *)parseImageFromeTextWithURL:(NSString *)url drawSize:(CGSize)drawSize{
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    if (data == nil) {
        NSAttributedString *imgaeString = [[NSAttributedString alloc] initWithString:@""];
        return imgaeString;
    }
    UIImage *image = [UIImage imageWithData:data];
    if (image == nil) {
        NSAttributedString *imgaeString = [[NSAttributedString alloc] initWithString:@""];
        return imgaeString;
    }
    
    /**************** 计算图片宽高 **************/
    CGSize imageShowSize = image.size;//屏幕上展示的图片尺寸
    if (image.size.width > drawSize.width) {
        imageShowSize = CGSizeMake(drawSize.width, image.size.height / image.size.width * drawSize.width);
    }
        
    YLImage *model = [[YLImage alloc]init];
    model.url = url;
    model.image = image;
    model.imageFrame = CGRectMake(0, 0, imageShowSize.width, imageShowSize.height);
    
    //注意：此处返回的富文本，最主要的作用是占位！
    //为图片的绘制留下空白区域
    CTRunDelegateCallbacks callbacks;
    memset(&callbacks, 0, sizeof(CTRunDelegateCallbacks));
    callbacks.version = kCTRunDelegateVersion1;//设置回调版本，默认这个
    callbacks.getAscent = ascentCallback;//上行高度
    callbacks.getDescent = descentCallback;//下行高度
    callbacks.getWidth = widthCallback;//图片宽度
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, (__bridge void *)model);
    
    //使用0xFFFC作为空白占位符
    unichar objectReplacementChar = 0xFFFC;
    NSString *content = [NSString stringWithCharacters:&objectReplacementChar length:1];
    NSMutableAttributedString *placeholder = [[NSMutableAttributedString alloc] initWithString:content attributes:@{kYLAttributeName:model}];
    CFAttributedStringSetAttribute((CFMutableAttributedStringRef)placeholder, CFRangeMake(0, 1), kCTRunDelegateAttributeName, delegate);
    CFRelease(delegate);
    return placeholder;
}

@end


/// CTFrame 上触摸事件的处理：
@implementation YLCoreText (Touch)

/** 获取触摸位置所在的行 CTLine
 * @param point 触摸点
 */
CTLineRef getTouchLine(CGPoint point,CTFrameRef frameRef){
    CTLineRef line = nil;
    if (frameRef == nil) { return line; }
    
    CGPathRef path = CTFrameGetPath(frameRef);
    CGRect bounds = CGPathGetBoundingBox(path);/// 页面边界
    CGFloat pageWidth = CGRectGetWidth(bounds);/// 页面宽度
    CGFloat pageHeight = CGRectGetHeight(bounds);/// 页面高度
    
    CFArrayRef lines = CTFrameGetLines(frameRef);
    int lineCount = (int)CFArrayGetCount(lines);
    if (lineCount < 1) {
        return line;
    }
    
    CGPoint origins[lineCount];
    for (int i = 0; i < lineCount; i++) {
        origins[i] = CGPointZero;
    }
    CTFrameGetLineOrigins(frameRef, CFRangeMake(0, 0), origins);
    for (int i = 0; i < lineCount; i ++) {
        CGPoint origin = origins[i];
        CTLineRef tempLine = CFArrayGetValueAtIndex(lines, i);
        CGFloat lineAscent = 0;  //上行高度
        CGFloat lineDescent = 0; //下行高度
        CGFloat lineLeading = 0; //行距
        CTLineGetTypographicBounds(tempLine, &lineAscent, &lineDescent, &lineLeading);/// 获取CTLine的字形度量
        CGFloat lineHeight = lineAscent + fabs(lineDescent) + lineLeading;
        CGRect lineFrame = CGRectMake(origin.x, pageHeight - (origin.y + lineAscent), pageWidth, lineHeight);
        lineFrame = CGRectInset(lineFrame, -5, -5);
        if (CGRectContainsPoint(lineFrame, point)) {
            line = tempLine;
            break;
        }
    }
    return line;
}

/** 获得触摸位置那一行文字范围 Range
 * @param point 触摸点
 */
NSRange getTouchLineRange(CGPoint point,CTFrameRef frameRef){
    NSRange range = NSMakeRange(NSNotFound, 0);
    CTLineRef line = getTouchLine(point, frameRef);
    if (line) {
        CFRange lineRange = CTLineGetStringRange(line);
        range = NSMakeRange(lineRange.location == kCFNotFound ? NSNotFound : lineRange.location, lineRange.length);
    }
    return range;
}

/** 获得触摸位置文字的Location
 * @param point 触摸点
 */
signed long getTouchLocation(CGPoint point,CTFrameRef frameRef){
    signed long location = -1;
    CTLineRef line = getTouchLine(point,frameRef);
    if (line != nil) {
        location = CTLineGetStringIndexForPosition(line, point);
    }
    return location;
}

@end
