//
//  STMViewController.m
//  STMWebViewController_Example
//
//  Created by DouKing on 2018/7/31.
//  Copyright © 2018 douking. All rights reserved.
//

#import "STMViewController.h"

static NSInteger const kRightBarItemBaseTag = 3001;

@interface STMViewController ()
@property (nullable, nonatomic, strong) NSString *responseCallback;
@property (nullable, nonatomic, strong) STMScriptMessageHandler *page;

@end

@interface STMViewController (Demo)
- (void)setupRightBarButtonItems:(NSDictionary *)data;
@end

@implementation STMViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareScriptMessageHandler];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    [self.webView loadHTMLString:[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] baseURL:nil];

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(0, self.view.frame.size.height - 300, 100, 50);
    [btn setTitle:@"Call js method" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    btn.center = CGPointMake(self.view.center.x, btn.center.y);

    btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(0, self.view.frame.size.height - 250, 100, 50);
    [btn setTitle:@"Save callback" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(test) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    btn.center = CGPointMake(self.view.center.x, btn.center.y);
}

- (void)prepareScriptMessageHandler {
    // Use `self.webView.stm_defaultScriptMessageHandler` register a method for js, the js should call this use App.Bridge.callMethod...
    [self.webView.stm_defaultScriptMessageHandler registerMethod:@"nslog" handler:^(id  _Nonnull data, STMResponseCallback  _Nullable responseCallback) {
        NSLog(@"native receive js calling `nslog`: %@", data);
        responseCallback([NSString stringWithFormat:@"native `nslog` %@ done!", data]);
    }];

    [self.webView.stm_defaultScriptMessageHandler registerMethod:@"testNativeMethod" handler:^(id  _Nonnull data, STMResponseCallback  _Nullable responseCallback) {
        NSLog(@"native receive js calling `testNativeMethod`: %@", data);
        responseCallback(@(200));
    }];

    // You can register yourself message handler.
    // register a message handler named `Page`, so the js should call your method that the message handler registered use App.Page.callMethod...
    self.page = [self.webView stm_addScriptMessageHandlerUseName:@"Page"];

    [self.page registerMethod:@"setButtons" handler:^(id data, STMResponseCallback responseCallback) {
        [self setupRightBarButtonItems:data];
		responseCallback(@(YES));
    }];
}

- (void)onClick {
    [self.webView.stm_defaultScriptMessageHandler callMethod:@"log" parameters:@{@"foo": @"foo"} responseHandler:^(id  _Nonnull responseData) {
        NSLog(@"native got js response for `log`: %@", responseData);
    }];
}

- (void)test {
    [self.webView.stm_defaultScriptMessageHandler callMethod:@"test" parameters:@{} responseHandler:^(id  _Nonnull responseData) {
        NSLog(@"native got js response for `test`: %@", responseData);
    }];
}

@end

@implementation STMViewController (Demo)

- (void)setupRightBarButtonItems:(NSDictionary *)data {
    self.responseCallback = data[@"callback"];
	NSArray<NSDictionary *> *items = data[@"data"];
    [self _setupNavigationBarButtonItems:items];
}

- (void)_handleRightBarButtonItemAction:(UIBarButtonItem *)sender {
	[self.page callMethod:self.responseCallback parameters:@(sender.tag - kRightBarItemBaseTag) responseHandler:nil];
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

