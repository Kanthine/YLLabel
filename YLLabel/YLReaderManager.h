//
//  YLReaderManager.h
//  YLLabel
//
//  Created by 苏沫离 on 2020/9/1.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YLCoreText.h"

NS_ASSUME_NONNULL_BEGIN

@interface YLReaderManager : NSObject

@property (nonatomic, strong) NSMutableArray<YLPageModel *> *pageModelsArray;
@property (nonatomic ,assign) NSInteger page;
@property (nonatomic, strong) YLPageModel *currentModel;


@property (nonatomic, strong) NSArray<NSString *> *transitionTypes;
@property (nonatomic, strong) NSString *currentTransition;

+ (instancetype)shareReader;

@end

NS_ASSUME_NONNULL_END
