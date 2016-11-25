//
//  MDFWebViewJSManager.m
//  MDFWebViewController
//
//  Created by iosci on 2016/11/25.
//  Copyright © 2016年 secoo. All rights reserved.
//

#import "MDFWebViewJSManager.h"

@implementation MDFWebViewJSManager

- (instancetype)initWithWebView:(WKWebView *)webView {
    self = [super init];
    if (self) {
        _webView = webView;
        __weak typeof(self) weakSelf = self;
        [[self jsMethodNames] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [webView.configuration.userContentController addScriptMessageHandler:strongSelf name:obj];
        }];
    }
    return self;
}

- (NSArray<NSString *> *)jsMethodNames {
    return @[];
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
}

@end

