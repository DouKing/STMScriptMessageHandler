//
//  STMWebViewController.h
//  Pods-STMWebViewController_Example
//
//  Created by DouKing on 2018/7/31.
//

@import UIKit;
@import WebKit;

NS_ASSUME_NONNULL_BEGIN
@class STMScriptMessageHandler;

@interface STMWebViewController : UIViewController

@property (nonatomic, strong, readonly) WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;
- (NSArray<__kindof STMScriptMessageHandler *> *)registeredMessageHandlers;

/// register your message handler in this method
- (void)prepareScriptMessageHandler;
- (void)registerScriptMessageHandler:(__kindof STMScriptMessageHandler *)msgHandler;

@end

NS_ASSUME_NONNULL_END
