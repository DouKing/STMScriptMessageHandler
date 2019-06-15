//
//  WKWebView+STMScriptMessage.h
//  STMScriptMessageHandler
//
//  Created by DouKing on 2019/6/15.
//

#import "STMScriptMessageHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (STMScriptMessage)

@property (nullable, nonatomic, strong, readonly) STMScriptMessageHandler *stm_defaultScriptMessageHandler;
@property (nullable, nonatomic, strong, readonly) NSArray<STMScriptMessageHandler *> *stm_registeredMessageHandlers;

- (nullable STMScriptMessageHandler *)stm_addScriptMessageHandlerUseName:(NSString *)handlerName;
- (void)stm_addScriptMessageHandler:(__kindof STMScriptMessageHandler *)msgHandler;

@end

NS_ASSUME_NONNULL_END
