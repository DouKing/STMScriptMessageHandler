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

- (instancetype)initWithWebViewController:(STMWebViewController *)webViewController;
- (void)registerMethod:(NSString *)methodName handler:(STMHandler)handler;

@end

NS_ASSUME_NONNULL_END
