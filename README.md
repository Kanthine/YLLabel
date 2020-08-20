# YLLabel
利用 CoreText 自定义一个Label

###### 前言 ：字符（Character）和字形（Glyphs）

 
文本显示的主要过程就是字符到字形的转换：
* 字符：信息本身的元素；在计算机中是一个编码，如 Unicode 字符集囊括了大部分字符
* 字形：字符的图标特征，一般存储在字体文件中；
一个字符可以对应多个字形（不同的字体，同种字体的不同样式：粗体、斜体）
 
在 iOS 中渲染到屏幕的字形有多个度量(Glyph Metrics)：

![字形度量.gif](https://upload-images.jianshu.io/upload_images/7112462-409335ee7ef3c3d4.gif?imageMogr2/auto-orient/strip)


* 边界框 bounding box ：一个假想的框子，在边界框内尽可能紧密的装入字形；
* 基线 baseline ：一条假想的线，同一行的字形以该条线作参考；该条线最左侧的一个点是基线的原点；
* 上行高度 ascent ： 基线距字体中最高的字形顶部的距离，是一个正值
* 下行高度 descent： 基线距字体中最低的字形底部的距离，是一个负值
* 行距 linegap
* 行高 lineHeight = ascent + |descent| + linegap


###### CoreText 的常用布局元素：

![CTFrame组成.png](https://upload-images.jianshu.io/upload_images/7112462-f87d2992e4a87cb6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


* `CTFrameRef`：由多个 `CTLineRef` 组成，有几行文字就有几行 `CTLineRef`；
* `CTLineRef`：可以看做 CoreText 绘制中的一行的对象； 通过它可以获得当前行的上行高度 ascent , 下行高度 descent ,行距 leading, 还可以获得Line下的所有Glyph Runs
* `CTRunRef`：基本绘制单元，由属性 attributes 都相同的部分字形组成；

###### 1、  `CTFrameRef` 制造器


```
/** CTFramesetterRef 是根据富文本生成的一个frame生成的工厂，
 * 可以通过 framesetter 以及待绘制的富文本的范围获取该 CTRun 的 frame 
 */
typedef const struct CF_BRIDGED_TYPE(id) __CTFramesetter * CTFramesetterRef;

/** 根据 typesetter 创建一个framesetter对象
 * @param typesetter 用于构造 framesetter 的 typesetter
 * @result 返回对CTFramesetter对象的引用。
 * @discussion 每个 framesetter 在内部使用一个 typesetter 来执行分行等工作；
 *            该函数允许使用使用 specific options 创建的typesetter 
 * @memory 注意合适的时机释放 CFRelease(framesetter);
 */
CTFramesetterRef CTFramesetterCreateWithTypesetter(CTTypesetterRef typesetter);

/** 获取 framesetter 正在使用的 typesetter 对象
 * @param framesetter 向其请求的 framesetter
 * @memory 该函数获取对 CTTypesetter 对象的引用，调用者不必释放该对象；               
 */
CTTypesetterRef CTFramesetterGetTypesetter(CTFramesetterRef framesetter);

/** 根据富文本创建不可变的framesetter对象
 * @param attrString 用于构造 framesetter 的富文本
 * @result 返回对CTFramesetter对象的引用
 * @discussion 生成的 framesetter 对象可用来被 CTFramesetterCreateFrame() 调用创建和填充文本 frames
 * @memory 注意合适的时机释放 CFRelease(framesetter);
 */
CTFramesetterRef CTFramesetterCreateWithAttributedString(CFAttributedStringRef attrString);

/** 从 framesetter 创建一个 CTFrameRef
 * @param framesetter 用于创建 CTFrame 的 framesetter
 * @param stringRange 新frame将基于的字符串范围;字符串范围是用于创建framesetter的字符串上的范围。
 *           如果 range.length 被设置为 0，那么framesetter将一直添加 CTLineRef ，直到耗尽文本或空间
 * @param path 绘制局域，可以提供一个特殊形状的区域（如圆形、三角形区域等）
 * @param frameAttributes 在这里指定 frame 填充过程的其他属性，如果没有这样的属性，则为 NULL
 * @result 返回对一个新的CTFrame对象的引用
 * @memory 注意合适的时机释放 CFRelease(frameRef);    
 */
CTFrameRef CTFramesetterCreateFrame(CTFramesetterRef framesetter,CFRange stringRange,
                            CGPathRef path,CFDictionaryRef _Nullable frameAttributes);
                            
/** 确定字符串范围所需的frame.size
 * @param framesetter 用于测量 frame.size 的 framesetter
 * @param stringRange 将应用 frame.size 的字符串范围。字符串范围是用于创建framesetter的字符串上的范围。
 *           如果 range.length 被设置为 0，那么framesetter将一直添加 CTLineRef ，直到耗尽文本或空间
 * @param frameAttributes 在这里指定 frame 填充过程的其他属性，如果没有这样的属性，则为 NULL
 * @param constraints 被限制的宽度与高度，值为 CGFLOAT_MAX，表示不受限制；
 * @param fitRange 受 constrained 限制的字符串的范围             
 * @result 返回显示字符串所需的实际空间大小
 */
CGSize CTFramesetterSuggestFrameSizeWithConstraints(CTFramesetterRef framesetter,CFRange stringRange,
           CFDictionaryRef _Nullable frameAttributes,CGSize constraints,CFRange * _Nullable fitRange);
```


###### 2、  `CTFrameRef`  

```
typedef const struct CF_BRIDGED_TYPE(id) __CTFrame * CTFrameRef;

/// CTFrameRef 内 CTLineRef 的堆叠方式：水平或垂直堆叠；
/// 垂直堆叠时，在绘图时将使线条逆时针旋转90度；
/// 不同的堆叠方式，并不影响该 CTFrameRef 内字形的外观；
typedef CF_ENUM(uint32_t, CTFrameProgression) {
    kCTFrameProgressionTopToBottom  = 0, //对于水平文本，行是从上到下堆叠的
    kCTFrameProgressionRightToLeft  = 1, //垂直文本的行从右到左堆叠
    kCTFrameProgressionLeftToRight  = 2  //垂直文本的行从左到右堆叠
};

/// CTFrameRef 内 CTLineRef 的堆叠方式：默认值为 kCTFrameProgressionTopToBottom 
CT_EXPORT const CFStringRef kCTFrameProgressionAttributeName;

/// 填充规则：当路径与自身相交时，指定填充规则来决定文本被绘制的区域
typedef CF_ENUM(uint32_t, CTFramePathFillRule) {
    kCTFramePathFillEvenOdd         = 0, // 路径被给定到 CGContextEOFillPath
    kCTFramePathFillWindingNumber   = 1  // 路径被给定到 CGContextFillPath
};

/** 默认值为 kCTFramePathFillEvenOdd
 * @discussion 如果在 frameAttributes 字典的使用此属性，则为 CTFrameRef 指定填充规则;
 *          如果在 kCTFrameClippingPathsAttributeName 指定的数组中包含的字典中使用，则为剪切路径指定填充规则;
 */
CT_EXPORT const CFStringRef kCTFramePathFillRuleAttributeName;

/** 默认值为 0
 * @discussion 如果在 frameAttributes 字典的使用此属性，则为 CTFrameRef 指定宽度;
 *          如果在 kCTFrameClippingPathsAttributeName 指定的数组中包含的字典中使用，则为剪切路径指定宽度;
 */
CT_EXPORT const CFStringRef kCTFramePathWidthAttributeName;

/// 指定 clip frame 的路径数组   
CT_EXPORT const CFStringRef kCTFrameClippingPathsAttributeName;

/// 指定 clipping path
CT_EXPORT const CFStringRef kCTFramePathClippingPathAttributeName;

/** 获取 CTFrameRef 的字符范围。               
 * @result 返回一个CFRange，其中包含创建 CTFrameRef 时的后备存储范围。如果函数调用不成功，那么将返回一个 empty range
*/
CFRange CTFrameGetStringRange(CTFrameRef frame);

/// 获取实际填充 CTFrameRef 的字符范围
CFRange CTFrameGetVisibleStringRange(CTFrameRef frame);

///获取用于创建 CTFrameRef 的路径
CGPathRef CTFrameGetPath(CTFrameRef frame);

/// 获取用于创建 CTFrameRef 的属性字典，如果没有则返回NULL
CFDictionaryRef _Nullable CTFrameGetFrameAttributes(CTFrameRef frame);

/// 获取组成 CTFrameRef 的所有行（CTLineRef 对象），可能返回空数组
CFArrayRef CTFrameGetLines(CTFrameRef frame);

/** 拷贝 CTFrameRef 中指定范围的所有行的原点 origin
 * @param range 希望拷贝的范围。如果 range.length 设置为0，则将从 range.location 拷贝至最后一行
 * @param origins 缓冲区，用于存储待复制的数据；缓冲区的长度至少要大于待拷贝的数据份数；
 * @note  当使用 origin 来计算 CTFrameRef 内容的字形度量时，请注意线的原点并不总是对应于线度量;例如，段落样式设置可以影响线条的 origin ；
 * @discussion 数组 origins 的最大存储量是行数组的计数；
 */
void CTFrameGetLineOrigins(CTFrameRef frame,CFRange range,CGPoint origins[_Nonnull]);

/** 将 CTFrameRef 绘制到上下文 CGContext 中；   
 * @note 该调用可能会使上下文处于任何状态，并且在绘制操作之后不会刷新它。                
 */
void CTFrameDraw(CTFrameRef frame,CGContextRef context);
```

###### 示范：

```
-(CFDictionaryRef)clippingPathsDictionary{
    NSMutableArray *pathsArray = [[NSMutableArray alloc] init];

    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformScale(transform, 1, -1);
    transform = CGAffineTransformTranslate(transform, 0, -self.bounds.size.height);

    int eFrameWidth=0;
    CFNumberRef frameWidth = CFNumberCreate(NULL, kCFNumberNSIntegerType, &eFrameWidth);

    int eFillRule = kCTFramePathFillEvenOdd;
    CFNumberRef fillRule = CFNumberCreate(NULL, kCFNumberNSIntegerType, &eFillRule);

    int eProgression = kCTFrameProgressionTopToBottom;
    CFNumberRef progression = CFNumberCreate(NULL, kCFNumberNSIntegerType, &eProgression);

    CFStringRef keys[] = { kCTFrameClippingPathsAttributeName, kCTFramePathFillRuleAttributeName, kCTFrameProgressionAttributeName, kCTFramePathWidthAttributeName};
    CFTypeRef values[] = { (__bridge CFTypeRef)(pathsArray), fillRule, progression, frameWidth};
    
    CFDictionaryRef clippingPathsDictionary = CFDictionaryCreate(NULL,
                                                             (const void **)&keys, (const void **)&values,
                                                             sizeof(keys) / sizeof(keys[0]),
                                                             &kCFTypeDictionaryKeyCallBacks,
                                                             &kCFTypeDictionaryValueCallBacks);
    return clippingPathsDictionary;
}

- (void)drawRect:(CGRect)rect{
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformScale(transform, 1, -1);
    transform = CGAffineTransformTranslate(transform, 0, -rect.size.height);

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextConcatCTM(context, transform);

    CFAttributedStringRef attributedString = (__bridge CFAttributedStringRef)self.attributedString;
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString(attributedString);

    CFDictionaryRef  attributesDictionary = [self clippingPathsDictionary];
    CGPathRef path = CGPathCreateWithRect(rect, &transform);
    CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, self.attributedString.length), path, attributesDictionary);
    CFRelease(path);
    CFRelease(attributesDictionary);

    CTFrameDraw(frame, context);
    
    CFRelease(frameSetter);
    CFRelease(frame);
}
```


###### 3、  `CTLineRef`  


```
/** 可以看做 CoreText 绘制中的一行的对象 
 * 通过它可以获得当前行的 line ascent , line descent ,line leading, 还可以获得Line下的所有Glyph Runs
 * 可以通过 CTFramesetterRef 以及待绘制的富文本的范围获取该 CTRun 的 frame 
 */
typedef const struct CF_BRIDGED_TYPE(id) __CTLine * CTLineRef;


/** 枚举值 CTLineBoundsOptions ：传递0(没有选项)返回排版边界，包括排版前导和移位
 * 允许其成员值按位组合。      
*/
typedef CF_OPTIONS(CFOptionFlags, CTLineBoundsOptions) {
    kCTLineBoundsExcludeTypographicLeading  = 1 << 0, /// 从边界计算（不同文本行的基线之间的间隔）中排除印刷字体的前导
    kCTLineBoundsExcludeTypographicShifts   = 1 << 1, /// 在计算边界时不考虑字距调整或引导信息
    
    ///悬挂标点符号是一种排版标点符号和项目符号点（最常用的是引号和连字符）的方式，这样它们就不会破坏文本主体的“流动”或“破坏”对齐的边缘。之所以这样称呼，是因为标点符号似乎在文本的边缘处“悬挂”，而不是并入文本的块或列中。通常在文本完全合理时使用。
    kCTLineBoundsUseHangingPunctuation      = 1 << 2, 
    
     /// 使用字形的边界，而非默认的排版边界；因为它们没有考虑到排版的详细信息，这将返回所呈现的实际文本的边界框;
    kCTLineBoundsUseGlyphPathBounds         = 1 << 3,
    
    ///使用光学边界：某些字体包含光学感知的信息，并且可能与文本的边界框不完全对齐；此选项将覆盖 PathBounds;
    kCTLineBoundsUseOpticalBounds           = 1 << 4,
    
    /// 根据各种语言的通用符号序列包括额外的空间，在绘图时使用，以避免可能由排版边界引起的剪切；
    /// 当与kCTLineBoundsUseGlyphPathBounds一起使用时，该选项没有任何效果。
    kCTLineBoundsIncludeLanguageExtents     = 1 << 5,
};


/*!
    @enum       CTLineTruncationType
    @abstract   Truncation types required by CTLineCreateTruncatedLine. These
                will tell truncation engine which type of truncation is being
                requested.

    @constant   kCTLineTruncationStart
                Truncate at the beginning of the line, leaving the end portion
                visible.

    @constant   kCTLineTruncationEnd
                Truncate at the end of the line, leaving the start portion
                visible.

    @constant   kCTLineTruncationMiddle
                Truncate in the middle of the line, leaving both the start
                and the end portions visible.
*/

typedef CF_ENUM(uint32_t, CTLineTruncationType) {
    kCTLineTruncationStart  = 0,
    kCTLineTruncationEnd    = 1,
    kCTLineTruncationMiddle = 2
};


/*!
    @function   CTLineGetTypeID
    @abstract   Returns the CFType of the line object
*/

CFTypeID CTLineGetTypeID( void ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/* --------------------------------------------------------------------------- */
/* Line Creation */
/* --------------------------------------------------------------------------- */

/*!
    @function   CTLineCreateWithAttributedString
    @abstract   Creates a single immutable line object directly from an
                attributed string.

    @discussion This will allow clients who need very simple line generation to
                create a line without needing to create a typesetter object. The
                typesetting will be done under the hood. Without a typesetter
                object, the line cannot be properly broken. However, for simple
                things like text labels and other things, this is not an issue.

    @param      attrString
                The attributed string which the line will be created for.

    @result     This function will return a reference to a CTLine object.
*/

CTLineRef CTLineCreateWithAttributedString(
    CFAttributedStringRef attrString ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTLineCreateTruncatedLine
    @abstract   Creates a truncated line from an existing line.

    @param      line
                The line that you want to create a truncated line for.

    @param      width
                The width at which truncation will begin. The line will be
                truncated if its width is greater than the width passed in this.

    @param      truncationType
                The type of truncation to perform if needed.

    @param      truncationToken
                This token will be added to the point where truncation took place
                to indicate that the line was truncated. Usually, the truncation
                token is the ellipsis character (U+2026). If this parameter is
                set to NULL, then no truncation token is used, and the line is
                simply cut off. The line specified in truncationToken should have
                a width less than the width specified by the width parameter. If
                the width of the line specified in truncationToken is greater,
                this function will return NULL if truncation is needed.

    @result     This function will return a reference to a truncated CTLine
                object if the call was successful. Otherwise, it will return
                NULL.
*/

CTLineRef _Nullable CTLineCreateTruncatedLine(
    CTLineRef line,
    double width,
    CTLineTruncationType truncationType,
    CTLineRef _Nullable truncationToken ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTLineCreateJustifiedLine
    @abstract   Creates a justified line from an existing line.

    @param      line
                The line that you want to create a justified line for.

    @param      justificationFactor
                Allows for full or partial justification. When set to 1.0 or
                greater indicates, full justification will be performed. If less
                than 1.0, varying degrees of partial justification will be
                performed. If set to 0 or less, then no justification will be
                performed.

    @param      justificationWidth
                The width to which the resultant line will be justified. If
                justificationWidth is less than the actual width of the line,
                then negative justification will be performed ("text squishing").

    @result     This function will return a reference to a justified CTLine
                object if the call was successful. Otherwise, it will return
                NULL.
*/

CTLineRef _Nullable CTLineCreateJustifiedLine(
    CTLineRef line,
    CGFloat justificationFactor,
    double justificationWidth ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/* --------------------------------------------------------------------------- */
/* Line Access */
/* --------------------------------------------------------------------------- */

/*!
    @function   CTLineGetGlyphCount
    @abstract   Returns the total glyph count for the line object.

    @discussion The total glyph count is equal to the sum of all of the glyphs in
                the glyph runs forming the line.

    @param      line
                The line that you want to obtain the glyph count for.

    @result     The total glyph count for the line passed in.
*/

CFIndex CTLineGetGlyphCount(
    CTLineRef line ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTLineGetGlyphRuns
    @abstract   Returns the array of glyph runs that make up the line object.

    @param      line
                The line that you want to obtain the glyph run array for.

    @result     A CFArrayRef containing the CTRun objects that make up the line.
*/

CFArrayRef CTLineGetGlyphRuns(
    CTLineRef line ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTLineGetStringRange
    @abstract   Gets the range of characters that originally spawned the glyphs
                in the line.

    @param      line
                The line that you want to obtain the string range from.

    @result     A CFRange that contains the range over the backing store string
                that spawned the glyphs. If the function fails for any reason, an
                empty range will be returned.
*/

CFRange CTLineGetStringRange(
    CTLineRef line ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTLineGetPenOffsetForFlush
    @abstract   Gets the pen offset required to draw flush text.

    @param      line
                The line that you want to obtain a flush position from.

    @param      flushFactor
                Specifies what kind of flushness you want. A flushFactor of 0 or
                less indicates left flush. A flushFactor of 1.0 or more indicates
                right flush. Flush factors between 0 and 1.0 indicate varying
                degrees of center flush, with a value of 0.5 being totally center
                flush.

    @param      flushWidth
                Specifies the width that the flushness operation should apply to.

    @result     A value which can be used to offset the current pen position for
                the flush operation.
*/

double CTLineGetPenOffsetForFlush(
    CTLineRef line,
    CGFloat flushFactor,
    double flushWidth ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTLineDraw
    @abstract   Draws a line.

    @discussion This is a convenience call, since the line could be drawn
                run-by-run by getting the glyph runs and accessing the glyphs out
                of them. This call may leave the graphics context in any state and
                does not flush the context after drawing. This call also expects
                a text matrix with `y` values increasing from bottom to top; a
                flipped text matrix may result in misplaced diacritics.

    @param      line
                The line that you want to draw.

    @param      context
                The context to which the line will be drawn.
*/

void CTLineDraw(
    CTLineRef line,
    CGContextRef context ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/* --------------------------------------------------------------------------- */
/* Line Measurement */
/* --------------------------------------------------------------------------- */

/*!
    @function   CTLineGetTypographicBounds
    @abstract   Calculates the typographic bounds for a line.

    @discussion A line's typographic width is the distance to the rightmost
                glyph advance width edge. Note that this distance includes
                trailing whitespace glyphs.

    @param      line
                The line that you want to calculate the typographic bounds for.

    @param      ascent
                Upon return, this parameter will contain the ascent of the line.
                This may be set to NULL if not needed.

    @param      descent
                Upon return, this parameter will contain the descent of the line.
                This may be set to NULL if not needed.

    @param      leading
                Upon return, this parameter will contain the leading of the line.
                This may be set to NULL if not needed.

    @result     The typographic width of the line. If line is invalid, this
                function will always return zero.

    @seealso    CTLineGetTrailingWhitespaceWidth
*/

double CTLineGetTypographicBounds(
    CTLineRef line,
    CGFloat * _Nullable ascent,
    CGFloat * _Nullable descent,
    CGFloat * _Nullable leading ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTLineGetBoundsWithOptions
    @abstract   Calculates the bounds for a line.

    @param      line
                The line that you want to calculate the bounds for.

    @param      options
                Desired options or 0 if none.

    @result     The bounds of the line as specified by the type and options,
                such that the coordinate origin is coincident with the line
                origin and the rect origin is at the bottom left. If the line
                is invalid this function will return CGRectNull.
*/

CGRect CTLineGetBoundsWithOptions(
    CTLineRef line,
    CTLineBoundsOptions options ) CT_AVAILABLE(macos(10.8), ios(6.0), watchos(2.0), tvos(9.0));


/*!
    @function   CTLineGetTrailingWhitespaceWidth
    @abstract   Calculates the trailing whitespace width for a line.

    @param      line
                The line that you want to calculate the trailing whitespace width
                for. Creating a line for a width can result in a line that is
                actually longer than the desired width due to trailing
                whitespace. Normally this is not an issue due to whitespace being
                invisible, but this function may be used to determine what amount
                of a line's width is due to trailing whitespace.

    @result     The width of the line's trailing whitespace. If line is invalid,
                this function will always return zero.
*/

double CTLineGetTrailingWhitespaceWidth(
    CTLineRef line ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTLineGetImageBounds
    @abstract   Calculates the image bounds for a line.

    @discussion The image bounds for a line is the union of all non-empty glyph
                bounding rects, each positioned as it would be if drawn using
                CTLineDraw using the current context. Note that the result is
                ideal and does not account for raster coverage due to rendering.
                This function is purely a convenience for using glyphs as an
                image and should not be used for typographic purposes.

    @param      line
                The line that you want to calculate the image bounds for.

    @param      context
                The context which the image bounds will be calculated for or NULL,
                in which case the bounds are relative to CGPointZero.

    @result     A rectangle that tightly encloses the paths of the line's glyphs,
                which will be translated by the supplied context's text position.
                If the line is invalid, CGRectNull will be returned.

    @seealso    CTLineGetTypographicBounds
    @seealso    CTLineGetBoundsWithOptions
    @seealso    CTLineGetPenOffsetForFlush
*/

CGRect CTLineGetImageBounds(
    CTLineRef line,
    CGContextRef _Nullable context ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/* --------------------------------------------------------------------------- */
/* Line Caret Positioning and Highlighting */
/* --------------------------------------------------------------------------- */

/*!
    @function   CTLineGetStringIndexForPosition
    @abstract   Performs hit testing.

    @discussion This function can be used to determine the string index for a
                mouse click or other event. This string index corresponds to the
                character before which the next character should be inserted.
                This determination is made by analyzing the string from which a
                typesetter was created and the corresponding glyphs as embodied
                by a particular line.

    @param      line
                The line being examined.

    @param      position
                The location of the mouse click relative to the line's origin.

    @result     The string index for the position. Relative to the line's string
                range, this value will be no less than the first string index and
                no greater than one plus the last string index. In the event of
                failure, this function will return kCFNotFound.
*/

CFIndex CTLineGetStringIndexForPosition(
    CTLineRef line,
    CGPoint position ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTLineGetOffsetForStringIndex
    @abstract   Determines the graphical offset(s) for a string index.

    @discussion This function returns the graphical offset(s) corresponding to
                a string index, suitable for movement between adjacent lines or
                for drawing a custom caret. For the former, the primary offset
                may be adjusted for any relative indentation of the two lines;
                a CGPoint constructed with the adjusted offset for its x value
                and 0.0 for its y value is suitable for passing to
                CTLineGetStringIndexForPosition. In either case, the primary
                offset corresponds to the portion of the caret that represents
                the visual insertion location for a character whose direction
                matches the line's writing direction.

    @param      line
                The line from which the offset is requested.

    @param      charIndex
                The string index corresponding to the desired position.

    @param      secondaryOffset
                An output parameter that will be set to the secondary offset
                along the baseline for charIndex. When a single caret is
                sufficient for a string index, this value will be the same as
                the primary offset, which is the return value of this function.
                This parameter may be NULL.

    @result     The primary offset along the baseline for charIndex, or 0.0 in
                the event of failure.
*/

CGFloat CTLineGetOffsetForStringIndex(
    CTLineRef line,
    CFIndex charIndex,
    CGFloat * _Nullable secondaryOffset ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


#if defined(__BLOCKS__)

/*!
    @function   CTLineEnumerateCaretOffsets
    @abstract   Enumerates caret offsets for characters in a line.

    @discussion The provided block is invoked once for each logical caret edge in the line, in left-to-right visual order.

    @param      block
                The offset parameter is relative to the line origin. The leadingEdge parameter of this block refers to logical order.
*/

void CTLineEnumerateCaretOffsets(
    CTLineRef line,
    void (^block)(double offset, CFIndex charIndex, bool leadingEdge, bool* stop) ) CT_AVAILABLE(macos(10.11), ios(9.0), watchos(2.0), tvos(9.0));
```

###### 4、  `CTRunRef`  


```
/** 或者叫做 Glyph Run，是一组共享想相同attributes（属性）的字形的集合体
 */
typedef const struct CF_BRIDGED_TYPE(id) __CTRun * CTRunRef;

/*!
    @enum       CTRunStatus
    @abstract   A bitfield passed back by CTRunGetStatus that is used to
                indicate the disposition of the run.

    @constant   kCTRunStatusNoStatus
                The run has no special attributes.

    @constant   kCTRunStatusRightToLeft
                When set, the run is right to left.

    @constant   kCTRunStatusNonMonotonic
                When set, the run has been reordered in some way such that
                the string indices associated with the glyphs are no longer
                strictly increasing (for left to right runs) or decreasing
                (for right to left runs).

    @constant   kCTRunStatusHasNonIdentityMatrix
                When set, the run requires a specific text matrix to be set
                in the current CG context for proper drawing.
*/

typedef CF_OPTIONS(uint32_t, CTRunStatus)
{
    kCTRunStatusNoStatus = 0,
    kCTRunStatusRightToLeft = (1 << 0),
    kCTRunStatusNonMonotonic = (1 << 1),
    kCTRunStatusHasNonIdentityMatrix = (1 << 2)
};

 
/*!
    @function   CTRunGetTypeID
    @abstract   Returns the CFType of the run object
*/

CFTypeID CTRunGetTypeID( void ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/* --------------------------------------------------------------------------- */
/* Glyph Run Access */
/* --------------------------------------------------------------------------- */

/*!
    @function   CTRunGetGlyphCount
    @abstract   Gets the glyph count for the run.

    @param      run
                The run whose glyph count you wish to access.

    @result     The number of glyphs that the run contains. It is totally
                possible that this function could return a value of zero,
                indicating that there are no glyphs in this run.
*/

CFIndex CTRunGetGlyphCount(
    CTRunRef run ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTRunGetAttributes
    @abstract   Returns the attribute dictionary that was used to create the
                glyph run.

    @discussion This dictionary returned is either the same exact one that was
                set as an attribute dictionary on the original attributed string
                or a dictionary that has been manufactured by the layout engine.
                Attribute dictionaries can be manufactured in the case of font
                substitution or if they are missing critical attributes.

    @param      run
                The run whose attributes you wish to access.

    @result     The attribute dictionary.
*/

CFDictionaryRef CTRunGetAttributes(
    CTRunRef run ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTRunGetStatus
    @abstract   Returns the run's status.

    @discussion In addition to attributes, runs also have status that can be
                used to expedite certain operations. Knowing the direction and
                ordering of a run's glyphs can aid in string index analysis,
                whereas knowing whether the positions reference the identity
                text matrix can avoid expensive comparisons. Note that this
                status is provided as a convenience, since this information is
                not strictly necessary but can certainly be helpful.

    @param      run
                The run whose status you wish to access.

    @result     The run's status.
*/

CTRunStatus CTRunGetStatus(
    CTRunRef run ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTRunGetGlyphsPtr
    @abstract   Returns a direct pointer for the glyph array stored in the run.

    @discussion The glyph array will have a length equal to the value returned by
                CTRunGetGlyphCount. The caller should be prepared for this
                function to return NULL even if there are glyphs in the stream.
                Should this function return NULL, the caller will need to
                allocate their own buffer and call CTRunGetGlyphs to fetch the
                glyphs.

    @param      run
                The run whose glyphs you wish to access.

    @result     A valid pointer to an array of CGGlyph structures or NULL.
*/

const CGGlyph * _Nullable CTRunGetGlyphsPtr(
    CTRunRef run ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTRunGetGlyphs
    @abstract   Copies a range of glyphs into user-provided buffer.

    @param      run
                The run whose glyphs you wish to copy.

    @param      range
                The range of glyphs to be copied, with the entire range having a
                location of 0 and a length of CTRunGetGlyphCount. If the length
                of the range is set to 0, then the operation will continue from
                the range's start index to the end of the run.

    @param      buffer
                The buffer where the glyphs will be copied to. The buffer must be
                allocated to at least the value specified by the range's length.
*/

void CTRunGetGlyphs(
    CTRunRef run,
    CFRange range,
    CGGlyph buffer[_Nonnull] ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTRunGetPositionsPtr
    @abstract   Returns a direct pointer for the glyph position array stored in
                the run.

    @discussion The glyph positions in a run are relative to the origin of the
                line containing the run. The position array will have a length
                equal to the value returned by CTRunGetGlyphCount. The caller
                should be prepared for this function to return NULL even if there
                are glyphs in the stream. Should this function return NULL, the
                caller will need to allocate their own buffer and call
                CTRunGetPositions to fetch the positions.

    @param      run
                The run whose positions you wish to access.

    @result     A valid pointer to an array of CGPoint structures or NULL.
*/

const CGPoint * _Nullable CTRunGetPositionsPtr(
    CTRunRef run ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTRunGetPositions
    @abstract   Copies a range of glyph positions into a user-provided buffer.

    @discussion The glyph positions in a run are relative to the origin of the
                line containing the run.

    @param      run
                The run whose positions you wish to copy.

    @param      range
                The range of glyph positions to be copied, with the entire range
                having a location of 0 and a length of CTRunGetGlyphCount. If the
                length of the range is set to 0, then the operation will continue
                from the range's start index to the end of the run.

    @param      buffer
                The buffer where the glyph positions will be copied to. The buffer
                must be allocated to at least the value specified by the range's
                length.
*/

void CTRunGetPositions(
    CTRunRef run,
    CFRange range,
    CGPoint buffer[_Nonnull] ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTRunGetAdvancesPtr
    @abstract   Returns a direct pointer for the glyph advance array stored in
                the run.

    @discussion The advance array will have a length equal to the value returned
                by CTRunGetGlyphCount. The caller should be prepared for this
                function to return NULL even if there are glyphs in the stream.
                Should this function return NULL, the caller will need to
                allocate their own buffer and call CTRunGetAdvances to fetch the
                advances. Note that advances alone are not sufficient for correctly
                positioning glyphs in a line, as a run may have a non-identity
                matrix or the initial glyph in a line may have a non-zero origin;
                callers should consider using positions instead.

    @param      run
                The run whose advances you wish to access.

    @result     A valid pointer to an array of CGSize structures or NULL.
*/

const CGSize * _Nullable CTRunGetAdvancesPtr(
    CTRunRef run ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTRunGetAdvances
    @abstract   Copies a range of glyph advances into a user-provided buffer.

    @param      run
                The run whose advances you wish to copy.

    @param      range
                The range of glyph advances to be copied, with the entire range
                having a location of 0 and a length of CTRunGetGlyphCount. If the
                length of the range is set to 0, then the operation will continue
                from the range's start index to the end of the run.

    @param      buffer
                The buffer where the glyph advances will be copied to. The buffer
                must be allocated to at least the value specified by the range's
                length.
*/

void CTRunGetAdvances(
    CTRunRef run,
    CFRange range,
    CGSize buffer[_Nonnull] ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTRunGetStringIndicesPtr
    @abstract   Returns a direct pointer for the string indices stored in the run.

    @discussion The indices are the character indices that originally spawned the
                glyphs that make up the run. They can be used to map the glyphs in
                the run back to the characters in the backing store. The string
                indices array will have a length equal to the value returned by
                CTRunGetGlyphCount. The caller should be prepared for this
                function to return NULL even if there are glyphs in the stream.
                Should this function return NULL, the caller will need to allocate
                their own buffer and call CTRunGetStringIndices to fetch the
                indices.

    @param      run
                The run whose string indices you wish to access.

    @result     A valid pointer to an array of CFIndex structures or NULL.
*/

const CFIndex * _Nullable CTRunGetStringIndicesPtr(
    CTRunRef run ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTRunGetStringIndices
    @abstract   Copies a range of string indices int o a user-provided buffer.

    @discussion The indices are the character indices that originally spawned the
                glyphs that make up the run. They can be used to map the glyphs
                in the run back to the characters in the backing store.

    @param      run
                The run whose string indices you wish to copy.

    @param      range
                The range of string indices to be copied, with the entire range
                having a location of 0 and a length of CTRunGetGlyphCount. If the
                length of the range is set to 0, then the operation will continue
                from the range's start index to the end of the run.

    @param      buffer
                The buffer where the string indices will be copied to. The buffer
                must be allocated to at least the value specified by the range's
                length.
*/

void CTRunGetStringIndices(
    CTRunRef run,
    CFRange range,
    CFIndex buffer[_Nonnull] ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTRunGetStringRange
    @abstract   Gets the range of characters that originally spawned the glyphs
                in the run.

    @param      run
                The run whose string range you wish to access.

    @result     Returns the range of characters that originally spawned the
                glyphs. If run is invalid, this will return an empty range.
*/

CFRange CTRunGetStringRange(
    CTRunRef run ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTRunGetTypographicBounds
    @abstract   Gets the typographic bounds of the run.

    @param      run
                The run that you want to calculate the typographic bounds for.

    @param      range
                The range of glyphs to be measured, with the entire range having
                a location of 0 and a length of CTRunGetGlyphCount. If the length
                of the range is set to 0, then the operation will continue from
                the range's start index to the end of the run.

    @param      ascent
                Upon return, this parameter will contain the ascent of the run.
                This may be set to NULL if not needed.

    @param      descent
                Upon return, this parameter will contain the descent of the run.
                This may be set to NULL if not needed.

    @param      leading
                Upon return, this parameter will contain the leading of the run.
                This may be set to NULL if not needed.

    @result     The typographic width of the run. If run or range is
                invalid, then this function will always return zero.
*/

double CTRunGetTypographicBounds(
    CTRunRef run,
    CFRange range,
    CGFloat * _Nullable ascent,
    CGFloat * _Nullable descent,
    CGFloat * _Nullable leading ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTRunGetImageBounds
    @abstract   Calculates the image bounds for a glyph range.

    @discussion The image bounds for a run is the union of all non-empty glyph
                bounding rects, each positioned as it would be if drawn using
                CTRunDraw using the current context (for clients linked against
                macOS High Sierra or iOS 11 and later) or the text position of
                the supplied context (for all others). Note that the result is
                ideal and does not account for raster coverage due to rendering.
                This function is purely a convenience for using glyphs as an
                image and should not be used for typographic purposes.

    @param      run
                The run that you want to calculate the image bounds for.

    @param      context
                The context which the image bounds will be calculated for or NULL,
                in which case the bounds are relative to CGPointZero.

    @param      range
                The range of glyphs to be measured, with the entire range having
                a location of 0 and a length of CTRunGetGlyphCount. If the length
                of the range is set to 0, then the operation will continue from
                the range's start index to the end of the run.

    @result     A rect that tightly encloses the paths of the run's glyphs. The
                rect origin will match the drawn position of the requested range;
                that is, it will be translated by the supplied context's text
                position and the positions of the individual glyphs. If the run
                or range is invalid, CGRectNull will be returned.

    @seealso    CTRunGetTypographicBounds
*/

CGRect CTRunGetImageBounds(
    CTRunRef run,
    CGContextRef _Nullable context,
    CFRange range ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTRunGetTextMatrix
    @abstract   Returns the text matrix needed to draw this run.

    @discussion To properly draw the glyphs in a run, the fields 'tx' and 'ty' of
                the CGAffineTransform returned by this function should be set to
                the current text position.

    @param      run
                The run object from which to get the text matrix.

    @result     A CGAffineTransform.
*/

CGAffineTransform CTRunGetTextMatrix(
    CTRunRef run ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));


/*!
    @function   CTRunGetBaseAdvancesAndOrigins
    @abstract   Copies a range of base advances and/or origins into user-provided
                buffers.

    @discussion A run's base advances and origins determine the positions of its
                glyphs but require additional processing before being used for
                drawing. Similar to the advances returned by CTRunGetAdvances,
                base advances are the displacement from the origin of a glyph
                to the origin of the next glyph, except base advances do not
                include any positioning the font layout tables may have done
                relative to another glyph (such as a mark relative to its base).
                The actual position of the current glyph is determined by the
                displacement of its origin from the starting position, and the
                position of the next glyph by the displacement of the current
                glyph's base advance from the starting position.

    @param      runRef
                The run whose base advances and/or origins you wish to copy.

    @param      range
                The range of values to be copied. If the length of the
                range is set to 0, then the copy operation will continue from the
                range's start index to the end of the run.

    @param      advancesBuffer
                The buffer where the base advances will be copied to, or NULL.
                If not NULL, the buffer must allow for at least as many elements
                as specified by the range's length.

    @param      originsBuffer
                The buffer where the origins will be copied to, or NULL. If not
                NULL, the buffer must allow for at least as many elements as
                specified by the range's length.
*/

void CTRunGetBaseAdvancesAndOrigins(
    CTRunRef runRef,
    CFRange range,
    CGSize advancesBuffer[_Nullable],
    CGPoint originsBuffer[_Nullable] ) CT_AVAILABLE(macos(10.11), ios(9.0), watchos(2.0), tvos(9.0));


/*!
    @function   CTRunDraw
    @abstract   Draws a complete run or part of one.

    @discussion This is a convenience call, since the run could also be drawn by
                accessing its glyphs, positions, and text matrix. Unlike when
                drawing the entire line containing the run with CTLineDraw, the
                run's underline (if any) will not be drawn, since the underline's
                appearance may depend on other runs in the line. This call may
                leave the graphics context in any state and does not flush the
                context after drawing. This call also expects a text matrix with
                `y` values increasing from bottom to top; a flipped text matrix
                may result in misplaced diacritics.

    @param      run
                The run that you want to draw.

    @param      context
                The context to draw the run to.

    @param      range
                The range of glyphs to be drawn, with the entire range having a
                location of 0 and a length of CTRunGetGlyphCount. If the length
                of the range is set to 0, then the operation will continue from
                the range's start index to the end of the run.
*/
void CTRunDraw(
    CTRunRef run,
    CGContextRef context,
    CFRange range ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));
```
