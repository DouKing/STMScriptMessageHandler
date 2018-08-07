//
//  STMScriptMessageHandler.m
//  Pods-STMWebViewController_Example
//
//  Created by DouKing on 2018/7/31.
//

#import "STMScriptMessageHandler.h"

#define STM_JS_FUNC(x, ...) [NSString stringWithFormat:@#x ,##__VA_ARGS__]

static NSString * const kSTMApp = @"App";
static NSString * const kSTMNativeCallback = @"nativeCallback";

@interface STMScriptMessageHandler ()

@property (nonatomic, copy) NSString *handlerName;
@property (nullable, nonatomic, weak) WKWebView *webView;

@property (nullable, nonatomic, strong) NSMutableDictionary *methodHandlers;
@property (nullable, nonatomic, strong) NSMutableDictionary *jsResponseHandlers;

@end

@implementation STMScriptMessageHandler

- (instancetype)initWithScriptMessageHandlerName:(NSString *)handlerName forWebView:(WKWebView * _Nonnull __weak)webView {
    self = [super init];
    if (self) {
        _handlerName = [handlerName copy];
        _webView = webView;
        [self prepareJsScript];
    }
    return self;
}

- (void)registerMethod:(NSString *)methodName handler:(STMHandler)handler {
    if (!methodName) { return; }
    NSString *js = STM_JS_FUNC(
        if (!%@.%@.%@) {
            %@.%@.%@ = {};
        };
        %@.%@.callMethod = function(name, info, callback) {
            %@.%@.%@.callback = callback;
            %@.%@.postMessage({name:name, info:info});
        };
        , kSTMApp, self.handlerName, methodName,
        kSTMApp, self.handlerName, methodName,
        kSTMApp, self.handlerName,
        kSTMApp, self.handlerName, methodName,
        kSTMApp, self.handlerName
    );
    [self _addJSScript:js forMainFrameOnly:YES];
    if (handler) {
        self.methodHandlers[methodName] = handler;
    }
}

- (void)callMethod:(NSString *)methodName parameters:(NSDictionary *)parameters responseHandler:(STMResponseCallback)handler {
    if (!methodName) { return; }
    if (handler) {
        self.jsResponseHandlers[methodName] = handler;
    }
    NSString *formatParameter = [self _formatParameters:parameters];
    NSString *js = [NSString stringWithFormat:@"nativeCallback('%@', '%@')", methodName, formatParameter];
    [self.webView evaluateJavaScript:js completionHandler:nil];
}

#pragma mark - Private

- (void)_response:(NSString *)methodName parameter:(nullable id)parameter {
    NSString *js = STM_JS_FUNC(
        var callback = %@.%@.%@.callback;
        if (callback) { callback(%@); }
        , kSTMApp, self.handlerName, methodName, parameter
    );
    [self.webView evaluateJavaScript:js completionHandler:nil];
}

- (void)prepareJsScript {
    [self _addJS1];
    [self _addJS2];
    [self _addJS3];
    [self registerMethod:kSTMNativeCallback handler:^(NSDictionary * _Nonnull data, STMResponseCallback  _Nullable responseCallback) {
        NSString *methodName = data[@"name"];
        NSDictionary *info = data[@"info"];
        STMResponseCallback jsResponse = self.jsResponseHandlers[methodName];
        !jsResponse ?: jsResponse(info);
    }];
}

- (void)_addJS1 {
    NSString *jsScript = STM_JS_FUNC(
                                     var %@ = window.webkit.messageHandlers;
                                     , kSTMApp
                                     );
    [self _addJSScript:jsScript forMainFrameOnly:YES];
}

- (void)_addJS2 {
    NSString *jsScript = STM_JS_FUNC(
                                     function registerMethod(methodName, methodHandler) {
                                         if (!%@.%@.methods) {
                                             %@.%@.methods = {};
                                         }
                                         %@.%@.methods.methodName = methodHandler;
                                     }
                                     , kSTMApp, self.handlerName,
                                     kSTMApp, self.handlerName,
                                     kSTMApp, self.handlerName
                                     );
    [self _addJSScript:jsScript forMainFrameOnly:YES];
}

- (void)_addJS3 {
    NSString *jsScript = STM_JS_FUNC(
                                     function nativeCallback(methodName, info) {
                                         var handler = %@.%@.methods.methodName;
                                         handler(info, function(data){
                                             %@.%@.postMessage({name:'%@', info:{name: methodName, info: data}});
                                         });
                                     }
                                     , kSTMApp, self.handlerName,
                                     kSTMApp, self.handlerName, kSTMNativeCallback
                                     );
    [self _addJSScript:jsScript forMainFrameOnly:YES];
}

#pragma mark -

- (void)_addJSScript:(NSString *)jsScript forMainFrameOnly:(BOOL)flag {
    if (!jsScript) { return; }
    jsScript = [NSString stringWithFormat:@";%@;", jsScript];
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jsScript
                                                      injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                   forMainFrameOnly:flag];
    [self.webView.configuration.userContentController addUserScript:userScript];
}

- (NSString *)_formatParameters:(NSDictionary *)parameters {
    NSString *formatParameter = nil;;
    if ([NSJSONSerialization isValidJSONObject:parameters]) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:nil];
        formatParameter = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else {
        formatParameter = parameters.description;
    }
    formatParameter = [formatParameter stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    formatParameter = [formatParameter stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    formatParameter = [formatParameter stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    formatParameter = [formatParameter stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    formatParameter = [formatParameter stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    formatParameter = [formatParameter stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    formatParameter = [formatParameter stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    formatParameter = [formatParameter stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    NSLog(@"%@", formatParameter);
    return formatParameter;
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:self.handlerName]) { return; }
    NSString *method = message.body[@"name"];
    NSDictionary *parameter = message.body[@"info"];
    STMHandler handler = self.methodHandlers[method];
    if ([method isEqualToString:kSTMNativeCallback]) {
        handler(parameter, nil);
    } else {
        handler(parameter, ^(id info){
            [self _response:method parameter:info];
        });
    }
}

#pragma mark - setter & getter

- (NSMutableDictionary *)methodHandlers {
    if (!_methodHandlers) {
        _methodHandlers = [NSMutableDictionary dictionary];
    }
    return _methodHandlers;
}

- (NSMutableDictionary *)jsResponseHandlers {
    if (!_jsResponseHandlers) {
        _jsResponseHandlers = [NSMutableDictionary dictionary];
    }
    return _jsResponseHandlers;
}

@end
