# STMWebViewController

[![CI Status](https://img.shields.io/travis/douking/STMWebViewController.svg?style=flat)](https://travis-ci.org/douking/STMWebViewController)
[![Version](https://img.shields.io/cocoapods/v/STMWebViewController.svg?style=flat)](https://cocoapods.org/pods/STMWebViewController)
[![License](https://img.shields.io/cocoapods/l/STMWebViewController.svg?style=flat)](https://cocoapods.org/pods/STMWebViewController)
[![Platform](https://img.shields.io/cocoapods/p/STMWebViewController.svg?style=flat)](https://cocoapods.org/pods/STMWebViewController)

![capture](./Capture.gif)

## Requirements

iOS 8.0+

## Usage

- Native side

```Objc

// Use `self.messageHandler` register a method for js, the js should call this use App.Bridge.callMethod...
[self.messageHandler registerMethod:@"nslog" handler:^(id  _Nonnull data, STMResponseCallback  _Nullable responseCallback) {
    NSLog(@"native receive js calling `nslog`: %@", data);
    responseCallback(@"native `nslog` done!");
}];

[self.messageHandler registerMethod:@"testNativeMethod" handler:^(id  _Nonnull data, STMResponseCallback  _Nullable responseCallback) {
    NSLog(@"native receive js calling `testNativeMethod`: %@", data);
    responseCallback(@(200));
}];

// You can register yourself message handler.

// register a message handler named `Page`, so the js should call your method (that the message handler registered) use App.Page.callMethod...
self.page = [[STMScriptMessageHandler alloc] initWithScriptMessageHandlerName:@"Page" forWebView:self.webView];
[self registerScriptMessageHandler:self.page];

[self.page registerMethod:@"setButtons" handler:^(id data, STMResponseCallback responseCallback) {
    [self setupRightBarButtonItems:data callback:responseCallback];
}];
```

- JS side

```js

App.Bridge.callMethod('testNativeMethod', {foo:'foo1', bar: 'bar1'}, function(data){
                        log('JS got native `testNativeMethod` response', data);
                     });

App.Bridge.registerMethod('log', function(data, callback){
                           var message = JSON.parse(data);
                           log('Native calling js method `log`', message);
                           callback({key: 'from js', value: 'something'});
                        });
```

## Installation

STMWebViewController is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'STMWebViewController'
```

## License

STMWebViewController is available under the MIT license. See the LICENSE file for more info.
