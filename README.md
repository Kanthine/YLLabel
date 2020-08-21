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

//使用省略号对 CTLine 进行截断的规则
typedef CF_ENUM(uint32_t, CTLineTruncationType) {
    kCTLineTruncationStart  = 0, // 省略号在开头
    kCTLineTruncationEnd    = 1, // 省略号在结尾
    kCTLineTruncationMiddle = 2  // 省略号在中间
};

///Returns the CFType of the line object
CFTypeID CTLineGetTypeID(void);

/** 使用富文本创建 CTLineRef 对象
    @discussion 
    这将允许需要非常简单的行生成的客户端创建一个行，而不需要创建一个typesetter对象。
    排版 typesetting 将在引擎盖 hood 下面进行。
    如果没有 typesetter 对象，就不能正确地断行。但是，对于简单的东西，比如文本标签和其他东西，这不是一个问题。
*/
CTLineRef CTLineCreateWithAttributedString(CFAttributedStringRef attrString);

/** 将现有 CTLineRef 截断并返回一个新的对象
 * @param line 需要截断的行
 * @param width 截断宽度：如果行宽大于截断宽度，则该行将被截断
 * @param truncationType 截断类型
 * @param truncationToken 截断用的填充符号，通常是省略号 ... ，为Null时则只截断，不做填充
 *                        该填充符号的宽度必须小于截断宽度，否则该函数返回 NULL；
 */
CTLineRef _Nullable CTLineCreateTruncatedLine(CTLineRef line,double width,
          CTLineTruncationType truncationType,CTLineRef _Nullable truncationToken);

/** 两端对齐：填充空白符，文字之间等间距
 * @param line 需要对齐的行
 * @param justificationFactor 调整系数，取值范围 [0,1] ； <= 0 时不执行对齐； >=1 时执行完全调整；
 *                   假如文字长度是100，限定宽度是300，则填充的空白区域为 200*justificationFactor 
 * @param justificationWidth 目标宽度，如果 line 的宽度超过了 justificationWidth ，那么文本将被压缩
 *                                                                             或者返回NULL？       
 */
CTLineRef _Nullable CTLineCreateJustifiedLine(CTLineRef line,CGFloat justificationFactor,double justificationWidth );

/** 对齐文本：通过偏移对齐
 * @param flushFactor (0.0,1.0) 0表示靠左，1表示靠右，0.5表示居中 ;
 * @param flushWidth 对齐的宽度
 */
double CTLineGetPenOffsetForFlush(CTLineRef line,CGFloat flushFactor,double flushWidth);

/// 获取字形数量
CFIndex CTLineGetGlyphCount(CTLineRef line);

/// 获取所有的 glyphRuns 
CFArrayRef CTLineGetGlyphRuns(CTLineRef line);

/// 获取创建 CTLine 的字形的 rang ；失败则返回 empty range 
CFRange CTLineGetStringRange(CTLineRef line);

/** CTLine 可以直接绘制
 * @param line 待绘制的行 
 * @param context 上下文
 * @discussion CGContextSetTextPosition() 设置的位置对CTFrameDraw()没有作用，但是和CTLineDraw() 配合使用则效果非常好
 */
void CTLineDraw(CTLineRef line,CGContextRef context);

/** 获取一个CTLine的宽、高等字形度量
 * @param ascent  上行高度；回调函数，如果不需要，可以将其设置为NULL。
 * @param descent 下行高度；基线距字体中最低的字形底部的距离，是一个负值
 * @param leading 行距
 * @result 行宽；如果行无效，则返回 0
 * @discussion 行高 lineHeight = ascent + |descent| + linegap
 */
double CTLineGetTypographicBounds(CTLineRef line,CGFloat * _Nullable ascent,
                    CGFloat * _Nullable descent,CGFloat * _Nullable leading);

/** 获取一行文本的 bounds，坐标原点与 CTLineRef 原点重合，矩形原点位于左下角
 * @param options 一般填 0
 * @result 如果行无效，将返回CGRectNull
 */
CGRect CTLineGetBoundsWithOptions(CTLineRef line,CTLineBoundsOptions options);

/// 获取一行未尾字符后空格的像素长度。如 "abc  " 后面有两个空格，返回的就是这两个空格占有的像素宽度
double CTLineGetTrailingWhitespaceWidth(CTLineRef line);

/** 计算该行文字绘制成图像所需要的最小 bounds
 * @param context 计算图像 bounds 的上下文，可以传 NULL；
 * @discussion 计算这行文字绘制成图片所需要的最小 size，没有各种边距，是一种是尽可能小的理想状态的size
 * @result 如果行无效，将返回CGRectNull
 */
CGRect CTLineGetImageBounds(CTLineRef line,CGContextRef _Nullable context);


/* --------------------------------------------------------------------------- */
/* 行插入符号定位和高亮显示 */
/* --------------------------------------------------------------------------- */

/** 处理点击事件的字符串索引：传入行信息和位置信息，计算出该位置对应的字符索引
 * @param position 点击相对于 line's origin 的位置
 * @result 如果失败，返回kCFNotFound
 * @discussion 相对于该行的字符串范围，返回值将不小于第一个字符串索引，且不大于最后一个字符串索引 + 1
 */
CFIndex CTLineGetStringIndexForPosition(CTLineRef line,CGPoint position);


/** 计算当行中，指定索引的字符的相对 x 原点的偏移量
 * @param charIndex 待计算字符的字符串索引
 * @discussion 
 
 此函数返回与字符串索引对应的图形偏移量，该图形偏移量适用于在相邻行之间移动或绘制自定义插入符号。
 对于前者，可针对两行的任何相对缩进调整主偏移量;用调整过的x值偏移量和0.0的y值构造的CGPoint适合传递给CTLineGetStringIndexForPosition。
 在这两种情况下，主偏移量都对应于插入符号中表示方向与该行写入方向相匹配的字符的可视插入位置的部分。

    @param secondaryOffset
    
一个输出参数，它将被设置为charIndex沿着基线的辅助偏移量。
当单个插入符号足以用于字符串索引时，此值将与主偏移量相同，主偏移量是此函数的返回值。
此参数可以为 NULL 
    
An output parameter that will be set to the secondary offset along the baseline for charIndex.
When a single caret is sufficient for a string index, this value will be the same as the primary offset, which is the return value of this function.                
This parameter may be NULL.
            
获取一行文字中，指定charIndex字符相对x原点的偏移量，返回值与secondaryOffset同为一个值。
如果charIndex超出一行的字符长度则反回最大长度结束位置的偏移量，如一行文字共有17个字符，哪么返回的是第18个字符的起始偏移，即第17个偏移+第17个字符占有的宽度=第18个起始位置的偏移。
因此想求一行字符所占的像素长度时，就可以使用此函数，将charIndex设置为大于字符长度即可。
*/
CGFloat CTLineGetOffsetForStringIndex(CTLineRef line, CFIndex charIndex,CGFloat * _Nullable secondaryOffset);

/** 遍历一行中字符的脱字符偏移量
 * @discussion The provided block is invoked once for each logical caret edge in the line, in left-to-right visual order.
 * @param block 偏移量 offset 是相对于 CTLineRe f原点；参数 leadingEdge指的是逻辑顺序
 */
void CTLineEnumerateCaretOffsets(CTLineRef line,
       void (^block)(double offset, CFIndex charIndex, bool leadingEdge, bool* stop));
```


###### case1、 获取一行文本的Rect

```
///获取一行文本的Rect
+ (CGRect)getLineBounds:(CTLineRef)line point:(CGPoint)point {
    CGFloat ascent = 0.0f;
    CGFloat descent = 0.0f;
    CGFloat leading = 0.0f;
    CGFloat width = (CGFloat)CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    CGFloat height = ascent + fabs(descent) + leading;
    return CGRectMake(point.x, point.y - descent, width, height);
}
```

###### 4、  `CTRunRef`  


```
/** 或者叫做 Glyph Run，是一组共享想相同attributes（属性）的字形的集合体
 */
typedef const struct CF_BRIDGED_TYPE(id) __CTRun * CTRunRef;

/// 由 CTRunGetStatus() 传回的位字段，用于指示 CTRunRef 的处理
typedef CF_OPTIONS(uint32_t, CTRunStatus){
    kCTRunStatusNoStatus = 0, /// 没有特殊的属性 attributes
    kCTRunStatusRightToLeft = (1 << 0), /// 设置文本从右向左书写
    kCTRunStatusNonMonotonic = (1 << 1), ///以某种方式重新排序，字符串索引不再严格地从左到右的递增或从右到左的递减
    kCTRunStatusHasNonIdentityMatrix = (1 << 2) /// CTRunRef 需要在当前 CGContext 中设置一个特定的文本矩阵来进行适当的绘图
};

/*!
    @function   CTRunGetTypeID
    @abstract   Returns the CFType of the run object
*/
CFTypeID CTRunGetTypeID(void);


/* --------------------------------------------------------------------------- */
/* 访问 Glyph Run  */
/* --------------------------------------------------------------------------- */


///获取 CTRunRef 的字形个数；返回 0 表示 CTRunRef 中没有任何符号
CFIndex CTRunGetGlyphCount(CTRunRef run);

/// 获取 CTRunRef 的属性
CFDictionaryRef CTRunGetAttributes(CTRunRef run);


/** 获取 CTRunRef 的状态
 * @discussion 除了属性 attributes 之外，CTRunRef 还具有可用于加快某些操作的状态：
 *             知道 CTRunRef 的方向和顺序可以为字符串索引分析提供帮助；
 *             知道位置是否引用标识文本矩阵可以避免额外比较；
 * @note 该状态不是严格必要的，仅仅是为了方便
 */
CTRunStatus CTRunGetStatus(CTRunRef run);


/** 获取一个指针数组：用于存储在 CTRunRef 中的字形
 * @discussion 该数组的长度将等于CTRunGetGlyphCount() 返回的值；
 *     如果返回NULL，需要开发者分配缓冲区，并调用CTRunGetGlyphs() 来获取字形    
 */
const CGGlyph * _Nullable CTRunGetGlyphsPtr(CTRunRef run);

/** 将指定范围的字形复制到用户提供的缓冲区中
 * @param range 指定范围；如果 range.location = 0 ，range.length = CTRunGetGlyphCount ,则全部复制
 *                      如果 range.length = 0 ,则从 range.location 开始复制到结尾；
 * @param buffer 缓冲区，长度要足够使用
*/
void CTRunGetGlyphs(CTRunRef run,CFRange range,CGGlyph buffer[_Nonnull]);

/** 获取存储在 CTRunRef 中的每个字形的位置：相对于 CTRunRef 所在行的原点的位置
 * @discussion 如果返回 NULL，需要开发者分配缓冲区，并调用 CTRunGetPositions() 来获取字形位置；
 */
const CGPoint * _Nullable CTRunGetPositionsPtr(CTRunRef run);

/// 获取（拷贝）存储在 CTRunRef 中的指定范围的字形的位置
void CTRunGetPositions(CTRunRef run,CFRange range,CGPoint buffer[_Nonnull]);

/** 获取在 CTRunRef 中存储的字形 advance 数组
 * @discussion 如果返回 NULL，需要开发者分配缓冲区，并调用 CTRunGetAdvances() 来获取 advance;
 * @note 仅靠 advances 并不足以在一行中正确地定位字形，因为 CTRunRef 可能具有非单位矩阵，或者该行的 origin 可能是非零原点;
 */
const CGSize * _Nullable CTRunGetAdvancesPtr(CTRunRef run);

/// 获取（拷贝）存储在 CTRunRef 中的指定范围的字形的 advance
void CTRunGetAdvances(CTRunRef run,CFRange range,CGSize buffer[_Nonnull]);

/** 获取在 CTRunRef 中存储的字形索引（CFIndex）的指针数组
 * @discussion 如果返回 NULL，需要开发者分配缓冲区，并调用 CTRunGetStringIndices() 来获取索引;
 *             它们可用于将 CTRunRef 中的字形映射到后备存储区中的字形；
 */
const CFIndex * _Nullable CTRunGetStringIndicesPtr(CTRunRef run);

/// 获取（拷贝）存储在 CTRunRef 中的指定范围的字形的索引
void CTRunGetStringIndices(CTRunRef run,CFRange range,CFIndex buffer[_Nonnull]);

///获取用于创建 CTRunRef 的字符范围
CFRange CTRunGetStringRange(CTRunRef run);


/** 获取 CTRunRef 的指定范围的字符的排版边界
 * @param range 指定范围；如果 range.location = 0 ，range.length = CTRunGetGlyphCount ,则是整个 CTRunRef；
 *                      如果 range.length = 0 ,则从 range.location 开始复制到结尾；
 * @param ascent  上行高度；回调函数，如果不需要，可以将其设置为NULL。
 * @param descent 下行高度；基线距字体中最低的字形底部的距离，是一个负值
 * @param leading 行距
 * @result 排版宽度；如果 CTRunRef 或 CFRange 无效，则返回 0
 * @discussion 行高 lineHeight = ascent + |descent| + linegap      
 */
double CTRunGetTypographicBounds(CTRunRef run, CFRange range, CGFloat * _Nullable ascent,
                                 CGFloat * _Nullable descent,CGFloat * _Nullable leading);

/** 计算 CTRunRef 中指定范围的字形绘制成图像所需要的 bounds ：一个紧密包含字形的边界
 * @param context 计算图像 bounds 的上下文，可以传 NULL；
 * @discussion 计算这行文字绘制成图片所需要的最小 size，没有各种边距，是一种是尽可能小的理想状态的size
 * @result 如果行无效，将返回 CGRectNull；
 */
CGRect CTRunGetImageBounds(CTRunRef run,CGContextRef _Nullable context,CFRange range);


/** 获取绘制此 CTRunRef 所需的文本矩阵
 * @note 为了正确地绘制字形，该函数返回的 CGAffineTransform 的 tx 和 ty 应该为当前文本位置
 */
CGAffineTransform CTRunGetTextMatrix(CTRunRef run);

/** 获取（拷贝）存储在 CTRunRef 中的指定范围的字形的 advances 和 origins
 * @discussion CTRunRef 的 base advances 和 origins 决定字形的位置，在用于绘图之前需要进行额外的处理。
 *   当前字形的实际位置由其原点从起始位置的偏移量决定，而下一个字形的位置由当前字形base advance 从起始位置的偏移量决定。
 */
void CTRunGetBaseAdvancesAndOrigins(CTRunRef runRef,CFRange range,
            CGSize advancesBuffer[_Nullable],CGPoint originsBuffer[_Nullable]);


/** 绘制 CTRunRef 
 * @discussion 还可以通过访问其 glyphs、positions 和text matrix 来复杂的绘制 CTRunRef。
 *      与调用 CTLineDraw() 绘制包含 CTRun 的整个 CTLine 不同；
 *      CTRun 如果有下划线，将不会被绘制，因为下划线可能依赖于该 CTLine 中的其他CTRun；
*/
void CTRunDraw(CTRunRef run,CGContextRef context,CFRange range);
```
