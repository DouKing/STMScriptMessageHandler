//
//  MDFWebPageSetting.m
//  MDFWebViewController
//
//  Created by iosci on 2016/11/23.
//  Copyright © 2016年 secoo. All rights reserved.
//

#import "MDFWebPageSetting.h"

NSString * const kMDFWebPageSettingJSMethodNameSetRightBarButtonsAction = @"SetRightBarButtons";

@implementation MDFWebPageSetting

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(webPageSetting:didReceiveScriptMessage:atUserContentController:)]) {
        [self.delegate webPageSetting:self didReceiveScriptMessage:message atUserContentController:userContentController];
    }
}

- (NSArray<NSString *> *)jsMethodNames {
    return @[
             kMDFWebPageSettingJSMethodNameSetRightBarButtonsAction
             ];
}

@end
