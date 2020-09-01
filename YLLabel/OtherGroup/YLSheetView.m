//
//  YLSheetView.m
//  YLLabel
//
//  Created by 苏沫离 on 2020/9/1.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "YLSheetView.h"

@implementation YLSheetView

+ (void)showWithHandle:(void(^)(NSString *item))handle{
    YLSheetView *sheet = [[YLSheetView alloc] init];
    sheet.didSelectedBlock = handle;
    [sheet show];
}

- (instancetype)init{
    self = [super init];
    if (self){
        self.itemArray = YLReaderManager.shareReader.transitionTypes;
        self.frame = UIScreen.mainScreen.bounds;
        [self addSubview:self.coverButton];
        [self addSubview:self.contentView];
    }
    return self;
}

#pragma mark - public method

- (void)show{
    [UIApplication.sharedApplication.delegate.window addSubview:self];
    self.contentView.transform = CGAffineTransformMakeTranslation(0,CGRectGetHeight(self.contentView.bounds));
    self.coverButton.alpha = 0;
    [UIView animateWithDuration:0.20 animations:^{
        self.coverButton.alpha = 1.0;
        self.contentView.transform = CGAffineTransformIdentity;
    }];
}

- (void)dismissButtonClick{
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.2 animations:^{
        weakSelf.coverButton.alpha = 0;
        weakSelf.contentView.transform = CGAffineTransformMakeTranslation(0,CGRectGetHeight(weakSelf.contentView.bounds));
    } completion:^(BOOL finished) {
        [weakSelf.coverButton removeFromSuperview];
        weakSelf.coverButton = nil;
        [weakSelf.contentView removeFromSuperview];
        weakSelf.contentView = nil;
        [weakSelf removeFromSuperview];
    }];
}

- (void)handleButtonClick:(UIButton *)sender{
    if (self.didSelectedBlock) {
        self.didSelectedBlock(self.itemArray[sender.tag]);
    }
    [self dismissButtonClick];
}

#pragma mark - getter and setter

- (UIButton *)coverButton{
    if (_coverButton == nil) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        [button addTarget:self action:@selector(dismissButtonClick) forControlEvents:UIControlEventTouchUpInside];
        button.frame = UIScreen.mainScreen.bounds;
        _coverButton = button;
    }
    return _coverButton;
}

- (UIView *)contentView{
    if (_contentView == nil) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(UIScreen.mainScreen.bounds), 124)];
        view.backgroundColor = UIColor.whiteColor;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(UIScreen.mainScreen.bounds), 30)];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"翻页方式";
        label.textColor = UIColor.blackColor;
        label.font = [UIFont systemFontOfSize:15];
        [view addSubview:label];

        [self.itemArray enumerateObjectsUsingBlock:^(NSString * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.tag = idx;
            [button addTarget:self action:@selector(handleButtonClick:) forControlEvents:UIControlEventTouchUpInside];
            button.frame = CGRectMake(12, 30 + 40 * idx, CGRectGetWidth(view.bounds) - 12 * 2.0, 40);
            button.titleLabel.font = [UIFont systemFontOfSize:15];
            [button setTitleColor:[UIColor colorWithRed:52/255.0 green:52/255.0 blue:52/255.0 alpha:1.0] forState:UIControlStateNormal];
            if ([item isEqualToString:YLReaderManager.shareReader.currentTransition]) {
                [button setTitleColor:UIColor.redColor forState:UIControlStateNormal];
            }
            [button setTitle:item forState:UIControlStateNormal];
            [view addSubview:button];
        }];
            
        
        CGFloat height = 30 + 40 * self.itemArray.count + 34;
        view.frame = CGRectMake(0, CGRectGetHeight(UIScreen.mainScreen.bounds) - height, CGRectGetWidth(UIScreen.mainScreen.bounds), height);
        
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:view.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(10,10)];
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = view.bounds;
        maskLayer.path = maskPath.CGPath;
        view.layer.mask = maskLayer;
        _contentView = view;
    }
    return _contentView;
}

@end

