//
//  DemoViewController.m
//  MDFWebViewController
//
//  Created by iosci on 2016/11/23.
//  Copyright © 2016年 secoo. All rights reserved.
//

#import "DemoViewController.h"
#import "MDFWebPageSetting.h"
#import <SDWebImage/UIButton+WebCache.h>

@interface DemoViewController ()

@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    [self.webView loadHTMLString:[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] baseURL:nil];
    
//    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.baidu.com"]]];
}

- (NSArray<Class> *)scriptMessageHandlerClass {
    return @[MDFWebPageSetting.class];
}

@end


static NSString * const kMDFBarItemTitleKey = @"title";
static NSString * const kMDFBarItemImageKey = @"image";
static NSString * const kMFDBarItemImageURLKey = @"imageURL";
static NSInteger const kMDFRightBarItemBaseTag = 3001;
static NSInteger const kMDFLeftBarItemBaseTag  = 1001;

@implementation DemoViewController (NavigationBarButton)

- (void)_setupRightBarButtonItems:(NSArray<NSDictionary *> *)items {
    [self _setupNavigationBarButtonItems:items onRight:YES];
}

- (void)_setupLeftBarButtonItems:(NSArray<NSDictionary *> *)items {
    [self _setupNavigationBarButtonItems:items onRight:NO];
}

- (void)_handleRightBarButtonItemAction:(UIBarButtonItem *)sender {
    NSString *action = [NSString stringWithFormat:@"; var js_right_callback = %@; js_right_callback('%ld');",
                        self.rightButton_callback, sender.tag - kMDFRightBarItemBaseTag];
    [self.webView evaluateJavaScript:action completionHandler:nil];
}

- (void)_handleLeftBarButtonItemAction:(UIBarButtonItem *)sender {
    NSString *action = [NSString stringWithFormat:@"; var js_left_callback = %@; js_left_callback('%ld');",
                        self.leftButton_callback, sender.tag - kMDFRightBarItemBaseTag];
    [self.webView evaluateJavaScript:action completionHandler:nil];
}

- (void)_setupNavigationBarButtonItems:(NSArray<NSDictionary *> *)items onRight:(BOOL)flag {
    NSMutableArray<UIBarButtonItem *> *temp = [NSMutableArray arrayWithCapacity:items.count];
    [items enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == items.count - 1 && [obj isKindOfClass:[NSString class]]) {
            if (flag) { self.rightButton_callback = (NSString *)obj; }
            else { self.leftButton_callback = (NSString *)obj; }
            return;
        }
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
