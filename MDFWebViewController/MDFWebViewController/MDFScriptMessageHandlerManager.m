//
//  MDFWebViewJSManager.m
//  MDFWebViewController
//
//  Created by iosci on 2016/11/25.
//  Copyright © 2016年 secoo. All rights reserved.
//

#import "MDFScriptMessageHandlerManager.h"

@implementation MDFScriptMessageHandlerManager

- (NSArray<NSString *> *)jsMethodNames {
    return @[];
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
}

@end

