//
//  MDFWebViewJSManager.h
//  MDFWebViewController
//
//  Created by iosci on 2016/11/25.
//  Copyright © 2016年 secoo. All rights reserved.
//

@import WebKit;
@import Foundation;

NS_ASSUME_NONNULL_BEGIN


@interface MDFWebViewJSManager : NSObject<WKScriptMessageHandler>

@property (nullable, nonatomic, weak, readonly) WKWebView *webView;

- (instancetype)initWithWebView:(WKWebView *)webView;

- (nullable NSArray<NSString *> *)jsMethodNames;

@end


NS_ASSUME_NONNULL_END
