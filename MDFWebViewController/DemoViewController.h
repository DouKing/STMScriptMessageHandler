//
//  DemoViewController.h
//  MDFWebViewController
//
//  Created by iosci on 2016/11/23.
//  Copyright © 2016年 secoo. All rights reserved.
//

#import "MDFWebViewController.h"

@interface DemoViewController : MDFWebViewController

@end

@interface DemoViewController ()
@property (nonatomic, strong) NSString *rightButton_callback;
@property (nonatomic, strong) NSString *leftButton_callback;
@end
@interface DemoViewController (NavigationBarButton)
- (void)_setupRightBarButtonItems:(NSArray<NSDictionary *> *)items;
- (void)_setupLeftBarButtonItems:(NSArray<NSDictionary *> *)items;
@end
