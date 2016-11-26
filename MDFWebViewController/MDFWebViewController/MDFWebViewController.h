//
//  MDFWebViewController.h
//  MDFWebViewController
//
//  Created by iosci on 2016/11/23.
//  Copyright © 2016年 secoo. All rights reserved.
//

@import WebKit;
@import UIKit;
#import "MDFScriptMessageHandlerManager.h"

NS_ASSUME_NONNULL_BEGIN


@interface MDFWebViewController : UIViewController

@property (nonatomic, strong, readonly) WKWebView *webView;

- (void)addScriptMessageHandler:(__kindof MDFScriptMessageHandlerManager *)scriptMessageHandler;

- (void)registerJSMethods;

@end


NS_ASSUME_NONNULL_END
