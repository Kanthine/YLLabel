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
        self.backgroundColor = UIColor.clearColor;
        _label = [[YLLabel alloc] init];
        [self.contentView addSubview:_label];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    _label.frame = self.contentView.bounds;
}

- (void)setModel:(YLPageModel *)model{
    self.label.content = model.content;
    self.label.frameRef = model.frameRef;
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
        self.scrollDirection = UICollectionViewScrollDirectionVertical;
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        return CGSizeMake(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    }else{
        return CGSizeMake(CGRectGetWidth(self.bounds), self.pageModelsArray[indexPath.row].contentHeight);
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
    [self.collectionView reloadData];
}

- (void)setPageModelsArray:(NSMutableArray<YLPageModel *> *)pageModelsArray{
    _pageModelsArray = pageModelsArray;
    [self.collectionView reloadData];
}

- (void)setScrollDirection:(UICollectionViewScrollDirection)scrollDirection{
    ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).scrollDirection = scrollDirection;
    
    if (self.scrollDirection == UICollectionViewScrollDirectionVertical) {
        self.collectionView.pagingEnabled = NO;
    }else{
        self.collectionView.pagingEnabled = YES;
    }
    
    [self.collectionView reloadData];
}

- (UICollectionViewScrollDirection)scrollDirection{
    return ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).scrollDirection;
}

- (UICollectionView *)collectionView{
    if (_collectionView == nil){
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.minimumLineSpacing = 0.1;
        flowLayout.minimumInteritemSpacing = 0.1;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:UIScreen.mainScreen.bounds collectionViewLayout:flowLayout];
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = UIColor.clearColor;
        [_collectionView registerClass:[YLPageCollectionCell class] forCellWithReuseIdentifier:@"YLPageCollectionCell"];
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _collectionView;
}

@end
