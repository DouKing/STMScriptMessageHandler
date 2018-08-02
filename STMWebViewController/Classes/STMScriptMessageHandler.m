//
//  STMScriptMessageHandler.m
//  Pods-STMWebViewController_Example
//
//  Created by DouKing on 2018/7/31.
//

#import "STMScriptMessageHandler.h"

static NSString * const kSTMApp = @"App";
static NSString * const kSTMAppBridge = @"AppBridge";

@interface STMScriptMessageHandler ()

@property (nullable, nonatomic, strong) NSMutableDictionary *methodHandlers;

@end

@implementation STMScriptMessageHandler

- (instancetype)initWithWebViewController:(STMWebViewController *)webViewController {
    self = [super init];
    if (self) {
        _webViewController = webViewController;
        [self _initial];
    }
    return self;
}

- (void)registerMethod:(NSString *)methodName handler:(STMHandler)handler {
    if (!methodName) { return; }
    NSString *js = [NSString stringWithFormat:@"\
                    if (!%@.%@.%@) {\
                        %@.%@.%@ = {};\
                    };\
                    %@.%@.callMethod = function(name, info, callback) {\
                        %@.%@.%@.callback = callback;\
                        %@.%@.postMessage({name:name, info:info});\
                    };",
                    kSTMAppBridge, self.handlerName, methodName,
                    kSTMAppBridge, self.handlerName, methodName,
                    kSTMAppBridge, self.handlerName,
                    kSTMAppBridge, self.handlerName, methodName,
                    kSTMApp, self.handlerName];
    [self _addJSScript:js forMainFrameOnly:YES];
    if (handler) {
        self.methodHandlers[methodName] = handler;
    }
}

- (void)callback:(NSString *)methodName parameter:(nullable id)parameter {
    NSString *js = [NSString stringWithFormat:@"%@.%@.%@.callback(%@)",
                    kSTMAppBridge, self.handlerName, methodName, parameter];
    [self.webViewController.webView evaluateJavaScript:js completionHandler:^(id _Nullable info, NSError * _Nullable error) {
        NSLog(@"completion: %@", info);
    }];
}

- (void)_initial {
    NSString *jsScript = [NSString stringWithFormat:@"\
                          var %@ = window.webkit.messageHandlers;\
                          var %@ = {};\
                          if (!%@.%@) {\
                            %@.%@ = {};\
                          }",
                          kSTMApp,
                          kSTMAppBridge,
                          kSTMAppBridge, self.handlerName,
                          kSTMAppBridge, self.handlerName];
    [self _addJSScript:jsScript forMainFrameOnly:YES];
}

- (void)_addJSScript:(NSString *)jsScript forMainFrameOnly:(BOOL)flag {
    if (!jsScript) { return; }
    jsScript = [NSString stringWithFormat:@";%@;", jsScript];
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jsScript
                                                      injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                   forMainFrameOnly:flag];
    [_webViewController.webView.configuration.userContentController addUserScript:userScript];
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:self.handlerName]) { return; }
    NSString *method = message.body[@"name"];
    NSArray *parameter = message.body[@"info"];
    STMHandler handler = self.methodHandlers[method];
    handler(parameter, ^(id info){
        [self callback:method parameter:info];
    });
}

#pragma mark - setter & getter

- (NSMutableDictionary *)methodHandlers {
    if (!_methodHandlers) {
        _methodHandlers = [NSMutableDictionary dictionary];
    }
    return _methodHandlers;
}

- (NSString *)handlerName {
    return NSStringFromClass(self.class);
}

@end
