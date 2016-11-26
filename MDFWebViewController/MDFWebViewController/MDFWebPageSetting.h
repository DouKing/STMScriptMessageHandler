//
//  MDFWebPageSetting.h
//  MDFWebViewController
//
//  Created by iosci on 2016/11/23.
//  Copyright © 2016年 secoo. All rights reserved.
//

#import "MDFScriptMessageHandlerManager.h"

NS_ASSUME_NONNULL_BEGIN

@class MDFWebPageSetting;

extern NSString * const kMDFWebPageSettingJSMethodNameSetRightBarButtonsAction;

@protocol MDFWebPageSettingDelegate <NSObject>

- (void)webPageSetting:(MDFWebPageSetting *)webPageSetting didReceiveScriptMessage:(WKScriptMessage *)message atUserContentController:(WKUserContentController *)userContentController ;

@end

@interface MDFWebPageSetting : MDFScriptMessageHandlerManager

@property (nonatomic, weak, nullable) id<MDFWebPageSettingDelegate> delegate;

@end


NS_ASSUME_NONNULL_END
