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
CTFrameRef getFrameRefByAttrString(NSAttributedString *attrString, CGRect rect){
    ///绘制局域
    CGPathRef path = CGPathCreateWithRect(rect, nil);
    //设置绘制内容
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attrString);
    CTFrameRef frameRef = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil);
    CFRelease(framesetter);
    CGPathRelease(path);
    return frameRef;
}

/** 获得内容分页列表
 * @param attrString 内容
 * @param rect 显示范围
 */
NSMutableArray<NSValue *> *getPageingRanges(NSAttributedString *attrString, CGRect rect){
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

/// 获取指定内容高度
///
/// - Parameters:
///   - attrString: 内容
///   - maxW: 最大宽度
/// - Returns: 当前高度

CGFloat getAttrStringHeight(NSAttributedString *attrString,CGFloat maxW){
    CGFloat height = 0;
    if (attrString.length > 0){
        // 注意设置的高度必须大于文本高度
        CGFloat maxH = 1000;
        CGRect drawingRect = CGRectMake(0, 0, maxW, maxH);

        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attrString);
        CGPathRef path = CGPathCreateWithRect(drawingRect, nil);
        CTFrameRef frameRef = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil);
        
        /// 释放资源
        CFRelease(framesetter);
        CGPathRelease(path);
                
        CFArrayRef lines = CTFrameGetLines(frameRef);//as! [CTLine]
        int lineCount = (int)CFArrayGetCount(lines);
        
        CGPoint origins[lineCount];
        for (int i = 0; i < lineCount; i++) {
            origins[i] = CGPointZero;
        }
        CTFrameGetLineOrigins(frameRef, CFRangeMake(0, 0), origins);
        
        CGPoint point = origins[lineCount - 1];
        CGFloat lineY = point.y;
        CGFloat lineAscent = 0;
        CGFloat lineDescent = 0;
        CGFloat lineLeading = 0;
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineCount - 1);
        CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
        height = maxH - lineY + ceil(lineDescent);
        
        CFRelease(frameRef);
    }
    return height;
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

/// 获得触摸位置在哪一行
///
/// - Parameters:
///   - point: 触摸位置
///   - frameRef: CTFrame
/// - Returns: CTLine
CTLineRef getTouchLine(CGPoint point,CTFrameRef frameRef){
    CTLineRef line = nil;
    if (frameRef == nil) { return line; }
    
    CGPathRef path = CTFrameGetPath(frameRef);
    CGRect bounds = CGPathGetBoundingBox(path);
    //CGPathRelease(path);
    
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
        CGFloat lineAscent = 0;
        CGFloat lineDescent = 0;
        CGFloat lineLeading = 0;
        CTLineGetTypographicBounds(tempLine, &lineAscent, &lineDescent, &lineLeading);
        CGFloat lineWidth = bounds.size.width;
        CGFloat lineheight = lineAscent + lineDescent + lineLeading;
        
        CGRect lineFrame = CGRectMake(origin.x, bounds.size.height - origin.y - lineAscent, lineWidth, lineheight);
        lineFrame = CGRectInset(lineFrame, -5, -5);
        if (CGRectContainsPoint(lineFrame, point)) {
            line = tempLine;
            break;
        }
    }
    return line;
}

/// 获得触摸位置那一行文字的Range
///
/// - Parameters:
///   - point: 触摸位置
///   - frameRef: CTFrame
/// - Returns: CTLine
NSRange getTouchLineRange(CGPoint point,CTFrameRef frameRef){
    NSRange range = NSMakeRange(NSNotFound, 0);
    CTLineRef line = getTouchLine(point, frameRef);
    if (line) {
        CFRange lineRange = CTLineGetStringRange(line);
        range = NSMakeRange(lineRange.location == kCFNotFound ? NSNotFound : lineRange.location, lineRange.length);
    }
    return range;
}

/// 获得触摸位置文字的Location
///
/// - Parameters:
///   - point: 触摸位置
///   - frameRef: CTFrame
/// - Returns: 触摸位置的Index
signed long getTouchLocation(CGPoint point,CTFrameRef frameRef){
    signed long location = -1;
    CTLineRef line = getTouchLine(point,frameRef);
    if (line != nil) {
        location = CTLineGetStringIndexForPosition(line, point);
    }
    return location;
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

@end







@implementation YLCoreText (Page)

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


/** 将内容分为多页
 * @param attrString 展示的内容
 * @prama rect 显示范围
 */
NSMutableArray<YLPageModel *> *pageingWithAttrString(NSMutableAttributedString *attrString, CGRect rect){
    NSMutableArray<YLPageModel *> *pageModels = [NSMutableArray array];
    handleAttrString(attrString, rect);
    NSMutableArray<NSValue *> *ranges = getPageingRanges(attrString, rect);
          
    if (ranges && ranges.count) {
        [ranges enumerateObjectsUsingBlock:^(NSValue * _Nonnull rangeValue, NSUInteger idx, BOOL * _Nonnull stop) {
            NSRange range = rangeValue.rangeValue;
            NSAttributedString *content = [attrString attributedSubstringFromRange:range];
            YLPageModel *pageModel = [[YLPageModel alloc]init];
            pageModel.range = range;
            pageModel.content = content;
            pageModel.page = idx;
            pageModel.frameRef = getFrameRefByAttrString(content,rect);
            [YLCoreText setImageFrametWithCTFrame:pageModel.frameRef];
            [pageModels addObject:pageModel];
        }];
    }    
    return pageModels;
}

@end


/** 绘制图片的时候实际上在一个 CTRunRef 中，以它坐标系为基准，以 origin 点作为原点进行绘制：
 * 基线为过原点的x轴，ascent 即为 CTRun 顶线距基线的距离，descent即为底线距基线的距离。
 */
@implementation YLCoreText (ImageHandler)

/** 计算并设置 CTFrameRef 中的所有图片的坐标
 * @note 单独用 frameSetter 求出的 image 的 frame 是不正确的，那是只绘制 image 而得的坐标
 * 思路： 遍历 CTFrameRef 中的所有 CTRun，检查 CTRun 是不是绑定图片的那个，
 *       如果是，根据 CTRun 所在 CTLine 的 origin 以及在 CTLine 中的横向偏移量计算出 CTRun 的原点，
 *       加上其尺寸即为该CTRun的尺寸
 */
+ (void)setImageFrametWithCTFrame:(CTFrameRef)frame{
    NSArray *arrLines = (NSArray *)CTFrameGetLines(frame);
    NSInteger count = [arrLines count];
    CGPoint points[count];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), points);
    for (int i = 0; i < count; i ++) {//外层for循环，为了取到所有的 CTLine
        CTLineRef line = (__bridge CTLineRef)arrLines[i];
        NSArray *arrGlyphRun = (NSArray *)CTLineGetGlyphRuns(line);
        for (int j = 0; j < arrGlyphRun.count; j ++) {//内层for循环，检查每个 CTRun
            CTRunRef run = (__bridge CTRunRef)arrGlyphRun[j];
            NSDictionary * attributes = (NSDictionary *)CTRunGetAttributes(run);
            CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[attributes valueForKey:(id)kCTRunDelegateAttributeName];//获取代理属性
            if (delegate == nil) {
                continue;
            }
            YLImage *model = CTRunDelegateGetRefCon(delegate);
            if (![model isKindOfClass:[YLImage class]]) {
                continue;
            }
            CGPoint linePoint = points[i];//获取CTLine的原点
            CGFloat ascent;//获取上距
            CGFloat descent;//获取下距
            CGRect boundsRun;
            //获取宽、高
            boundsRun.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);
            boundsRun.size.height = ascent + descent;
            //获取对应 CTRun 的 X 偏移量
            CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
            boundsRun.origin.x = linePoint.x + xOffset;
            boundsRun.origin.y = linePoint.y - descent;//减去图片的下边距才是图片的原点
            CGPathRef path = CTFrameGetPath(frame);//获取绘制区域
            CGRect colRect = CGPathGetBoundingBox(path);//获取绘制区域边框
            model.imageFrame = CGRectOffset(boundsRun, colRect.origin.x, colRect.origin.y);//设置图片坐标
        }
    }
}

static CGFloat ascentCallback(void *ref){
    YLImage *model = (__bridge YLImage *)ref;
    return model.imageFrame.size.height;
}

static CGFloat descentCallback(void *ref){
    return 0;
}

static CGFloat widthCallback(void *ref){
    YLImage *model = (__bridge YLImage *)ref;
    return model.imageFrame.size.width;
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
    callbacks.getAscent = ascentCallback;//设置图片顶部距离基线的距离
    callbacks.getDescent = descentCallback;//设置图片底部距离基线的距离
    callbacks.getWidth = widthCallback;//设置图片宽度
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, (__bridge void *)model);
    
    //使用0xFFFC作为空白占位符
    unichar objectReplacementChar = 0xFFFC;
    NSString *content = [NSString stringWithCharacters:&objectReplacementChar length:1];
    NSMutableAttributedString *space = [[NSMutableAttributedString alloc] initWithString:content attributes:@{kYLAttributeName:model}];
    CFAttributedStringSetAttribute((CFMutableAttributedStringRef)space, CFRangeMake(0, 1), kCTRunDelegateAttributeName, delegate);
    CFRelease(delegate);
    return space;
}


@end
