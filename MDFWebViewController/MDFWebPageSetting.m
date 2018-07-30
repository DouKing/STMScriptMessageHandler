//
//  MDFWebPageSetting.m
//  MDFWebViewController
//
//  Created by iosci on 2016/11/23.
//  Copyright © 2016年 secoo. All rights reserved.
//

#import "MDFWebPageSetting.h"
#import "DemoViewController.h"

NSString * const kMDFWebPageSettingJSMethodNameSetRightBarButtonsAction = @"SetRightBarButtons";

@implementation MDFWebPageSetting

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    NSString *name = message.name;
    if ([name isEqualToString:kMDFWebPageSettingJSMethodNameSetRightBarButtonsAction]) {
        NSArray<NSDictionary *> *btns = message.body;
        [(DemoViewController *)self.webViewController _setupRightBarButtonItems:btns];
    }
}

- (NSArray<NSString *> *)jsMethodNames {
    return @[
             kMDFWebPageSettingJSMethodNameSetRightBarButtonsAction
             ];
}

@end
