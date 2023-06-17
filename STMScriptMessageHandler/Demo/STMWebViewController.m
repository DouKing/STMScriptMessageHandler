//
//  STMWebViewController.m
//  Pods-STMWebViewController_Example
//
//  Created by DouKing on 2018/7/31.
//

#import "STMWebViewController.h"

static NSString * const kMDFWebViewObserverKeyPathTitle = @"title";
static NSString * const kMDFWebViewObserverKeyPathEstimatedProgress = @"estimatedProgress";

@interface STMWebViewController ()<WKUIDelegate, WKNavigationDelegate>

@property (nonatomic, strong, readwrite) WKWebView *webView;

@end

@implementation STMWebViewController

- (void)dealloc {
    [self _removeObser];
    [_webView stopLoading];
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
    [self _copyNSHTTPCookieStorageToWKWebViewWithCompletionHandler:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.webView.frame = self.view.bounds;
    self.progressView.frame = CGRectMake(0, self.webView.scrollView.contentInset.top -
                                            self.webView.scrollView.contentOffset.y,
                                         CGRectGetWidth(self.navigationController.navigationBar.frame), 2);
}

#pragma mark - Private Methods

- (void)_initial {
    [self _addObserver];
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

#pragma mark cookies
/**
 cookie持久化路径 NSLibraryDirectory
 .../Library/Cookies/
    Cookie.binarycookies    WKWebview
    <appid>.binarycookies   NSHTTPCookieStorage
 
 session级别的cookie
    WKProcessPool
 */

- (void)_copyNSHTTPCookieStorageToWKWebViewWithCompletionHandler:(nullable void (^)(void))completionHandler {
    if (@available(iOS 11.0, *)) {
        NSArray<NSHTTPCookie *> *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
        WKHTTPCookieStore *cookieStroe = self.webView.configuration.websiteDataStore.httpCookieStore;
        if (cookies.count == 0) {
            !completionHandler ?: completionHandler();
            return;
        }
        for (NSHTTPCookie *cookie in cookies) {
            [cookieStroe setCookie:cookie completionHandler:^{
                if ([[cookies lastObject] isEqual:cookie]) {
                    !completionHandler ?: completionHandler();
                    return;
                }
            }];
        }
    } else {
        NSString *cookiestring = [self _formatCookies:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];
        WKUserScript *cookieScript = [[WKUserScript alloc] initWithSource:cookiestring
                                                            injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                         forMainFrameOnly:NO];
        [self.webView.configuration.userContentController addUserScript:cookieScript];
        !completionHandler ?: completionHandler();
    }
}

- (void)_syncCookiesToRequest:(NSMutableURLRequest *)request {
    if (!request.URL) {
        return;
    }
    
    void (^block)(NSArray<NSHTTPCookie *> *) = ^(NSArray<NSHTTPCookie *> *availableCookie){
        if (availableCookie.count > 0) {
            NSDictionary *reqHeader = [NSHTTPCookie requestHeaderFieldsWithCookies:availableCookie];
            NSString *cookieStr = [reqHeader objectForKey:@"Cookie"];
            [request setValue:cookieStr forHTTPHeaderField:@"Cookie"];
        }
    };
    
    if (@available(iOS 11.0, *)) {
        WKHTTPCookieStore *cookieStroe = self.webView.configuration.websiteDataStore.httpCookieStore;
        [cookieStroe getAllCookies:^(NSArray<NSHTTPCookie *> * _Nonnull availableCookie) {
            block(availableCookie);
        }];
    } else {
        NSArray<NSHTTPCookie *> *availableCookie = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:request.URL];
        block(availableCookie);
    }
}


- (void)_clearCookies {
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    for (NSHTTPCookie *cookie in cookies) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    
    if (@available(iOS 11.0, *)) {
        WKHTTPCookieStore *cookieStroe = self.webView.configuration.websiteDataStore.httpCookieStore;
        [cookieStroe getAllCookies:^(NSArray<NSHTTPCookie *> * _Nonnull cookies) {
            for (NSHTTPCookie *cookie in cookies) {
                [cookieStroe deleteCookie:cookie completionHandler:^{
                    NSLog(@"[STMWebViewController] WKWebView 清除cookie %@", cookie.name);
                }];
            }
        }];
    }
}

- (void)clearWKWebViewCache {
    NSString *libraryDir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    NSString *bundleId  =  [[NSBundle mainBundle] infoDictionary][@"CFBundleIdentifier"];
    NSString *webkitFolderInLib = [NSString stringWithFormat:@"%@/WebKit", libraryDir];
    NSString *webKitFolderInCaches = [NSString stringWithFormat:@"%@/Caches/%@/WebKit", libraryDir, bundleId];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCaches error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:webkitFolderInLib error:nil];
    
    if (@available(iOS 9.0, *)) {
        WKWebsiteDataStore *dataStore = [WKWebsiteDataStore defaultDataStore];
        [dataStore fetchDataRecordsOfTypes:[WKWebsiteDataStore allWebsiteDataTypes]
                         completionHandler:^(NSArray<WKWebsiteDataRecord *> * _Nonnull records) {
            for (WKWebsiteDataRecord *record in records) {
                [dataStore removeDataOfTypes:record.dataTypes forDataRecords:@[record] completionHandler:^{
                    NSLog(@"[STMWebViewController] WKWebView 清除缓存 %@", record.displayName);
                }];
            }
        }];
    }
}

- (NSString *)_formatCookies:(NSArray<NSHTTPCookie *> *)cookies {
    NSMutableString *cookieScript = [NSMutableString string];
    for (NSHTTPCookie *cookie in cookies) {
        // Skip cookies that will break our script
        if ([cookie.value rangeOfString:@"'"].location != NSNotFound) {
            continue;
        }
        // Create a line that appends this cookie to the web view's document's cookies
        [cookieScript appendFormat:@"document.cookie='%@=%@;", cookie.name, cookie.value];
        if (cookie.domain || cookie.domain.length > 0) {
            [cookieScript appendFormat:@"domain=%@;", cookie.domain];
        }
        if (cookie.path || cookie.path.length > 0) {
            [cookieScript appendFormat:@"path=%@;", cookie.path];
        }
        if (cookie.expiresDate) {
            [cookieScript appendFormat:@"expires=%@;", [[self cookieDateFormatter] stringFromDate:cookie.expiresDate]];
        }
        if (cookie.secure) {
            [cookieScript appendString:@"Secure;"];
        }
        if (cookie.HTTPOnly) {
            // 保持 native 的 cookie 完整性，当 HTTPOnly 时，不能通过 document.cookie 来读取该 cookie。
            [cookieScript appendString:@"HTTPOnly;"];
        }
        [cookieScript appendFormat:@"'\n"];
    }
    
    // document.cookie='%@=%@;domain=%@;path=%@;expires=%@;Secure;HTTPOnly;'
    return cookieScript;
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

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    // 302
    if ([navigationAction.request isKindOfClass:[NSMutableURLRequest class]]) {
        [self _syncCookiesToRequest:(NSMutableURLRequest *)navigationAction.request];
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - setter & getter

- (WKWebView *)webView {
    if (!_webView) {
        NSString *jScript = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);";
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];

        WKUserContentController *userContentController = [[WKUserContentController alloc] init];
        [userContentController addUserScript:userScript];

        WKPreferences *preferences = [[WKPreferences alloc] init];
        preferences.javaScriptCanOpenWindowsAutomatically = YES;

        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        config.allowsInlineMediaPlayback = YES;
        config.userContentController = userContentController;
        config.preferences = preferences;
        config.processPool = [self processPool];

        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
        _webView.UIDelegate = self;
        _webView.navigationDelegate = self;
    }
    return _webView;
}

- (UIProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] init];
        _progressView.progressTintColor = [UIColor redColor];
        _progressView.trackTintColor = [UIColor lightGrayColor];
    }
    return _progressView;
}

- (WKProcessPool *)processPool {
    static WKProcessPool *pool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pool = [[WKProcessPool alloc] init];
    });
    return pool;
}

- (NSDateFormatter *)cookieDateFormatter {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // expires=Mon, 01 Aug 2050 06:44:35 GMT
        formatter = [NSDateFormatter new];
        formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        formatter.dateFormat = @"EEE, d MMM yyyy HH:mm:ss zzz";
    });
    return formatter;
}

@end
