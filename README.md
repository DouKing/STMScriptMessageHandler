[![996.icu](https://img.shields.io/badge/link-996.icu-red.svg)](https://996.icu)
[![LICENSE](https://img.shields.io/badge/license-Anti%20996-blue.svg)](https://github.com/996icu/996.ICU/blob/master/LICENSE)

# STMScriptMessageHandler

<img src="./Capture.gif" style="float:right">

The `STMScriptMessageHandler` is used to comunicate with js for `WKWebView`. It implements `WKScriptMessageHandler` and `WKScriptMessageHandlerWithReply` protocol. A `STMScriptMessageHandler` corresponding a js object. When your `WKWebView` add a `STMScriptMessageHandler`, the js side add a object on the window automatically. The  handlerName of `STMScriptMessageHandler` is the js object's name.

## Features

- [x] Support multi message handlers
- [x] Support Promise
- [x] Compatible with `WebViewJavascriptBridge`

## Requirements

iOS 8.0+

## Usage

#### Native side

```objectivec

//When the native register a STMScriptMessageHandler called `Bridge`, the js register a object called `window.Bridge`.
STMScriptMessageHandler *messageHandler = [[STMScriptMessageHandler alloc] initWithScriptMessageHandlerName:@"Bridge" forWebView:self.webView];
[self.webView stm_addScriptMessageHandler:messageHandler];

// register a message handler named `Page`, so the js should call your method (that the message handler registered) use `window.Page.callMethod...`
STMScriptMessageHandler *page = [[STMScriptMessageHandler alloc] initWithScriptMessageHandlerName:@"Page" forWebView:self.webView];
[self.webView registerScriptMessageHandler:page];

[page registerMethod:@"setButtons" handler:^(id data, STMResponseCallback responseCallback) {
    [self setupRightBarButtonItems:data callback:responseCallback];
}];

```

#### JS side

```javascript
// Use js object `window.Bridge` call native method or register method for native.
window.Bridge.callHandler('nslog', data, function (data) {
    log('JS got native `nslog` response', data);
});

window.Bridge.registerMethod('log', function(data, callback){
    var message = JSON.parse(data);
    log('Native calling js method `log`', message);
    callback({key: 'from js', value: 'something'});
});

// Support Promise
async function promise(data) {
    // window.Bridge.callHandler('nslog', data).then(
    //     result => log('JS got native `nslog` response', result),
    //     error => log('JS got native `nslog` error', error)
    // )

    var p = window.Bridge.callHandler('nslog', data);
    var result = await p;
    log('JS got native `nslog` response', result);
}
```

#### Migrate from `WebViewJavascriptBridge`

If you register a message handler named `WebViewJavascriptBridge` at native side, the js side dones not need modify any code.

```objectivec

// The bridge's name is `WebViewJavascriptBridge`
self.bridge = [self.webView stm_addScriptMessageHandlerUseName:@"WebViewJavascriptBridge"];

```

## Installation

STMScriptMessageHandler is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'STMScriptMessageHandler'
```

## License

STMScriptMessageHandler is available under the MIT license and 996ICU license. See file `LICENSE.MIT` and `LICENSE.NPL` for more info.