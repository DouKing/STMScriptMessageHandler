//
//  STMWebViewController.h
//  Pods-STMWebViewController_Example
//
//  Created by DouKing on 2018/7/31.
//

@import UIKit;
#import "STMScriptMessageHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface STMWebViewController : UIViewController

@property (nonatomic, strong, readonly) WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nullable, nonatomic, strong, readonly) STMScriptMessageHandler *messageHandler;

/// register your message handler in this method
- (void)prepareScriptMessageHandler NS_REQUIRES_SUPER;
- (NSArray<__kindof STMScriptMessageHandler *> *)registeredMessageHandlers;

@end

NS_ASSUME_NONNULL_END
