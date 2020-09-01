//
//  YLReaderPageContentController.m
//  YLLabel
//
//  Created by 苏沫离 on 2020/9/1.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "YLReaderPageContentController.h"

@interface YLReaderPageContentController ()

@end

@implementation YLReaderPageContentController

+ (instancetype)controllerWithCTFrame:(CTFrameRef)frameRef{
    YLReaderPageContentController *controller = [[YLReaderPageContentController alloc] init];
    controller.label.frameRef = frameRef;
    return controller;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:self.label];
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    self.label.frame = CGRectMake(10, 10, CGRectGetWidth(self.view.bounds) - 10 * 2.0, YLReaderManager.shareReader.currentModel.contentHeight);
}

#pragma mark - YLLabelDelegate

- (void)touchYLLabel:(YLLabel *)label url:(NSString *)url{
    WebViewController *webVC = [[WebViewController alloc] init];
    webVC.url = url;
    [self.navigationController pushViewController:webVC animated:YES];
}

#pragma mark - setter and getter

- (YLLabel *)label{
    if (_label == nil) {
        _label = [[YLLabel alloc] init];
        _label.delegate = self;
    }
    return _label;
}

@end
