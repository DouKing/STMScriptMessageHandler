//
//  WKWebView+STMScriptMessage.m
//
//  Copyright (c) 2021-2025 DouKing (https://github.com/DouKing/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "WKWebView+STMScriptMessage.h"
#import <objc/runtime.h>

static char * const kSTMWebViewScriptMessageHandlersKey = "kSTMWebViewScriptMessageHandlersKey";
static NSString * const kSTMWebViewScriptMessageHandlerDefaultName = @"Bridge";
void _STMObjcSwizzMethod(Class aClass, SEL originSelector, SEL swizzSelector);

@implementation WKWebView (STMScriptMessage)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL systemSel = NSSelectorFromString(@"dealloc");
        SEL swizzSel = @selector(stm_dealloc);
        _STMObjcSwizzMethod(self, systemSel, swizzSel);
    });
}

- (void)stm_dealloc {
    for (STMScriptMessageHandler *messageHandler in [self stm_scriptMessageHandlers]) {
        [self _stm_removeScriptMessageHandler:messageHandler];
    }
}

- (STMScriptMessageHandler *)stm_addScriptMessageHandlerUseName:(NSString *)handlerName {
    if (!handlerName || !handlerName.length) { return nil; }
    STMScriptMessageHandler *msgHandler = [[STMScriptMessageHandler alloc] initWithScriptMessageHandlerName:handlerName forWebView:self];
    [self stm_addScriptMessageHandler:msgHandler];
    return msgHandler;
}

- (void)stm_addScriptMessageHandler:(__kindof STMScriptMessageHandler *)msgHandler {
    if (!msgHandler) { return; }
    [[self stm_scriptMessageHandlers] addObject:msgHandler];
    [self _stm_addScriptMessageHandler:msgHandler];
}

- (void)_stm_addScriptMessageHandler:(__kindof STMScriptMessageHandler *)messageHandler {
    WKUserContentController *userContentController = self.configuration.userContentController;
    [userContentController removeScriptMessageHandlerForName:messageHandler.handlerName];
#if TARHET_OS_MAC
    if (@available(macOS 11.0, *)) {
#else
    if (@available(iOS 14.0, *)) {
#endif
        [userContentController addScriptMessageHandlerWithReply:messageHandler
                                                   contentWorld:WKContentWorld.pageWorld
                                                           name:messageHandler.handlerName];
    } else {
        [userContentController addScriptMessageHandler:messageHandler
                                                  name:messageHandler.handlerName];
    }
}

- (void)_stm_removeScriptMessageHandler:(__kindof STMScriptMessageHandler *)messageHandler {
    WKUserContentController *userContentController = self.configuration.userContentController;
    [userContentController removeScriptMessageHandlerForName:messageHandler.handlerName];
}

- (STMScriptMessageHandler *)stm_defaultScriptMessageHandler {
    STMScriptMessageHandler *msgHandler = objc_getAssociatedObject(self, _cmd);
    if (!msgHandler) {
        msgHandler = [self stm_addScriptMessageHandlerUseName:kSTMWebViewScriptMessageHandlerDefaultName];
        objc_setAssociatedObject(self, _cmd, msgHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return msgHandler;
}

- (NSArray<STMScriptMessageHandler *> *)stm_registeredMessageHandlers {
    return [[self stm_scriptMessageHandlers] copy];
}

- (NSMutableArray<STMScriptMessageHandler *> *)stm_scriptMessageHandlers {
    NSMutableArray<STMScriptMessageHandler *> *array = objc_getAssociatedObject(self, kSTMWebViewScriptMessageHandlersKey);
    if (!array) {
        array = [NSMutableArray array];
        objc_setAssociatedObject(self, kSTMWebViewScriptMessageHandlersKey, array, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return array;
}

@end

void _STMObjcSwizzMethod(Class aClass, SEL originSelector, SEL swizzSelector) {
    Method systemMethod = class_getInstanceMethod(aClass, originSelector);
    Method swizzMethod = class_getInstanceMethod(aClass, swizzSelector);
    BOOL isAdd = class_addMethod(aClass,
                                 originSelector,
                                 method_getImplementation(swizzMethod),
                                 method_getTypeEncoding(swizzMethod));
    if (isAdd) {
        class_replaceMethod(aClass,
                            swizzSelector,
                            method_getImplementation(systemMethod),
                            method_getTypeEncoding(systemMethod));
    } else {
        method_exchangeImplementations(systemMethod, swizzMethod);
    }
}
