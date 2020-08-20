//
//  WebViewController.m
//  YLLabel
//
//  Created by 苏沫离 on 2020/8/19.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "WebViewController.h"
#import <WebKit/WebKit.h>
@interface WebViewController ()
@property (nonatomic ,strong) WKWebView *webView;

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    
    _webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_webView];
    
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.url]]];
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    self.webView.frame = self.view.bounds;
}

@end
