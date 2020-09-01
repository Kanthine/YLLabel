//
//  YLReaderPageContentController.h
//  YLLabel
//
//  Created by 苏沫离 on 2020/9/1.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YLLabel.h"

NS_ASSUME_NONNULL_BEGIN

@interface YLReaderPageContentController : UIViewController
<YLLabelDelegate>
@property (nonatomic ,strong) YLLabel *label;

+ (instancetype)controllerWithCTFrame:(CTFrameRef)frameRef;

@end

NS_ASSUME_NONNULL_END
