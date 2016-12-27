//
//  MDFWebViewJSManager.m
//  MDFWebViewController
//
//  Created by iosci on 2016/11/25.
//  Copyright © 2016年 secoo. All rights reserved.
//

#import "MDFScriptMessageHandlerManager.h"

@interface MDFScriptMessageHandlerManager ()

@end

@implementation MDFScriptMessageHandlerManager

- (instancetype)initWithWebViewController:(MDFWebViewController *)webViewController {
    self = [super init];
    if (self) {
        _webViewController = webViewController;
        if ([self conformsToProtocol:@protocol(MDFScriptMessageHandlerProtocol)]) {
            _child = (id<MDFScriptMessageHandlerProtocol>)self;
        } else {
            NSAssert(NO, @"子类必须遵守`MDFScriptMessageHandlerProtocol`这个协议");
        }
    }
    return self;
}

@end

