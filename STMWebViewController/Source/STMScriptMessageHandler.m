//
//  STMScriptMessageHandler.m
//  Pods-STMWebViewController_Example
//
//  Created by DouKing on 2018/7/31.
//

#import "STMScriptMessageHandler.h"
#import <objc/runtime.h>

#define STM_JS_FUNC(x, ...) [NSString stringWithFormat:@#x ,##__VA_ARGS__]
#define WEAK_SELF       __weak typeof(self) __weak_self__ = self
#define STRONG_SELF     __strong typeof(__weak_self__) self = __weak_self__
void _STMObjcSwizzMethod(Class aClass, SEL originSelector, SEL swizzSelector);

static NSString * const kSTMApp = @"App";
static NSString * const kSTMNativeCallback = @"nativeCallback";

static NSString * const kSTMMessageParameterNameKey = @"name";
static NSString * const kSTMMessageParameterInfoKey = @"info";

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

- (void)prepareJsScript {
    [self _addJS1];
    [self _addJS2];
    [self _addJS3];
    WEAK_SELF;
    [self registerMethod:kSTMNativeCallback handler:^(NSDictionary * _Nonnull data, STMResponseCallback  _Nullable responseCallback) {
        STRONG_SELF;
        NSString *methodName = data[kSTMMessageParameterNameKey];
        NSDictionary *info = data[kSTMMessageParameterInfoKey];
        STMResponseCallback jsResponse = self.jsResponseHandlers[methodName];
        !jsResponse ?: jsResponse(info);
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
    if (handler) {
        self.jsResponseHandlers[methodName] = handler;
    }
    NSString *formatParameter = [self _formatParameters:parameters];
    NSString *js = STM_JS_FUNC(%@.%@.nativeCall('%@', '%@'), kSTMApp, self.handlerName, methodName, formatParameter);
    [self.webView evaluateJavaScript:js completionHandler:nil];
    [self _debug:@"native call js's method" method:methodName parameters:parameters];
}

#pragma mark - Private

- (void)_response:(NSString *)methodName parameter:(nullable id)parameter {
    NSString *formatParameter = [self _formatParameters:parameter];
    NSString *js = STM_JS_FUNC(
        var callback = %@.%@.callback['%@'];
        if (callback) { callback('%@'); }
        , kSTMApp, self.handlerName, methodName, formatParameter
    );
    [self.webView evaluateJavaScript:js completionHandler:nil];
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
         %@.%@.methods.methodName = methodHandler;
        }
        , kSTMApp, self.handlerName,
        kSTMApp, self.handlerName,
        kSTMApp, self.handlerName,
        kSTMApp, self.handlerName
    );
    [self _addJSScript:jsScript forMainFrameOnly:YES];

    NSString *js = STM_JS_FUNC(
        if (!%@.%@.callback) {
           %@.%@.callback = {};
        };
        %@.%@.callMethod = function(name, info, callback) {
           %@.%@.callback[name] = callback;
           %@.%@.postMessage({name:name, info:info});
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
        %@.%@.nativeCall = function(methodName, info) {
         var handler = %@.%@.methods.methodName;
         handler(info, function(data){
             %@.%@.postMessage({name:'%@', info:{name: methodName, info: data}});
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
    STMHandler handler = self.methodHandlers[method];
    if ([method isEqualToString:kSTMNativeCallback]) {
        handler(parameter, nil);
        [self _debug:@"native receive js's response" method:parameter[kSTMMessageParameterNameKey] parameters:parameter[kSTMMessageParameterInfoKey]];
    } else {
        [self _debug:@"js call native's method" method:method parameters:parameter];
        WEAK_SELF;
        handler(parameter, ^(id info) {
            STRONG_SELF;
            [self _response:method parameter:info];
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

#pragma mark -

static char * const kSTMWebViewScriptMessageHandlersKey = "kSTMWebViewScriptMessageHandlersKey";

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

- (void)stm_addScriptMessageHandler:(__kindof STMScriptMessageHandler *)msgHandler {
    [[self stm_scriptMessageHandlers] addObject:msgHandler];
    [self _stm_addScriptMessageHandler:msgHandler];
}

- (NSArray<STMScriptMessageHandler *> *)stm_registeredMessageHandlers {
    return [[self stm_scriptMessageHandlers] copy];
}

- (void)_stm_addScriptMessageHandler:(__kindof STMScriptMessageHandler *)messageHandler {
    WKUserContentController *userContentController = self.configuration.userContentController;
    [userContentController removeScriptMessageHandlerForName:messageHandler.handlerName];
    [userContentController addScriptMessageHandler:messageHandler name:messageHandler.handlerName];
}

- (void)_stm_removeScriptMessageHandler:(__kindof STMScriptMessageHandler *)messageHandler {
    WKUserContentController *userContentController = self.configuration.userContentController;
    [userContentController removeScriptMessageHandlerForName:messageHandler.handlerName];
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
