//
//  STMViewController.m
//  STMWebViewController_Example
//
//  Created by DouKing on 2018/7/31.
//  Copyright © 2018 douking. All rights reserved.
//

#import "STMViewController.h"
#import "STMPageSetting.h"

static NSInteger const kRightBarItemBaseTag = 3001;

@interface STMViewController ()
@property (nullable, nonatomic, copy) STMResponseCallback responseCallback;
@property (nullable, nonatomic, strong) STMPageSetting *page;
@end

@interface STMViewController (Demo)
- (void)setupRightBarButtonItems:(NSArray<NSDictionary *> *)items callback:(STMResponseCallback)responseCallback;
@end

@implementation STMViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    [self.webView loadHTMLString:[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] baseURL:nil];

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(0, self.view.frame.size.height - 300, 100, 50);
    [btn setTitle:@"Call js method" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    btn.center = CGPointMake(self.view.center.x, btn.center.y);
}

- (void)prepareScriptMessageHandler {
    STMPageSetting *pageSetting = [[STMPageSetting alloc] initWithWebViewController:self];
    [pageSetting registerMethod:@"setButtons" handler:^(id data, STMResponseCallback responseCallback) {
        [self setupRightBarButtonItems:data callback:responseCallback];
    }];
    self.page = pageSetting;
    [self registerScriptMessageHandler:pageSetting];
}

- (void)onClick {
    [self.page callMethod:@"showAlert" parameters:@{@"title": @"js method"} responseHandler:^(id  _Nonnull responseData) {
        NSLog(@"native receive js response: %@", responseData);
    }];
}

@end

@implementation STMViewController (Demo)

- (void)setupRightBarButtonItems:(NSArray<NSDictionary *> *)items callback:(STMResponseCallback)responseCallback {
    self.responseCallback = responseCallback;
    [self _setupNavigationBarButtonItems:items];
}

- (void)_handleRightBarButtonItemAction:(UIBarButtonItem *)sender {
    self.responseCallback(@(sender.tag - kRightBarItemBaseTag));
}

- (void)_setupNavigationBarButtonItems:(NSArray<NSDictionary *> *)items {
    NSMutableArray<UIBarButtonItem *> *temp = [NSMutableArray arrayWithCapacity:items.count];
    [items enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *text = obj[@"title"];
        UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithTitle:text style:UIBarButtonItemStylePlain target:self action:@selector(_handleRightBarButtonItemAction:)];
        barButtonItem.tag = kRightBarItemBaseTag + idx;
        [temp addObject:barButtonItem];
    }];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithArray:temp];
}

@end

