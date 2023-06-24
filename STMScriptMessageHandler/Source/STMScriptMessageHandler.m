//
//  STMScriptMessageHandler.m
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

#import "STMScriptMessageHandler.h"
#import "STMScriptMessageHandler_JS.h"

static NSString * const kSTMMessageParameterNameKey = @"handlerName";
static NSString * const kSTMMessageParameterInfoKey = @"data";
static NSString * const kSTMMessageParameterResponseKey = @"responseData";
static NSString * const kSTMMessageParameterCallbackIdKey = @"callbackId";
static NSString * const kSTMMessageParameterResponseIdKey = @"responseId";
static NSString * const kSTMMessageParameterResolveIdKey = @"resolveId";
static NSString * const kSTMMessageParameterReplyKey = @"kSTMMessageParameterReplyKey";

static int gSTMCallbackUniqueId = 1;

@interface STMScriptMessageHandler ()

@property (nonatomic, copy) NSString *handlerName;
@property (nullable, nonatomic, weak) WKWebView *webView;

@property (nullable, nonatomic, strong) NSMutableDictionary *methodHandlers;
@property (nullable, nonatomic, strong) NSMutableDictionary *jsResponseHandlers;

@end

@implementation STMScriptMessageHandler

static BOOL gSTMEnableLog = NO;
+ (void)enableLog { gSTMEnableLog = YES; }

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
    [self _debug:@"SEND" parameters:message];
	NSString *messageJSON = [self _formatParameters:message];
	NSString* javascriptCommand = [NSString stringWithFormat:@"%@._handleMessageFromObjC('%@');", self.handlerName, messageJSON];
	[self _evaluateJavaScript:javascriptCommand];
}

//处理收到的 js 端消息
- (void)_flushReceivedMessage:(NSDictionary *)message {
	if (![message isKindOfClass:NSDictionary.class]) {
		return;
	}
    [self _debug:@"RECEIVE" parameters:message];
    
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
                    if (!responseData) {
                        responseData = [NSNull null];
                    }
                    void (^replyHandler)(id _Nullable reply, NSString *_Nullable errorMessage) = message[kSTMMessageParameterReplyKey];
                    NSString *resolveId = message[kSTMMessageParameterResolveIdKey];
                    if (replyHandler) {
                        [self _debug:@"SEND" parameters:responseData];
                        replyHandler(responseData, nil);
                    } else if (resolveId) {
                        [self _dispatchMessage:@{
                            kSTMMessageParameterResponseIdKey: resolveId,
                            kSTMMessageParameterResponseKey: responseData,
                        }];
                    }
				};
			}
		}
		STMHandler handler = self.methodHandlers[message[kSTMMessageParameterNameKey]];
		if (!handler) {
            responseCallback(@{});
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
                [self _log:[NSString stringWithFormat:@"Error: %@", error]];
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
    NSString *formatParameter = nil;
    if ([NSJSONSerialization isValidJSONObject:parameters]) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
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

- (void)_debug:(NSString *)action parameters:(NSDictionary *)parameters {
#ifdef DEBUG
    if (!gSTMEnableLog) { return; }
    NSLog(@"[%@] %@: %@", self.handlerName, action, parameters);
#endif
}

- (void)_log:(NSString *)message {
#ifdef DEBUG
    NSLog(@"[%@] %@", self.handlerName, message);
#endif
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:self.handlerName]) { return; }
    !self.didReceiveScriptMessage ?: self.didReceiveScriptMessage(message.body);
	[self _flushReceivedMessage:message.body];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message replyHandler:(void (^)(id _Nullable reply, NSString *_Nullable errorMessage))replyHandler API_AVAILABLE(macos(11.0), ios(14.0)) {
    if (![message.name isEqualToString:self.handlerName]) { return; }
    !self.didReceiveScriptMessage ?: self.didReceiveScriptMessage(message.body);
    
    NSMutableDictionary *parameters = [message.body mutableCopy];
    parameters[kSTMMessageParameterReplyKey] = replyHandler ?: ^(id _Nullable reply, NSString *_Nullable errorMessage){
        [self _log:@"reply handler is nil"];
    };
    [self _flushReceivedMessage:parameters];
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
