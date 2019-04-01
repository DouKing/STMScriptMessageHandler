[![996.icu](https://img.shields.io/badge/link-996.icu-red.svg)](https://996.icu)
[![LICENSE](https://img.shields.io/badge/license-NPL%20(The%20996%20Prohibited%20License)-blue.svg)](https://github.com/996icu/996.ICU/blob/master/LICENSE)

# STMScriptMessageHandler

![capture](./Capture.gif)


The `STMScriptMessageHandler` is used to comunicate with js for `WKWebView`. It implements `WKScriptMessageHandler` protocol. A `STMScriptMessageHandler` corresponding a js object. When your `WKWebView` add a `STMScriptMessageHandler`, the js side add a object automatically. The  handlerName of `STMScriptMessageHandler` is the js object's name.


## Requirements

iOS 8.0+

## Usage

- Native side

```objectivec

//When the native register a STMScriptMessageHandler called `Bridge`, the js register a object called `App.Bridge`.
STMScriptMessageHandler *messageHandler = [[STMScriptMessageHandler alloc] initWithScriptMessageHandlerName:@"Bridge" forWebView:self.webView];
[self.webView stm_addScriptMessageHandler:messageHandler];

// register a message handler named `Page`, so the js should call your method (that the message handler registered) use `App.Page.callMethod...`
STMScriptMessageHandler *page = [[STMScriptMessageHandler alloc] initWithScriptMessageHandlerName:@"Page" forWebView:self.webView];
[self.webView registerScriptMessageHandler:page];

[page registerMethod:@"setButtons" handler:^(id data, STMResponseCallback responseCallback) {
    [self setupRightBarButtonItems:data callback:responseCallback];
}];

```

- JS side

```javascript

// Use js object `App.Bridge` call native method or register method for native.
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

STMScriptMessageHandler is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'STMScriptMessageHandler'
```

## License

STMScriptMessageHandler is available under the MIT license and 996ICU license. See file `LICENSE.MIT` and `LICENSE.NPL` for more info.