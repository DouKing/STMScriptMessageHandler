//
//  STMViewController.m
//  STMWebViewController_Example
//
//  Created by DouKing on 2018/7/31.
//  Copyright © 2018 douking. All rights reserved.
//

#import "STMViewController.h"
static NSInteger const kRightBarItemBaseTag = 3001;
static NSInteger const kLeftBarItemBaseTag  = 1001;

@interface STMViewController ()

@property (nonatomic, strong) NSString *rightButton_callback;
@property (nonatomic, strong) NSString *leftButton_callback;
@property (nullable, nonatomic, copy) STMResponseCallback responseCallback;

@end

@implementation STMViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    [self.webView loadHTMLString:[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] baseURL:nil];
}

- (NSArray<Class> *)scriptMessageHandlerClass {
    return @[STMPageSetting.class];
}

#pragma mark -

- (void)_setupRightBarButtonItems:(NSArray<NSDictionary *> *)items {
    [self _setupNavigationBarButtonItems:items onRight:YES];
}

- (void)_setupLeftBarButtonItems:(NSArray<NSDictionary *> *)items {
    [self _setupNavigationBarButtonItems:items onRight:NO];
}

- (void)_handleRightBarButtonItemAction:(UIBarButtonItem *)sender {
    self.responseCallback(@(sender.tag - kRightBarItemBaseTag));
}

- (void)_handleLeftBarButtonItemAction:(UIBarButtonItem *)sender {
    self.responseCallback(@(sender.tag - kLeftBarItemBaseTag));
}

- (void)_setupNavigationBarButtonItems:(NSArray<NSDictionary *> *)items onRight:(BOOL)flag {
    NSMutableArray<UIBarButtonItem *> *temp = [NSMutableArray arrayWithCapacity:items.count];
    [items enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *text = obj[@"title"];
        UIBarButtonItem *barButtonItem = nil;
        SEL barButtonItemAction = flag ? @selector(_handleRightBarButtonItemAction:) : @selector(_handleLeftBarButtonItemAction:);
        barButtonItem = [[UIBarButtonItem alloc] initWithTitle:text style:UIBarButtonItemStylePlain target:self action:barButtonItemAction];
        if (flag) {
            barButtonItem.tag = kRightBarItemBaseTag + idx;
        } else {
            barButtonItem.tag = kLeftBarItemBaseTag + idx;
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

@implementation STMPageSetting

- (instancetype)initWithWebViewController:(STMWebViewController *)webViewController {
    self = [super initWithWebViewController:webViewController];
    if (self) {
        [self registerMethod:@"setButtons" handler:^(id data, STMResponseCallback responseCallback) {
            STMViewController *vc = (STMViewController *)self.webViewController;
            [vc _setupRightBarButtonItems:data];
            vc.responseCallback = responseCallback;
        }];
    }
    return self;
}

- (NSString *)handlerName {
    return @"Page";
}

@end

