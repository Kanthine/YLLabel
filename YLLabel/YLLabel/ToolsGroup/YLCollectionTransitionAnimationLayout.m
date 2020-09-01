//
//  YLCollectionTransitionAnimationLayout.m
//  CollectionLayout
//
//  Created by 苏沫离 on 2020/8/28.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "YLCollectionTransitionAnimationLayout.h"


#pragma mark - 动画操作者

///基类
@interface YLCollectionTransitionAnimationOperator : NSObject
///动画
- (void)transitionAnimationWithCollectionView:(UICollectionView *)collectionView attributes:(YLCollectionTransitionAnimationAttributes *)attributes;
@end
@implementation YLCollectionTransitionAnimationOperator
- (void)transitionAnimationWithCollectionView:(UICollectionView *)collectionView attributes:(YLCollectionTransitionAnimationAttributes *)attributes{}
@end


/// None 效果
@interface YLCollectionNoneAnimation : YLCollectionTransitionAnimationOperator
@end
@implementation YLCollectionNoneAnimation

- (void)transitionAnimationWithCollectionView:(UICollectionView *)collectionView attributes:(YLCollectionTransitionAnimationAttributes *)attributes{
    attributes.frame = CGRectMake(collectionView.contentOffset.x, collectionView.contentOffset.y, CGRectGetWidth(attributes.frame), CGRectGetHeight(attributes.frame));
    if (attributes.middleOffset < 0) {
        attributes.zIndex = 1000 + attributes.middleOffset;
    }else{
        attributes.zIndex = 2000 - attributes.middleOffset;
    }
}

@end







/// 小说阅读器：覆盖翻页
@interface YLCollectionOpenAnimation : YLCollectionTransitionAnimationOperator
@end
@implementation YLCollectionOpenAnimation

- (void)transitionAnimationWithCollectionView:(UICollectionView *)collectionView attributes:(YLCollectionTransitionAnimationAttributes *)attributes{
    CGFloat position = attributes.middleOffset;
    CGPoint contentOffset = collectionView.contentOffset;
    if (attributes.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        if (position > 0) {
            attributes.frame = CGRectMake(contentOffset.x, attributes.frame.origin.y, CGRectGetWidth(attributes.frame), CGRectGetHeight(attributes.frame));
        }
    } else {
        if (position > 0) {
            attributes.frame = CGRectMake(attributes.frame.origin.x, contentOffset.y, CGRectGetWidth(attributes.frame), CGRectGetHeight(attributes.frame));
        }
    }
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:attributes.indexPath];
    cell.clipsToBounds = NO;
    cell.layer.shadowColor = [UIColor blackColor].CGColor; // 阴影颜色
    cell.layer.shadowOffset = CGSizeMake(0, 0); // 偏移距离
    cell.layer.shadowOpacity = 0.5; // 不透明度
    cell.layer.shadowRadius = 10.0; // 半径
    
    attributes.zIndex = 10000 - attributes.indexPath.row;
}

@end


/// 视觉差：移动 cell 的速度慢于单元格本身来实现视差效果
@interface YLCollectionParallaxAnimation : YLCollectionTransitionAnimationOperator
/// 速度越快，视差越明显：取值范围 [0,1]；默认 0.5 ，0表示无视差
@property (nonatomic ,assign) CGFloat speed;
@end

@implementation YLCollectionParallaxAnimation

- (instancetype)init{
    return [self initWithSpeed:0.2];
}

- (instancetype)initWithSpeed:(CGFloat)speed{
    self = [super init];
    if (self) {
        self.speed = speed;
    }
    return self;
}

- (void)transitionAnimationWithCollectionView:(UICollectionView *)collectionView attributes:(YLCollectionTransitionAnimationAttributes *)attributes{
    CGFloat position = attributes.middleOffset;
    if (fabs(position) >= 1) {
        attributes.contentView.frame = attributes.bounds;
    } else if (attributes.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        CGFloat width = CGRectGetWidth(collectionView.frame);
        CGFloat transitionX = -(width * self.speed * position);
        CGAffineTransform transform = CGAffineTransformMakeTranslation(transitionX, 0);
        CGRect newFrame = CGRectApplyAffineTransform(attributes.bounds, transform);
        attributes.contentView.frame = newFrame;
    } else {
        CGFloat height = CGRectGetHeight(collectionView.frame);
        CGFloat transitionY = -(height * self.speed * position);
        CGAffineTransform transform = CGAffineTransformMakeTranslation(0, transitionY);
        CGRect newFrame = CGRectApplyAffineTransform(attributes.bounds, transform);
        // 不使用 attributes.transform，因为如果在绑定方法中由于布局变化而对每个单元格调用 - layoutSubviews 会有问题
        attributes.contentView.frame = newFrame;
    }
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:attributes.indexPath];
    cell.clipsToBounds = YES;
    cell.layer.shadowColor = [UIColor clearColor].CGColor; // 阴影颜色
    cell.layer.shadowOffset = CGSizeMake(0, 0); // 偏移距离
    cell.layer.shadowOpacity = 0; // 不透明度
    cell.layer.shadowRadius = 0; // 半径
}

@end











@implementation YLCollectionTransitionAnimationAttributes

/// 需要实现这个方法，collectionView 实时布局时，会copy参数，确保自身的参数被copy
- (id)copyWithZone:(NSZone *)zone{
    YLCollectionTransitionAnimationAttributes *copy = [super copyWithZone:zone];
    if (copy) {
        copy.contentView = self.contentView;
        copy.scrollDirection = self.scrollDirection;
        copy.startOffset = self.startOffset;
        copy.middleOffset = self.middleOffset;
        copy.endOffset = self.endOffset;
    }
    return copy;
}

- (BOOL)isEqual:(id)object{
    if (![object isKindOfClass:YLCollectionTransitionAnimationAttributes.class]) {
        return NO;
    }
    YLCollectionTransitionAnimationAttributes *attributes = (YLCollectionTransitionAnimationAttributes *)object;
    return [super isEqual:object] &&
            self.contentView == attributes.contentView &&
            self.scrollDirection == attributes.scrollDirection &&
            self.startOffset == attributes.startOffset &&
            self.middleOffset == attributes.middleOffset &&
            self.endOffset == attributes.endOffset;
}

@end


@interface YLCollectionTransitionAnimationLayout ()

/// 过渡动画的执行者
@property (nonatomic ,strong) YLCollectionTransitionAnimationOperator *animationOperator;

@end



@implementation YLCollectionTransitionAnimationLayout

- (instancetype)init{
    self = [super init];
    if (self) {
        self.sectionInset = UIEdgeInsetsZero;
        self.minimumLineSpacing = 0.0;
        self.minimumInteritemSpacing = 0.0;
        
        ///默认
        _transitionType = YLCollectionTransitionNone;
        _animationOperator = [[YLCollectionNoneAnimation alloc] init];
    }
    return self;
}

- (void)setTransitionType:(YLCollectionTransitionType)transitionType{
    if (_transitionType != transitionType) {
        _transitionType = transitionType;
        
        switch (transitionType) {
            case YLCollectionTransitionNone:{
                self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
                _animationOperator = [[YLCollectionNoneAnimation alloc] init];
            }break;
            case YLCollectionTransitionOpen:{
                self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
                _animationOperator = [[YLCollectionOpenAnimation alloc] init];
            }break;
            case YLCollectionTransitionPan:{
                self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
                _animationOperator = [[YLCollectionParallaxAnimation alloc] initWithSpeed:0];
            }break;
            case YLCollectionTransitionScroll:{
                self.scrollDirection = UICollectionViewScrollDirectionVertical;
                _animationOperator = nil;
            }break;
            default:
                _animationOperator = nil;
                break;
        }
        [self invalidateLayout];
    }
}

+ (Class)layoutAttributesClass{
    return YLCollectionTransitionAnimationAttributes.class;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds{
    return YES;
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect{
    NSArray<YLCollectionTransitionAnimationAttributes *> *attributesArray = [super layoutAttributesForElementsInRect:rect];
    
    CGFloat distance = self.scrollDirection == UICollectionViewScrollDirectionVertical ? CGRectGetHeight(self.collectionView.frame) : CGRectGetWidth(self.collectionView.frame);
    [attributesArray enumerateObjectsUsingBlock:^(YLCollectionTransitionAnimationAttributes * _Nonnull attribute, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat itemOffset = 0.0;//偏移量
        if (self.scrollDirection == UICollectionViewScrollDirectionVertical) {
            itemOffset = attribute.center.y - self.collectionView.contentOffset.y;
            attribute.startOffset = (attribute.frame.origin.y - self.collectionView.contentOffset.y) / CGRectGetHeight(attribute.frame);
            attribute.endOffset = (attribute.frame.origin.y - self.collectionView.contentOffset.y - CGRectGetHeight(self.collectionView.frame)) / CGRectGetHeight(attribute.frame);
        }else{
            itemOffset = attribute.center.x - self.collectionView.contentOffset.x;
            attribute.startOffset = (attribute.frame.origin.x - self.collectionView.contentOffset.x) / CGRectGetWidth(attribute.frame);
            attribute.endOffset = (attribute.frame.origin.x - self.collectionView.contentOffset.x - CGRectGetWidth(self.collectionView.frame)) / CGRectGetWidth(attribute.frame);
        }
        
        attribute.scrollDirection = self.scrollDirection;
        attribute.middleOffset = itemOffset / distance - 0.5;
                
        if (attribute.contentView == nil){
            attribute.contentView = [self.collectionView cellForItemAtIndexPath:attribute.indexPath].contentView;
        }
        [self.animationOperator transitionAnimationWithCollectionView:self.collectionView attributes:attribute];
    }];
    return attributesArray;
}

@end
