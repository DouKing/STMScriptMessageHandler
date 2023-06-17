//
//  STMScriptMessageHandler.h
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

@import UIKit;
@import WebKit;

NS_ASSUME_NONNULL_BEGIN

typedef void (^STMResponseCallback)(id responseData);
typedef void (^STMHandler)(id data, STMResponseCallback _Nullable responseCallback);

@interface STMScriptMessageHandler : NSObject<WKScriptMessageHandler, WKScriptMessageHandlerWithReply>

@property (nonatomic, copy, readonly) NSString *handlerName;
@property (nullable, nonatomic, copy) void (^didReceiveScriptMessage)(id message);

+ (void)enableLog;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithScriptMessageHandlerName:(NSString *)handlerName forWebView:(WKWebView *)webView;

- (void)prepareJsScript NS_REQUIRES_SUPER;

- (void)registerMethod:(NSString *)methodName handler:(STMHandler)handler;
- (void)removeMethod:(NSString *)methodName;

- (void)callMethod:(NSString *)methodName parameters:(id)parameters responseHandler:(nullable STMResponseCallback)handler;

@end


NS_ASSUME_NONNULL_END
