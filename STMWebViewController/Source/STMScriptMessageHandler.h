//
//  STMScriptMessageHandler.h
//  Pods-STMWebViewController_Example
//
//  Created by DouKing on 2018/7/31.
//

#import "STMWebViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^STMResponseCallback)(id responseData);
typedef void (^STMHandler)(id data, STMResponseCallback _Nullable responseCallback);

@interface STMScriptMessageHandler : NSObject<WKScriptMessageHandler>

@property (nullable, nonatomic, weak, readonly) STMWebViewController *webViewController;
@property (nullable, nonatomic, copy, readonly) NSString *handlerName;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithWebViewController:(__weak STMWebViewController *)webViewController;
- (void)prepareJsScript NS_REQUIRES_SUPER;

- (void)registerMethod:(NSString *)methodName handler:(STMHandler)handler;
- (void)callMethod:(NSString *)methodName parameters:(NSDictionary *)parameters responseHandler:(STMResponseCallback)handler;

@end

NS_ASSUME_NONNULL_END
