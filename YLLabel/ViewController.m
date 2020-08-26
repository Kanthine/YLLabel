//
//  ViewController.m
//  YLLabel
//
//  Created by 苏沫离 on 2020/8/18.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "ViewController.h"
#import "YLLabel.h"
#import "YLPageLabel.h"
#import "WebViewController.h"
#import "DemoLabel.h"


@interface ViewController ()
<YLPageLabelDelegate>

@property (nonatomic ,strong) YLPageLabel *pageLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.whiteColor;
    
    
//    DemoLabel *label = [[DemoLabel alloc] initWithFrame:self.view.bounds];
//    [self.view addSubview:label];
    
    
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"切换滚动方向" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonItemClick)];
    [self.view addSubview:self.pageLabel];
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    self.pageLabel.frame = CGRectMake(10, 10, CGRectGetWidth(self.view.bounds) - 10 * 2.0, CGRectGetHeight(self.view.bounds) - 10 * 2.0);
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *dataPath = [NSBundle.mainBundle pathForResource:@"Data" ofType:@"txt"];
        NSString *text = [NSString stringWithContentsOfFile:dataPath encoding:NSUTF8StringEncoding error:nil];
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: [UIFont fontWithName:@"PingFang SC" size:15],NSForegroundColorAttributeName: [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0]}];
        handleAttrString(string, self.pageLabel.bounds);
        NSMutableArray<YLPageModel *> *pageModelsArray = getPageModels(string, self.pageLabel.bounds);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.pageLabel.pageModelsArray = pageModelsArray;
        });
    });
}

- (void)rightBarButtonItemClick{
    if (self.pageLabel.scrollDirection == UICollectionViewScrollDirectionVertical) {
        self.pageLabel.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }else{
        self.pageLabel.scrollDirection = UICollectionViewScrollDirectionVertical;
    }
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
