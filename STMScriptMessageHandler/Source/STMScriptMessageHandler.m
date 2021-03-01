//
//  STMScriptMessageHandler.m
//  Pods-STMWebViewController_Example
//
//  Created by DouKing on 2018/7/31.
//

#import "STMScriptMessageHandler.h"
#import "STMScriptMessageHandler_JS.h"

#define STM_JS_FUNC(x, ...) [NSString stringWithFormat:@#x ,##__VA_ARGS__]
#define WEAK_SELF       __weak typeof(self) __weak_self__ = self
#define STRONG_SELF     __strong typeof(__weak_self__) self = __weak_self__

static NSString * const kSTMApp = @"App";
static NSString * const kSTMNativeCallback = @"nativeCallback";
static NSString * const kSTMMethodHandlerReuseKey = @"kSTMMethodHandlerReuseKey";
static NSString * const kSTMMethodHandlerIMPKey = @"kSTMMethodHandlerIMPKey";

static NSString * const kSTMMessageParameterNameKey = @"handlerName";
static NSString * const kSTMMessageParameterInfoKey = @"data";
static NSString * const kSTMMessageParameterResponseKey = @"responseData";
static NSString * const kSTMMessageParameterCallbackIdKey = @"callbackId";
static NSString * const kSTMMessageParameterResponseIdKey = @"responseId";

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
	NSString *js = STMScriptMessageHandler_js(self.handlerName);
//	[self _evaluateJavaScript:js];
	[self _addJSScript:js forMainFrameOnly:NO];
}

- (void)registerMethod:(NSString *)methodName handler:(nonnull STMHandler)handler {
    if (!methodName || !handler) { return; }
    if (handler) {
		self.methodHandlers[methodName] = handler;
    }
}

- (void)removeMethod:(NSString *)methodName {
	if (!methodName) { return; }
	[self.methodHandlers removeObjectForKey:methodName];
}

- (void)callMethod:(NSString *)methodName parameters:(id)parameters responseHandler:(STMResponseCallback)handler {
    if (!methodName) { return; }
	NSMutableDictionary *message = [NSMutableDictionary dictionary];
	if (parameters) {
		message[kSTMMessageParameterInfoKey] = parameters;
	}

    if (handler) {
        NSString *callbackId = [NSString stringWithFormat:@"cb_%d_%.0f", gSTMCallbackUniqueId++, [NSDate timeIntervalSinceReferenceDate] * 1000];
        self.jsResponseHandlers[callbackId] = handler;
		message[kSTMMessageParameterCallbackIdKey] = callbackId;
    }

	message[kSTMMessageParameterNameKey] = methodName;
	[self _dispatchMessage:message];
}

#pragma mark - Private

//给 js 端发送消息
- (void)_dispatchMessage:(NSDictionary *)message {
	NSString *messageJSON = [self _formatParameters:message];
	NSString* javascriptCommand = [NSString stringWithFormat:@"%@._handleMessageFromObjC('%@');", self.handlerName, messageJSON];
	[self _evaluateJavaScript:javascriptCommand];
}

//处理收到的 js 端消息
- (void)_flushReceivedMessage:(NSDictionary *)message {
	if (![message isKindOfClass:NSDictionary.class]) {
		return;
	}

	NSString *responseId = message[kSTMMessageParameterResponseIdKey];
	if (responseId) {
		STMResponseCallback responseCallback = self.jsResponseHandlers[responseId];
		!responseCallback ?: responseCallback(message[kSTMMessageParameterResponseKey]);
		[self.jsResponseHandlers removeObjectForKey:responseId];
	} else {
		STMResponseCallback responseCallback; {
			NSString *callbackId = message[kSTMMessageParameterCallbackIdKey];
			if (callbackId) {
				responseCallback = ^(id responseData){
					if (!responseData) {
						responseData = [NSNull null];
					}
					[self _dispatchMessage:@{
						kSTMMessageParameterResponseIdKey: callbackId,
						kSTMMessageParameterResponseKey: responseData,
					}];
				};
			} else {
				responseCallback = ^(id responseData){
				};
			}
		}
		STMHandler handler = self.methodHandlers[message[kSTMMessageParameterNameKey]];
		if (!handler) {
			return;
		}
		handler(message[kSTMMessageParameterInfoKey], responseCallback);
	}
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
				NSLog(@"Error: %@", error);
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
	[self _flushReceivedMessage:message.body];
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
