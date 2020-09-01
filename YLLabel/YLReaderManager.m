//
//  YLReaderManager.m
//  YLLabel
//
//  Created by 苏沫离 on 2020/9/1.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "YLReaderManager.h"

@implementation YLReaderManager

+ (instancetype)shareReader{
    static YLReaderManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (manager == nil) {
            manager = [[YLReaderManager alloc] init];
            [manager loadData];
        }
    });
    return manager;
}

- (void)loadData{
    NSString *dataPath = [NSBundle.mainBundle pathForResource:@"Data" ofType:@"txt"];
    NSString *text = [NSString stringWithContentsOfFile:dataPath encoding:NSUTF8StringEncoding error:nil];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: [UIFont fontWithName:@"PingFang SC" size:15],NSForegroundColorAttributeName: [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0]}];
    CGRect rect = CGRectMake(0, 0, CGRectGetWidth(UIScreen.mainScreen.bounds) - 20, CGRectGetHeight(UIScreen.mainScreen.bounds) - 100);
    handleAttrString(string, rect);
    self.pageModelsArray = getPageModels(string, rect);
}


- (void)setPage:(NSInteger)page{
    page = MAX(0, page);
    page = MIN(page, self.pageModelsArray.count - 1);
    _page = page;
}

- (YLPageModel *)currentModel{
    return self.pageModelsArray[self.page];
}

- (NSArray<NSString *> *)transitionTypes{
    if (_transitionTypes == nil) {
        _transitionTypes = @[@"仿真",@"覆盖",@"平移",@"滚动",@"无效果"];
    }
    return _transitionTypes;
}

@end
