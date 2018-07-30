//
//  MDFWebViewController.m
//  MDFWebViewController
//
//  Created by iosci on 2016/11/23.
//  Copyright © 2016年 secoo. All rights reserved.
//

#import "MDFWebViewController.h"
#import "MDFScriptMessageHandlerManager.h"

static NSString * const kMDFWebViewObserverKeyPathTitle = @"title";
static NSString * const kMDFWebViewObserverKeyPathEstimatedProgress = @"estimatedProgress";

@interface MDFWebViewController ()<WKUIDelegate>

@property (nonatomic, strong, readwrite) WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) NSMutableArray<__kindof MDFScriptMessageHandlerManager *> *messageHandlers;

@end

@implementation MDFWebViewController

- (void)dealloc {
    [self _removeObser];
    [_webView stopLoading];
    for (MDFScriptMessageHandlerManager *messageHandler in _messageHandlers) {
        [self _removeScriptMessageHandler:messageHandler];
    }
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self _initial];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self _initial];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.webView];
    [self.view addSubview:self.progressView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.webView evaluateJavaScript:@"viewDidAppear()" completionHandler:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.webView evaluateJavaScript:@"viewWillDisappear()" completionHandler:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.webView evaluateJavaScript:@"viewDidLayoutSubviews()" completionHandler:nil];
    self.webView.frame = self.view.bounds;
    self.progressView.frame = CGRectMake(0, CGRectGetMaxY(self.navigationController.navigationBar.frame),
                                         CGRectGetWidth(self.navigationController.navigationBar.frame), 2);
}

- (void)registerScriptMessageHandlerClass:(Class)scriptMessageHandlerCls {
    if (!scriptMessageHandlerCls) { return; }
    MDFScriptMessageHandlerManager *msgHandler = [scriptMessageHandlerCls alloc];
    if (![msgHandler isKindOfClass:[MDFScriptMessageHandlerManager class]]) {
        return;
    }
    msgHandler = [msgHandler initWithWebViewController:self];
    [self _addScriptMessageHandler:msgHandler];
    [self.messageHandlers addObject:msgHandler];
}

- (NSArray<Class> *)scriptMessageHandlerClass {
    return nil;
}

#pragma mark - Private Methods
- (void)_initial {
    __weak typeof(self) __weak_self__ = self;
    [self.scriptMessageHandlerClass enumerateObjectsUsingBlock:^(Class  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        __strong typeof(__weak_self__) self = __weak_self__;
        [self registerScriptMessageHandlerClass:obj];
    }];
    [self _addObserver];
}

- (void)_addScriptMessageHandler:(__kindof MDFScriptMessageHandlerManager*)messageHandler {
    WKUserContentController *userContentController = self.webView.configuration.userContentController;
    [[messageHandler.child jsMethodNames] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [userContentController removeScriptMessageHandlerForName:obj];
        [userContentController addScriptMessageHandler:messageHandler.child name:obj];
    }];
}

- (void)_removeScriptMessageHandler:(__kindof MDFScriptMessageHandlerManager*)messageHandler {
    WKUserContentController *userContentController = self.webView.configuration.userContentController;
    [[messageHandler.child jsMethodNames] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [userContentController removeScriptMessageHandlerForName:obj];
    }];
}

- (void)_addObserver {
    [self.webView addObserver:self forKeyPath:kMDFWebViewObserverKeyPathTitle options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:kMDFWebViewObserverKeyPathEstimatedProgress options:NSKeyValueObservingOptionNew context:nil];
}

- (void)_removeObser {
    [self.webView removeObserver:self forKeyPath:kMDFWebViewObserverKeyPathTitle];
    [self.webView removeObserver:self forKeyPath:kMDFWebViewObserverKeyPathEstimatedProgress];
}

- (void)_setProgressHidden:(BOOL)hidden animated:(BOOL)animated {
    CGFloat alpha = hidden ? 0 : 1;
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            self.progressView.alpha = alpha;
        }];
    } else {
        self.progressView.alpha = alpha;
    }
}

#pragma mark - Delegates & Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:kMDFWebViewObserverKeyPathTitle]) {
        self.navigationItem.title = [change objectForKey:NSKeyValueChangeNewKey];
    } else if ([keyPath isEqualToString:kMDFWebViewObserverKeyPathEstimatedProgress]) {
        double progress = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
        [self.progressView setProgress:progress animated:YES];
        BOOL hidden = (progress >= 1);
        [self _setProgressHidden:hidden animated:YES];
        if (hidden) {
            self.progressView.progress = 0;
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - WKUIDelegate

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - setter & getter

- (WKWebView *)webView {
    if (!_webView) {
        NSString *jScript = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);var App = window.webkit.messageHandlers;";
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        
        WKUserContentController *userContentController = [[WKUserContentController alloc] init];
        [userContentController addUserScript:userScript];
        
        WKPreferences *preferences = [[WKPreferences alloc] init];
        preferences.javaScriptCanOpenWindowsAutomatically = YES;
        
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        config.allowsInlineMediaPlayback = YES;
        config.userContentController = userContentController;
        config.preferences = preferences;
        
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
        _webView.UIDelegate = self;
    }
    return _webView;
}

- (UIProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] init];
        _progressView.tintColor = [UIColor redColor];
        _progressView.trackTintColor = [UIColor lightGrayColor];
    }
    return _progressView;
}

- (NSMutableArray<MDFScriptMessageHandlerManager *> *)messageHandlers {
    if (!_messageHandlers) {
        _messageHandlers = [NSMutableArray array];
    }
    return _messageHandlers;
}

- (void)setProgressTintColor:(UIColor *)progressTintColor {
    _progressTintColor = progressTintColor;
    self.progressView.tintColor = progressTintColor;
}

- (void)setProgressTrackTintColor:(UIColor *)progressTrackTintColor {
    _progressTrackTintColor = progressTrackTintColor;
    self.progressView.trackTintColor = progressTrackTintColor;
}

@end


