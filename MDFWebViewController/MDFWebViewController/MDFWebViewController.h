//
//  MDFWebViewController.h
//  MDFWebViewController
//
//  Created by iosci on 2016/11/23.
//  Copyright © 2016年 secoo. All rights reserved.
//

@import WebKit;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN


@interface MDFWebViewController : UIViewController

@property (nonatomic, strong, readonly) WKWebView *webView;
@property (nullable, nonatomic, strong) UIColor *progressTintColor;
@property (nullable, nonatomic, strong) UIColor *progressTrackTintColor;

- (nullable NSArray<Class> *)scriptMessageHandlerClass;

@end


NS_ASSUME_NONNULL_END
