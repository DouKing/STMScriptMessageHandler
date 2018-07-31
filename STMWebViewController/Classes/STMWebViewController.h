//
//  STMWebViewController.h
//  Pods-STMWebViewController_Example
//
//  Created by DouKing on 2018/7/31.
//

@import UIKit;
@import WebKit;

NS_ASSUME_NONNULL_BEGIN

@interface STMWebViewController : UIViewController

@property (nonatomic, strong, readonly) WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;

- (nullable NSArray<Class> *)scriptMessageHandlerClass;

@end

NS_ASSUME_NONNULL_END
