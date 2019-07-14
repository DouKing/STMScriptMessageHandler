//
//  STMScriptMessageHandler.m
//  Pods-STMWebViewController_Example
//
//  Created by DouKing on 2018/7/31.
//

#import "STMScriptMessageHandler.h"

#define STM_JS_FUNC(x, ...) [NSString stringWithFormat:@#x ,##__VA_ARGS__]
#define WEAK_SELF       __weak typeof(self) __weak_self__ = self
#define STRONG_SELF     __strong typeof(__weak_self__) self = __weak_self__

static NSString * const kSTMApp = @"App";
static NSString * const kSTMNativeCallback = @"nativeCallback";

static NSString * const kSTMMessageParameterNameKey = @"name";
static NSString * const kSTMMessageParameterInfoKey = @"info";
static NSString * const kSTMMessageParameterCallbackIdKey = @"callbackId";
static int gSTMCallbackUniqueId = 1;

@interface STMScriptMessageHandler ()

@property (nonatomic, copy) NSString *handlerName;
@property (nullable, nonatomic, weak) WKWebView *webView;

@property (nullable, nonatomic, strong) NSMutableDictionary *methodHandlers;
@property (nullable, nonatomic, strong) NSMutableDictionary *jsResponseHandlers;

@end

@implementation STMScriptMessageHandler

- (instancetype)initWithScriptMessageHandlerName:(NSString *)handlerName forWebView:(WKWebView * _Nonnull)webView {
    self = [super init];
    if (self) {
        _handlerName = [handlerName copy];
        _webView = webView;
        [self prepareJsScript];
    }
    return self;
}

- (void)prepareJsScript {
    [self _addJS1];
    [self _addJS2];
    [self _addJS3];
    WEAK_SELF;
    [self registerMethod:kSTMNativeCallback handler:^(NSDictionary * _Nonnull data, STMResponseCallback  _Nullable responseCallback) {
        STRONG_SELF;
        NSDictionary *info = data[kSTMMessageParameterInfoKey];
        NSString *callbackId = data[kSTMMessageParameterCallbackIdKey] ?: @"";
        STMResponseCallback jsResponse = self.jsResponseHandlers[callbackId];
        !jsResponse ?: jsResponse(info);
        [self.jsResponseHandlers removeObjectForKey:callbackId];
    }];
}

- (void)registerMethod:(NSString *)methodName handler:(STMHandler)handler {
    if (!methodName) { return; }
    if (handler) {
        self.methodHandlers[methodName] = handler;
    }
}

- (void)callMethod:(NSString *)methodName parameters:(NSDictionary *)parameters responseHandler:(STMResponseCallback)handler {
    if (!methodName) { return; }
    NSString *callbackId = @"";
    if (handler) {
        callbackId = [NSString stringWithFormat:@"cb_%d_%.0f", gSTMCallbackUniqueId++, [NSDate timeIntervalSinceReferenceDate] * 1000];
        self.jsResponseHandlers[callbackId] = handler;
    }
    NSString *formatParameter = [self _formatParameters:parameters];
    NSString *js = STM_JS_FUNC(%@.%@.nativeCall('%@','%@','%@'), kSTMApp, self.handlerName, methodName, formatParameter, callbackId);
    [self _evaluateJavaScript:js completionHandler:nil];
    [self _debug:@"native call js's method" method:methodName parameters:parameters];
}

#pragma mark - Private

- (void)_response:(NSString *)methodName callbackId:(NSString *)callbackId parameter:(nullable id)parameter {
    NSString *formatParameter = [self _formatParameters:parameter];
    callbackId = callbackId ?: @"";
    NSString *js = STM_JS_FUNC(
        var callback = %@.%@.callback['%@'];
        if (callback) { callback('%@'); delete %@.%@.callback.%@}
        , kSTMApp, self.handlerName, callbackId, formatParameter, kSTMApp, self.handlerName, callbackId
    );
    [self _evaluateJavaScript:js completionHandler:nil];
}

- (void)_addJS1 {
    NSString *jsScript = STM_JS_FUNC(var %@ = window.webkit.messageHandlers;, kSTMApp);
    [self _addJSScript:jsScript forMainFrameOnly:YES];
}

- (void)_addJS2 {
    NSString *jsScript = STM_JS_FUNC(
        %@.%@.registerMethod = function(methodName, methodHandler) {
         if (!%@.%@.methods) {
             %@.%@.methods = {};
         }
         %@.%@.methods[methodName] = methodHandler;
        }
        , kSTMApp, self.handlerName,
        kSTMApp, self.handlerName,
        kSTMApp, self.handlerName,
        kSTMApp, self.handlerName
    );
    [self _addJSScript:jsScript forMainFrameOnly:YES];

    NSString *js = STM_JS_FUNC(
        var callbackUniqueId = 1;
        if (!%@.%@.callback) {
           %@.%@.callback = {};
        };
        %@.%@.callMethod = function(name, info, callback) {
            var message = {};
            message['name'] = name;
            message['info'] = info;
            if (callback) {
                var callbackId = 'cb_'+(callbackUniqueId++)+'_'+new Date().getTime();
                %@.%@.callback[callbackId] = callback;
                message['callbackId'] = callbackId;
            }
            %@.%@.postMessage(message);
        };
        , kSTMApp, self.handlerName,
        kSTMApp, self.handlerName,
        kSTMApp, self.handlerName,
        kSTMApp, self.handlerName,
        kSTMApp, self.handlerName
    );
    [self _addJSScript:js forMainFrameOnly:YES];
}

- (void)_addJS3 {
    NSString *jsScript = STM_JS_FUNC(
        %@.%@.nativeCall = function(methodName, info, callbackId) {
         var handler = %@.%@.methods[methodName];
         handler(info, function(data){
             %@.%@.postMessage({name:'%@',info:{name:methodName,info:data,callbackId:callbackId}});
         });
        }
        , kSTMApp, self.handlerName,
        kSTMApp, self.handlerName,
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

- (void)_evaluateJavaScript:(NSString *)javaScriptString
          completionHandler:(void (^ _Nullable)(_Nullable id info, NSError * _Nullable error))completionHandler {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.webView evaluateJavaScript:javaScriptString completionHandler:completionHandler];
    });
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
    return formatParameter;
}

- (void)_debug:(NSString *)name method:(NSString *)method parameters:(NSDictionary *)parameters {
#ifdef DEBUG
    NSString *debug = STM_JS_FUNC([%@] %@: %@, name, method, parameters);
    NSLog(@"%@", debug);
#endif
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:self.handlerName]) { return; }
    NSString *method = message.body[kSTMMessageParameterNameKey];
    NSDictionary *parameter = message.body[kSTMMessageParameterInfoKey];
    NSString *callbackId = message.body[kSTMMessageParameterCallbackIdKey];
    STMHandler handler = self.methodHandlers[method];
    if ([method isEqualToString:kSTMNativeCallback]) {
        handler(parameter, nil);
        [self _debug:@"native receive js's response" method:parameter[kSTMMessageParameterNameKey] parameters:parameter[kSTMMessageParameterInfoKey]];
    } else {
        [self _debug:@"js call native's method" method:method parameters:parameter];
        WEAK_SELF;
        handler(parameter, ^(id info) {
            STRONG_SELF;
            [self _response:method callbackId:callbackId parameter:info];
            [self _debug:@"js receive native's response" method:method parameters:info];
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
