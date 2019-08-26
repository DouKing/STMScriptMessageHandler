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
static NSString * const kSTMMethodHandlerReuseKey = @"kSTMMethodHandlerReuseKey";
static NSString * const kSTMMethodHandlerIMPKey = @"kSTMMethodHandlerIMPKey";

static NSString * const kSTMMessageParameterNameKey = @"name";
static NSString * const kSTMMessageParameterInfoKey = @"info";
static NSString * const kSTMMessageParameterCallbackIdKey = @"callbackId";
static NSString * const kSTMMessageParameterReuseKey = @"reuse";

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
        BOOL reuse = [data[kSTMMessageParameterReuseKey] boolValue];
        STMResponseCallback jsResponse = self.jsResponseHandlers[callbackId];
        !jsResponse ?: jsResponse(info);
        if (!reuse) {
            [self.jsResponseHandlers removeObjectForKey:callbackId];
        }
    }];
}

- (void)registerMethod:(NSString *)methodName handler:(STMHandler)handler {
    [self registerMethod:methodName reuseHandler:NO handler:handler];
}

- (void)registerMethod:(NSString *)methodName reuseHandler:(BOOL)reuse handler:(nonnull STMHandler)handler {
    if (!methodName || !handler) { return; }
    if (handler) {
        self.methodHandlers[methodName] = @{kSTMMethodHandlerReuseKey : @(reuse),
                                            kSTMMethodHandlerIMPKey : handler};
    }
}

- (void)callMethod:(NSString *)methodName parameters:(NSDictionary *)parameters responseHandler:(STMResponseCallback)handler {
    if (!methodName) { return; }
    NSString *callbackId = @"";
    if (handler) {
        callbackId = [NSString stringWithFormat:@"cb_%d_%.0f", gSTMCallbackUniqueId++, [NSDate timeIntervalSinceReferenceDate] * 1000];
        self.jsResponseHandlers[callbackId] = handler;
    }
    NSString *formatParameter = [self _formatParameters:@{@"parameters": parameters}];
    NSString *js = STM_JS_FUNC(%@.%@.nativeCall('%@',JSON.parse('%@').parameters,'%@'), kSTMApp, self.handlerName, methodName, formatParameter, callbackId);
    [self _evaluateJavaScript:js];
    [self _debug:@"native call js's method" method:methodName parameters:parameters];
}

#pragma mark - Private

- (void)_response:(NSString *)methodName callbackId:(NSString *)callbackId parameter:(nullable id)parameter deleteCallback:(BOOL)delete {
    NSString *formatParameter = [self _formatParameters:@{@"responseData": parameter}];
    callbackId = callbackId ?: @"";
    NSString *js = STM_JS_FUNC(
        var callback = %@.%@.callback['%@'];
        if (callback) { callback(JSON.parse('%@').responseData); if (%d) { delete %@.%@.callback.%@ }}
        , kSTMApp, self.handlerName, callbackId, formatParameter, delete, kSTMApp, self.handlerName, callbackId
    );
    [self _evaluateJavaScript:js];
}

- (void)_addJS1 {
    NSString *jsScript = STM_JS_FUNC(var %@ = window.webkit.messageHandlers;, kSTMApp);
    [self _addJSScript:jsScript forMainFrameOnly:YES];
}

- (void)_addJS2 {
    NSString *jsScript = STM_JS_FUNC(
        %@.%@.registerMethod = function(methodName, methodHandler, reuse) {
            if (!%@.%@.methods) {
                %@.%@.methods = {};
            }
            var handlerInfo = {};
            handlerInfo['imp'] = methodHandler;
            handlerInfo['reuse'] = reuse;
            %@.%@.methods[methodName] = handlerInfo;
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
            var handlerInfo = %@.%@.methods[methodName];
            var reuse = handlerInfo['reuse'];
            var handler = handlerInfo['imp'];
            handler(info, function(data){
                %@.%@.postMessage({name:'%@',info:{name:methodName,info:data,callbackId:callbackId,reuse:reuse}});
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

- (void)_evaluateJavaScript:(NSString *)javaScriptString {
    void (^task)(void) = ^{
        __weak typeof(self) __weak_self__ = self;
        [self.webView evaluateJavaScript:javaScriptString completionHandler:^(id _Nullable info, NSError * _Nullable error) {
            __strong typeof(__weak_self__) self = __weak_self__;
            if (error) {
                [self.webView reload];
            }
        }];
    };
    if ([NSThread currentThread].isMainThread) {
        task();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            task();
        });
    }
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
    NSDictionary *handlerInfo = self.methodHandlers[method];
    STMHandler handler = handlerInfo[kSTMMethodHandlerIMPKey];
    BOOL reuseHandler = [handlerInfo[kSTMMethodHandlerReuseKey] boolValue];
    if ([method isEqualToString:kSTMNativeCallback]) {
        handler(parameter, nil);
        [self _debug:@"native receive js's response" method:parameter[kSTMMessageParameterNameKey] parameters:parameter[kSTMMessageParameterInfoKey]];
    } else {
        [self _debug:@"js call native's method" method:method parameters:parameter];
        WEAK_SELF;
        handler(parameter, ^(id info) {
            STRONG_SELF;
            [self _response:method callbackId:callbackId parameter:info deleteCallback:!reuseHandler];
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
