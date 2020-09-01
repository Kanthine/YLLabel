//
//  YLPageLabel.m
//  YLLabel
//
//  Created by 苏沫离 on 2020/8/18.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "YLPageLabel.h"
#import "YLLabel.h"

@interface YLPageCollectionCell : UICollectionViewCell
@property (nonatomic ,strong) YLLabel *label;
@property (nonatomic ,strong) YLPageModel *model;
@end

@implementation YLPageCollectionCell

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self){
        self.backgroundColor = UIColor.whiteColor;
        _label = [[YLLabel alloc] init];
        [self.contentView addSubview:_label];
    }
    return self;
}

- (void)setModel:(YLPageModel *)model{
    _model = model;
    self.label.frameRef = model.frameRef;
    self.label.frame = CGRectMake(0, 0, CGRectGetWidth(self.contentView.bounds), _model.contentHeight);
}

@end



@interface YLPageLabel ()
<UICollectionViewDelegate,UICollectionViewDataSource,
YLLabelDelegate>

@property (nonatomic ,strong) UICollectionView *collectionView;
@property (nonatomic ,strong) NSMutableArray<YLLabel *> *labelsArray;

@end

@implementation YLPageLabel

- (instancetype)init{
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        [self addSubview:self.collectionView];
    }
    return self;
}

#pragma mark - YLLabelDelegate

- (void)touchYLLabel:(YLLabel *)label url:(NSString *)url{
    if (self.delegate && [self.delegate respondsToSelector:@selector(touchYLPageLabel:url:)]) {
        [self.delegate touchYLPageLabel:self url:url];
    }
}

#pragma mark - UICollectionViewDelegate

- (void)scrollToPage{
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:YLReaderManager.shareReader.page inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (self.transitionType == YLCollectionTransitionScroll) {
        
    }else{
        YLReaderManager.shareReader.page = (NSInteger)scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds);
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (self.transitionType == YLCollectionTransitionScroll) {
        return CGSizeMake(CGRectGetWidth(collectionView.bounds), self.pageModelsArray[indexPath.row].contentHeight);
    }else{
        return CGSizeMake(CGRectGetWidth(collectionView.bounds), CGRectGetHeight(collectionView.bounds));
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.pageModelsArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    YLPageCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YLPageCollectionCell" forIndexPath:indexPath];
    cell.model = self.pageModelsArray[indexPath.row];
    cell.label.delegate = self;
    return cell;
}

#pragma mark - setter and getter

- (void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    self.collectionView.frame = self.bounds;
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self.collectionView reloadData];
}

- (void)setPageModelsArray:(NSMutableArray<YLPageModel *> *)pageModelsArray{
    _pageModelsArray = pageModelsArray;
    [self.collectionView reloadData];
}

- (void)setTransitionType:(YLCollectionTransitionType)transitionType{
    YLCollectionTransitionAnimationLayout *transitionLayout = (YLCollectionTransitionAnimationLayout *)self.collectionView.collectionViewLayout;
    transitionLayout.transitionType = transitionType;
    if (transitionType == YLCollectionTransitionScroll) {
        self.collectionView.pagingEnabled = NO;
    }else{
        self.collectionView.pagingEnabled = YES;
    }
    [self.collectionView reloadData];
}

- (YLCollectionTransitionType)transitionType{
    YLCollectionTransitionAnimationLayout *transitionLayout = (YLCollectionTransitionAnimationLayout *)self.collectionView.collectionViewLayout;
    return transitionLayout.transitionType;
}

- (UICollectionView *)collectionView{
    if (_collectionView == nil){
        YLCollectionTransitionAnimationLayout *flowLayout = [[YLCollectionTransitionAnimationLayout alloc] init];
        flowLayout.transitionType = YLCollectionTransitionOpen;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:UIScreen.mainScreen.bounds collectionViewLayout:flowLayout];
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.pagingEnabled = YES;
        _collectionView.backgroundColor = UIColor.clearColor;
        [_collectionView registerClass:[YLPageCollectionCell class] forCellWithReuseIdentifier:@"YLPageCollectionCell"];
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _collectionView;
}

@end
