//
//  YLSheetView.h
//  YLLabel
//
//  Created by 苏沫离 on 2020/9/1.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface YLSheetView : UIView

@property (nonatomic ,strong) UIButton *coverButton;
@property (nonatomic ,strong) UIView *contentView;
@property (nonatomic ,strong) UIButton *cancelButton;
@property (nonatomic ,strong) NSArray<NSString *> *itemArray;
@property (nonatomic ,copy) void(^didSelectedBlock)(NSString *item);

+ (void)showWithHandle:(void(^)(NSString *item))handle;

@end
NS_ASSUME_NONNULL_END
