//
//  YLPageLabel.h
//  YLLabel
//
//  Created by 苏沫离 on 2020/8/18.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "YLCoreText.h"
#import "YLCollectionTransitionAnimationLayout.h"

NS_ASSUME_NONNULL_BEGIN

@class YLPageLabel;
@protocol YLPageLabelDelegate <NSObject>

- (void)touchYLPageLabel:(YLPageLabel *)label url:(NSString *)url;

@end


@interface YLPageLabel : UIView

@property (nonatomic ,weak) id <YLPageLabelDelegate> delegate;
@property (nonatomic ,strong) NSMutableArray<YLPageModel *> *pageModelsArray;
@property (nonatomic ,assign) YLCollectionTransitionType transitionType;

- (void)scrollToPage;

@end

NS_ASSUME_NONNULL_END
