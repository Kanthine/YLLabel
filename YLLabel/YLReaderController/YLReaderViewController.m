//
//  YLReaderViewController.m
//  YLLabel
//
//  Created by 苏沫离 on 2020/9/1.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "YLReaderViewController.h"
#import "YLPageLabel.h"
#import "YLReaderPageController.h"

@interface YLReaderViewController ()
<YLPageLabelDelegate>

@property (nonatomic ,strong) YLPageLabel *pageLabel;

@end

@implementation YLReaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.whiteColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"翻页方式" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonItemClick)];
    [self.view addSubview:self.pageLabel];
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    self.pageLabel.frame = CGRectMake(10, 10, CGRectGetWidth(self.view.bounds) - 10 * 2.0, CGRectGetHeight(self.view.bounds) - 10 * 2.0);
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.pageLabel.pageModelsArray = YLReaderManager.shareReader.pageModelsArray;
    [self.pageLabel scrollToPage];
}

- (void)rightBarButtonItemClick{
    
    [YLSheetView showWithHandle:^(NSString * _Nonnull item) {
        YLReaderManager.shareReader.currentTransition = item;

        if ([item isEqualToString:@"覆盖"]) {
            self.pageLabel.transitionType = YLCollectionTransitionOpen;
        }else if ([item isEqualToString:@"平移"]){
            self.pageLabel.transitionType = YLCollectionTransitionPan;
        }else if ([item isEqualToString:@"滚动"]){
            self.pageLabel.transitionType = YLCollectionTransitionScroll;
        }else if ([item isEqualToString:@"无效果"]){
            self.pageLabel.transitionType = YLCollectionTransitionNone;
        }else if ([item isEqualToString:@"仿真"]){
            YLReaderPageController *vc = [[YLReaderPageController alloc]init];
            UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:vc];
            nav.navigationBar.translucent = NO;
            UIApplication.sharedApplication.delegate.window.rootViewController = nav;
        }
    }];
}

#pragma mark - YLPageLabelDelegate

- (void)touchYLPageLabel:(YLPageLabel *)label url:(NSString *)url{
    WebViewController *webVC = [[WebViewController alloc] init];
    webVC.url = url;
    [self.navigationController pushViewController:webVC animated:YES];
}

#pragma mark - setter and getter

- (YLPageLabel *)pageLabel{
    if (_pageLabel == nil) {
        _pageLabel = [[YLPageLabel alloc] init];
        _pageLabel.delegate = self;
    }
    return _pageLabel;
}

@end
