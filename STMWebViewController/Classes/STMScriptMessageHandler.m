//
//  STMScriptMessageHandler.m
//  Pods-STMWebViewController_Example
//
//  Created by DouKing on 2018/7/31.
//

#import "STMScriptMessageHandler.h"

@implementation STMScriptMessageHandler

- (instancetype)initWithWebViewController:(STMWebViewController *)webViewController {
    self = [super init];
    if (self) {
        _webViewController = webViewController;
        if ([self conformsToProtocol:@protocol(STMScriptMessageHandlerProtocol)]) {
            _child = (id<STMScriptMessageHandlerProtocol>)self;
        } else {
            NSAssert(NO, @"子类必须遵守`STMScriptMessageHandlerProtocol`这个协议");
        }
    }
    return self;
}

@end
