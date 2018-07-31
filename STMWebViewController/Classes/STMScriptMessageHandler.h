//
//  STMScriptMessageHandler.h
//  Pods-STMWebViewController_Example
//
//  Created by DouKing on 2018/7/31.
//

#import "STMWebViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol STMScriptMessageHandlerProtocol <WKScriptMessageHandler>

- (NSString *)handlerName;

@end

@interface STMScriptMessageHandler : NSObject

@property (nullable, nonatomic, weak, readonly) STMWebViewController *webViewController;
@property (nullable, nonatomic, weak, readonly) id<STMScriptMessageHandlerProtocol> child;

- (instancetype)initWithWebViewController:(STMWebViewController *)webViewController;

@end

NS_ASSUME_NONNULL_END
