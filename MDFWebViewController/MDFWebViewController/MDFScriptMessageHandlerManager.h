//
//  MDFWebViewJSManager.h
//  MDFWebViewController
//
//  Created by iosci on 2016/11/25.
//  Copyright © 2016年 secoo. All rights reserved.
//

@import Foundation;
#import "MDFWebViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MDFScriptMessageHandlerProtocol <WKScriptMessageHandler>

- (nullable NSArray<NSString *> *)jsMethodNames;

@end


@interface MDFScriptMessageHandlerManager : NSObject

@property (nullable, nonatomic, weak, readonly) MDFWebViewController *webViewController;
@property (nullable ,nonatomic, weak, readonly) id<MDFScriptMessageHandlerProtocol> child;

- (instancetype)initWithWebViewController:(MDFWebViewController *)webViewController;

@end


NS_ASSUME_NONNULL_END
