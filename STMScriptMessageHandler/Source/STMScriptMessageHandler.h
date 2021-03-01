//
//  STMScriptMessageHandler.h
//  Pods-STMWebViewController_Example
//
//  Created by DouKing on 2018/7/31.
//

@import UIKit;
@import WebKit;

NS_ASSUME_NONNULL_BEGIN

typedef void (^STMResponseCallback)(id responseData);
typedef void (^STMHandler)(id data, STMResponseCallback _Nullable responseCallback);

@interface STMScriptMessageHandler : NSObject<WKScriptMessageHandler>

@property (nonatomic, copy, readonly) NSString *handlerName;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithScriptMessageHandlerName:(NSString *)handlerName forWebView:(WKWebView *)webView;

- (void)prepareJsScript NS_REQUIRES_SUPER;

- (void)registerMethod:(NSString *)methodName handler:(STMHandler)handler;
- (void)removeMethod:(NSString *)methodName;

- (void)callMethod:(NSString *)methodName parameters:(id)parameters responseHandler:(nullable STMResponseCallback)handler;

@end


NS_ASSUME_NONNULL_END
