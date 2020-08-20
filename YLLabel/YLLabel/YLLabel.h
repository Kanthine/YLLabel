//
//  YLLabel.h
//  YLLabel
//
//  Created by 苏沫离 on 2020/8/18.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "YLCoreText.h"

NS_ASSUME_NONNULL_BEGIN

@class YLLabel;
@protocol YLLabelDelegate <NSObject>

- (void)touchYLLabel:(YLLabel *)label url:(NSString *)url;

@end

@interface YLLabel : UIView

@property (nonatomic ,weak) id <YLLabelDelegate> delegate;

/// 当前页内容(使用固定范围绘制)
@property (nonatomic ,strong) NSAttributedString *content;

@property (nonatomic ,assign) CTFrameRef frameRef;

@end

NS_ASSUME_NONNULL_END
