//
//  MDFWebViewController.m
//  MDFWebViewController
//
//  Created by iosci on 2016/11/23.
//  Copyright © 2016年 secoo. All rights reserved.
//

#import "MDFWebViewController.h"
#import <SDWebImage/UIButton+WebCache.h>
#import "MDFWebPageSetting.h"

static NSString * const kMDFBarItemTitleKey = @"title";
static NSString * const kMDFBarItemImageKey = @"image";
static NSString * const kMFDBarItemImageURLKey = @"imageURL";
static NSInteger const kMDFRightBarItemBaseTag = 3001;
static NSInteger const kMDFLeftBarItemBaseTag  = 1001;

@interface MDFWebViewController ()<MDFWebPageSettingDelegate>

@property (nonatomic, strong, readwrite) WKWebView *webView;
@property (nonatomic, strong) NSMutableArray<NSString *> *jsMethods;

@end

@interface MDFWebViewController (NavigationBarButton)

- (void)_setupRightBarButtonItems:(NSArray<NSDictionary *> *)items;
- (void)_setupLeftBarButtonItems:(NSArray<NSDictionary *> *)items;

@end

@implementation MDFWebViewController

- (void)dealloc {
    [_webView stopLoading];
    for (NSString *name in _jsMethods) {
        [_webView.configuration.userContentController removeScriptMessageHandlerForName:name];
    }
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self registerJSMethods];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self registerJSMethods];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.webView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.webView evaluateJavaScript:@"viewWillAppear()" completionHandler:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.webView evaluateJavaScript:@"viewDidAppear()" completionHandler:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.webView evaluateJavaScript:@"viewWillDisappear()" completionHandler:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.webView.frame = self.view.bounds;
}

- (void)addScriptMessageHandler:(__kindof MDFScriptMessageHandlerManager *)scriptMessageHandler {
    scriptMessageHandler.webView = self.webView;
    WKUserContentController *userContentController = self.webView.configuration.userContentController;
    __weak typeof(self) weakSelf = self;
    [[scriptMessageHandler jsMethodNames] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [userContentController removeScriptMessageHandlerForName:obj];
        [userContentController addScriptMessageHandler:scriptMessageHandler name:obj];
        [strongSelf.jsMethods addObject:obj];
    }];
}

- (void)registerJSMethods {
    MDFWebPageSetting *webPageSetting = [[MDFWebPageSetting alloc] init];
    webPageSetting.delegate = self;
    [self addScriptMessageHandler:webPageSetting];
}

#pragma mark - Private Methods


#pragma mark - Delegates
#pragma mark - MDFWebPageSettingDelegate

- (void)webPageSetting:(MDFWebPageSetting *)webPageSetting didReceiveScriptMessage:(WKScriptMessage *)message atUserContentController:(WKUserContentController *)userContentController {
    NSString *name = message.name;
    if ([name isEqualToString:kMDFWebPageSettingJSMethodNameSetRightBarButtonsAction]) {
        NSArray<NSDictionary *> *btns = message.body;
        [self _setupRightBarButtonItems:btns];
    }
}

#pragma mark - setter & getter

- (WKWebView *)webView {
    if (!_webView) {
        NSString *jScript = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);";
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        
        WKUserContentController *userContentController = [[WKUserContentController alloc] init];
        [userContentController addUserScript:userScript];
        
        WKPreferences *preferences = [[WKPreferences alloc] init];
        preferences.javaScriptCanOpenWindowsAutomatically = YES;
        
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        config.allowsInlineMediaPlayback = YES;
        config.userContentController = userContentController;
        config.preferences = preferences;
        
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    }
    return _webView;
}

- (NSMutableArray<NSString *> *)jsMethods {
    if (!_jsMethods) {
        _jsMethods = [NSMutableArray array];
    }
    return _jsMethods;
}

@end

@implementation MDFWebViewController (NavigationBarButton)

- (void)_setupRightBarButtonItems:(NSArray<NSDictionary *> *)items {
    [self _setupNavigationBarButtonItems:items onRight:YES];
}

- (void)_setupLeftBarButtonItems:(NSArray<NSDictionary *> *)items {
    [self _setupNavigationBarButtonItems:items onRight:NO];
}

- (void)_handleRightBarButtonItemAction:(UIBarButtonItem *)sender {
    NSString *action = [NSString stringWithFormat:@"handleRightButtonClick('%ld')", sender.tag - kMDFRightBarItemBaseTag];
    [self.webView evaluateJavaScript:action completionHandler:nil];
}

- (void)_handleLeftBarButtonItemAction:(UIBarButtonItem *)sender {
    NSString *action = [NSString stringWithFormat:@"handleLeftButtonClick('%ld')", sender.tag - kMDFRightBarItemBaseTag];
    [self.webView evaluateJavaScript:action completionHandler:nil];
}

- (void)_setupNavigationBarButtonItems:(NSArray<NSDictionary *> *)items onRight:(BOOL)flag {
    NSMutableArray<UIBarButtonItem *> *temp = [NSMutableArray arrayWithCapacity:items.count];
    [items enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *icon = obj[kMDFBarItemImageKey];  //图片代号
        NSString *text = obj[kMDFBarItemTitleKey];  //按钮名字
        NSString *url = obj[kMFDBarItemImageURLKey]; //图片URL
        UIImage *image = [UIImage imageNamed:icon];
        UIBarButtonItem *barButtonItem = nil;
        SEL barButtonItemAction = flag ? @selector(_handleRightBarButtonItemAction:) : @selector(_handleLeftBarButtonItemAction:);
        if (image) {
            barButtonItem = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:barButtonItemAction];
        } else if (url.length) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(0, 0, 22, 22);
            if (flag) {
                [btn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
            } else {
                [btn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            }
            [btn sd_setImageWithURL:[NSURL URLWithString:url] forState:UIControlStateNormal];
            [btn addTarget:self action:barButtonItemAction forControlEvents:UIControlEventTouchUpInside];
            barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
        } else {
            barButtonItem = [[UIBarButtonItem alloc] initWithTitle:text style:UIBarButtonItemStylePlain target:self action:barButtonItemAction];
        }
        if (flag) {
            barButtonItem.tag = kMDFRightBarItemBaseTag + idx;
        } else {
            barButtonItem.tag = kMDFLeftBarItemBaseTag + idx;
        }
        [temp addObject:barButtonItem];
    }];
    if (flag) {
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithArray:temp];
    } else {
        self.navigationItem.leftBarButtonItems = [NSArray arrayWithArray:temp];
    }
}

@end

