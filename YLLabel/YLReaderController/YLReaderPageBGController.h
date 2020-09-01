//
//  YLReaderPageBGController.h
//  YLLabel
//
//  Created by 苏沫离 on 2020/9/1.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YLReaderPageBGController : UIViewController
/// 目标视图(无值则跟阅读背景颜色保持一致)
@property (nonatomic ,strong) UIView *targetView;

@end

NS_ASSUME_NONNULL_END
