//
//  MDFWebPageSetting.m
//  MDFWebViewController
//
//  Created by iosci on 2016/11/23.
//  Copyright © 2016年 secoo. All rights reserved.
//

#import "MDFWebPageSetting.h"
#import <SDWebImage/UIButton+WebCache.h>

NSString * const kMDFWebPageSettingJSMethodNameSetRightBarButtonsAction = @"SetRightBarButtons";

@interface MDFWebViewController (NavigationBarButton)

- (void)_setupRightBarButtonItems:(NSArray<NSDictionary *> *)items;
- (void)_setupLeftBarButtonItems:(NSArray<NSDictionary *> *)items;

@end

@implementation MDFWebPageSetting

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    NSString *name = message.name;
    if ([name isEqualToString:kMDFWebPageSettingJSMethodNameSetRightBarButtonsAction]) {
        NSArray<NSDictionary *> *btns = message.body;
        [self.webViewController _setupRightBarButtonItems:btns];
    }
}

- (NSArray<NSString *> *)jsMethodNames {
    return @[
             kMDFWebPageSettingJSMethodNameSetRightBarButtonsAction
             ];
}

@end


static NSString * const kMDFBarItemTitleKey = @"title";
static NSString * const kMDFBarItemImageKey = @"image";
static NSString * const kMFDBarItemImageURLKey = @"imageURL";
static NSInteger const kMDFRightBarItemBaseTag = 3001;
static NSInteger const kMDFLeftBarItemBaseTag  = 1001;

@implementation MDFWebViewController (NavigationBarButton)

- (void)_setupRightBarButtonItems:(NSArray<NSDictionary *> *)items {
    [self _setupNavigationBarButtonItems:items onRight:YES];
}

- (void)_setupLeftBarButtonItems:(NSArray<NSDictionary *> *)items {
    [self _setupNavigationBarButtonItems:items onRight:NO];
}

- (void)_handleRightBarButtonItemAction:(UIBarButtonItem *)sender {
    NSString *action = [NSString stringWithFormat:@"handleRightButtonClick('%ld')", sender.tag - kMDFRightBarItemBaseTag];
    [self.webView evaluateJavaScript:action completionHandler:nil];
}

- (void)_handleLeftBarButtonItemAction:(UIBarButtonItem *)sender {
    NSString *action = [NSString stringWithFormat:@"handleLeftButtonClick('%ld')", sender.tag - kMDFRightBarItemBaseTag];
    [self.webView evaluateJavaScript:action completionHandler:nil];
}

- (void)_setupNavigationBarButtonItems:(NSArray<NSDictionary *> *)items onRight:(BOOL)flag {
    NSMutableArray<UIBarButtonItem *> *temp = [NSMutableArray arrayWithCapacity:items.count];
    [items enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *icon = obj[kMDFBarItemImageKey];  //图片代号
        NSString *text = obj[kMDFBarItemTitleKey];  //按钮名字
        NSString *url = obj[kMFDBarItemImageURLKey]; //图片URL
        UIImage *image = [UIImage imageNamed:icon];
        UIBarButtonItem *barButtonItem = nil;
        SEL barButtonItemAction = flag ? @selector(_handleRightBarButtonItemAction:) : @selector(_handleLeftBarButtonItemAction:);
        if (image) {
            barButtonItem = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:barButtonItemAction];
        } else if (url.length) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(0, 0, 22, 22);
            if (flag) {
                [btn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
            } else {
                [btn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            }
            [btn sd_setImageWithURL:[NSURL URLWithString:url] forState:UIControlStateNormal];
            [btn addTarget:self action:barButtonItemAction forControlEvents:UIControlEventTouchUpInside];
            barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
        } else {
            barButtonItem = [[UIBarButtonItem alloc] initWithTitle:text style:UIBarButtonItemStylePlain target:self action:barButtonItemAction];
        }
        if (flag) {
            barButtonItem.tag = kMDFRightBarItemBaseTag + idx;
        } else {
            barButtonItem.tag = kMDFLeftBarItemBaseTag + idx;
        }
        [temp addObject:barButtonItem];
    }];
    if (flag) {
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithArray:temp];
    } else {
        self.navigationItem.leftBarButtonItems = [NSArray arrayWithArray:temp];
    }
}

@end
