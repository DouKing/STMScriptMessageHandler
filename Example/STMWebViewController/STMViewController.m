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

@end

@implementation STMViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    NSString *jScript = @";var App = window.webkit.messageHandlers;\
    var Bridge = {}; \
    var page = {};\
    Bridge.page = page;\
    page.setButtons = function(buttons){\
    App.Page.postMessage(buttons);\
    };";
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    [self.webView.configuration.userContentController addUserScript:userScript];
}

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
    NSString *action = [NSString stringWithFormat:@"%@('%ld');",
                        self.rightButton_callback, sender.tag - kRightBarItemBaseTag];
    [self.webView evaluateJavaScript:action completionHandler:nil];
}

- (void)_handleLeftBarButtonItemAction:(UIBarButtonItem *)sender {
    NSString *action = [NSString stringWithFormat:@"; var js_left_callback = %@; js_left_callback('%ld');",
                        self.leftButton_callback, sender.tag - kRightBarItemBaseTag];
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

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSString *name = message.name;
    if ([name isEqualToString:self.handlerName]) {
        NSArray<NSDictionary *> *btns = message.body;
        [(STMViewController *)self.webViewController _setupRightBarButtonItems:btns];
    }
}

- (NSString *)handlerName {
    return @"Page";
}

@end

