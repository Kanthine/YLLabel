//
//  YLReaderPageController.m
//  YLLabel
//
//  Created by 苏沫离 on 2020/9/1.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "YLReaderPageController.h"
#import "YLReaderPageContentController.h"
#import "YLReaderPageBGController.h"

#import "YLReaderViewController.h"

@interface UIPageViewController (Extend)

/// 手势启用
@property (nonatomic ,assign) BOOL gestureRecognizerEnabled;

/// tap手势
@property (nonatomic ,strong) UITapGestureRecognizer *tapGestureRecognizer;

/// tap手势启用
@property (nonatomic ,assign) BOOL tapGestureRecognizerEnabled;


@end
#import <objc/message.h>

NSString *const IsGestureRecognizerEnabled = @"IsGestureRecognizerEnabled";
NSString *const TapIsGestureRecognizerEnabled = @"TapIsGestureRecognizerEnabled";


@implementation UIPageViewController (Extend)

/// 手势启用
- (void)setGestureRecognizerEnabled:(BOOL)gestureRecognizerEnabled{
    [self.gestureRecognizers enumerateObjectsUsingBlock:^(__kindof UIGestureRecognizer * _Nonnull gesture, NSUInteger idx, BOOL * _Nonnull stop) {
        gesture.enabled = gestureRecognizerEnabled;
    }];
    
    objc_setAssociatedObject(self, @selector(gestureRecognizerEnabled), @(gestureRecognizerEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)gestureRecognizerEnabled{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

/// tap手势
- (UITapGestureRecognizer *)tapGestureRecognizer{
    __block UITapGestureRecognizer *tapGestureRecognizer;
    [self.gestureRecognizers enumerateObjectsUsingBlock:^(__kindof UIGestureRecognizer * _Nonnull gesture, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([gesture isKindOfClass:UITapGestureRecognizer.class]) {
            tapGestureRecognizer = gesture;
            *stop = YES;
        }
    }];
    return tapGestureRecognizer;
}

/// tap手势启用
- (void)setTapGestureRecognizerEnabled:(BOOL)tapGestureRecognizerEnabled{
    self.tapGestureRecognizer.enabled = tapGestureRecognizerEnabled;
    objc_setAssociatedObject(self, @selector(tapGestureRecognizerEnabled), @(tapGestureRecognizerEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)tapGestureRecognizerEnabled{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

@end


// 左边上一页点击区域
#define LeftWidth (CGRectGetWidth(UIScreen.mainScreen.bounds) / 3.0)
// 右边下一页点击区域
#define RightWidth (CGRectGetWidth(UIScreen.mainScreen.bounds) / 3.0)


#import "YLCoreText.h"




@interface YLReaderPageController ()
<UIGestureRecognizerDelegate,UIPageViewControllerDataSource>
{
    // 自定义Tap手势
    UITapGestureRecognizer *_customTapGestureRecognizer;
}

@end

@implementation YLReaderPageController

- (instancetype)init{
    NSDictionary *options = @{UIPageViewControllerOptionSpineLocationKey:@(UIPageViewControllerSpineLocationMin)};
    return [self initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:options];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.tapGestureRecognizerEnabled = NO;
    self.dataSource = self;
    self.doubleSided = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"翻页方式" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonItemClick)];
    
    _customTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerClick:)];
    _customTapGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:_customTapGestureRecognizer];
    
    YLReaderPageBGController *bgVC = [[YLReaderPageBGController alloc] init];
    bgVC.targetView = self.view;

    /// 初始页面
    [self setViewControllers:@[[YLReaderPageContentController controllerWithCTFrame:YLReaderManager.shareReader.currentModel.frameRef]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {}];
}

- (void)rightBarButtonItemClick{
    [YLSheetView showWithHandle:^(NSString * _Nonnull item) {
        YLReaderManager.shareReader.currentTransition = item;
        if (![item isEqualToString:@"仿真"]){
            YLReaderViewController *vc = [[YLReaderViewController alloc]init];
            UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:vc];
            nav.navigationBar.translucent = NO;
            UIApplication.sharedApplication.delegate.window.rootViewController = nav;
        }
    }];
}

#pragma mark - 手势

/** 手势拦截 ： 询问 delegate 一个手势是否应该接收一个触摸对象
 * @return 默认为 YES，允许手势识别器检查触摸对象；返回 NO 拦截该次事件
 * @discussion 在调用手势识别器的 -touchesBegan:withEvent: 方法之前调用这个方法
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if ([touch.view.superview isKindOfClass:UICollectionViewCell.class]) {
        return NO;
    }
    
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer{
    if ([gestureRecognizer isKindOfClass:UITapGestureRecognizer.class] &&
        [gestureRecognizer isEqual:_customTapGestureRecognizer]) {
        CGPoint touchPoint = [_customTapGestureRecognizer locationInView:self.view];
        if (touchPoint.x > LeftWidth && touchPoint.x < (CGRectGetWidth(UIScreen.mainScreen.bounds) - RightWidth)) {
            return YES;
        }
    }
    return NO;
}

- (void)tapGestureRecognizerClick:(UITapGestureRecognizer *)tap{
    CGPoint touchPoint = [tap locationInView:self.view];
    if (touchPoint.x < LeftWidth) { // 左边
        YLReaderManager.shareReader.page --;
        
        YLReaderPageBGController *bgVC = [[YLReaderPageBGController alloc] init];
        bgVC.targetView = self.view;
        
        [self setViewControllers:@[[YLReaderPageContentController controllerWithCTFrame:YLReaderManager.shareReader.currentModel.frameRef],bgVC] direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:^(BOOL finished) {
            NSLog(@"动画左边");
        }];
    }else if (touchPoint.x > (CGRectGetWidth(UIScreen.mainScreen.bounds) - RightWidth)) { // 右边
        YLReaderManager.shareReader.page ++;
        
        YLReaderPageBGController *bgVC = [[YLReaderPageBGController alloc] init];
        bgVC.targetView = self.view;
        
        [self setViewControllers:@[[YLReaderPageContentController controllerWithCTFrame:YLReaderManager.shareReader.currentModel.frameRef],bgVC] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished) {
        }];
    }
}

#pragma mark - UIPageViewControllerDataSource

- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController{
    if (YLReaderManager.shareReader.page) {
        YLReaderManager.shareReader.page --;
        return [YLReaderPageContentController controllerWithCTFrame:YLReaderManager.shareReader.currentModel.frameRef];
    }else{
        return nil;
    }
}

- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController{
    if (YLReaderManager.shareReader.page < YLReaderManager.shareReader.pageModelsArray.count - 1) {
        YLReaderManager.shareReader.page ++;
        return [YLReaderPageContentController controllerWithCTFrame:YLReaderManager.shareReader.currentModel.frameRef];
    }else{
        return nil;
    }
}

@end
