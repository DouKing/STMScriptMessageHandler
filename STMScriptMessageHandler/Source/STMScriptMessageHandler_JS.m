//
//  STMScriptMessageHandler_JS.m
//
//  Copyright (c) 2021-2025 DouKing (https://github.com/DouKing/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "STMScriptMessageHandler_JS.h"

// window.webkit.messageHandlers.<bridgeName>.postMessage(<messageBody>)

NSString * STMScriptMessageHandler_js(NSString *bridgeName) {
#define __smhn_js_func__(x) #x

	// BEGIN preprocessorJSCode
	NSString * preprocessorJSCode = @__smhn_js_func__(
;(function() {
		if (window.WebViewJavascriptBridge) {
			return;
		}

		if (!window.onerror) {
			window.onerror = function (msg, url, line) {
				console.log("WebViewJavascriptBridge: ERROR:" + msg + "@" + url + ":" + line);
			}
		}
		window.WebViewJavascriptBridge = {
			registerHandler: registerHandler,
			callHandler: callHandler,
			disableJavscriptAlertBoxSafetyTimeout: disableJavscriptAlertBoxSafetyTimeout,
			_handleMessageFromObjC: _handleMessageFromObjC
		};

		var messageHandlers = {};

		var responseCallbacks = {};
		var uniqueId = 1;
		var dispatchMessagesWithTimeoutSafety = true;

		function registerHandler(handlerName, handler) {
			messageHandlers[handlerName] = handler;
		}

		function callHandler(handlerName, data, responseCallback) {
			if (arguments.length == 2 && typeof data == 'function') {
				responseCallback = data;
				data = null;
			}
			return _doSend({ handlerName: handlerName, data: data }, responseCallback);
		}
        
		function disableJavscriptAlertBoxSafetyTimeout() {
			dispatchMessagesWithTimeoutSafety = false;
		}

		function _doSend(message, responseCallback) {
            if (responseCallback) {
                var callbackId = 'cb_' + (uniqueId++) + '_' + new Date().getTime();
                responseCallbacks[callbackId] = responseCallback;
                message['callbackId'] = callbackId;
                window.webkit.messageHandlers.WebViewJavascriptBridge.postMessage(message);
            } else {
                var promise = new Promise((resolve, reject) => {
                    var callbackId = 'cb_' + (uniqueId++) + '_' + new Date().getTime();
                    responseCallbacks[callbackId] = resolve;
                    message['resolveId'] = callbackId;
                    
                    var p = window.webkit.messageHandlers.WebViewJavascriptBridge.postMessage(message);
                    if (p instanceof Promise) {
                        p.then(result => resolve(result), error => reject(error));
                        delete responseCallbacks[callbackId];
                        delete message['resolveId'];
                    }
                });
                return promise;
            }
		}

		function _dispatchMessageFromObjC(messageJSON) {
			if (dispatchMessagesWithTimeoutSafety) {
				setTimeout(_doDispatchMessageFromObjC);
			} else {
				_doDispatchMessageFromObjC();
			}

			function _doDispatchMessageFromObjC() {
				var message = JSON.parse(messageJSON);
				var messageHandler;
				var responseCallback;

				if (message.responseId) {
					responseCallback = responseCallbacks[message.responseId];
					if (!responseCallback) {
						return;
					}
					responseCallback(message.responseData);
					delete responseCallbacks[message.responseId];
				} else {
					if (message.callbackId) {
						var callbackResponseId = message.callbackId;
						responseCallback = function (responseData) {
							_doSend({ handlerName: message.handlerName, responseId: callbackResponseId, responseData: responseData });
						};
					}

					var handler = messageHandlers[message.handlerName];
					if (!handler) {
						console.log("WebViewJavascriptBridge: WARNING: no handler for message from ObjC:", message);
					} else {
						handler(message.data, responseCallback);
					}
				}
			}
		}

		function _handleMessageFromObjC(messageJSON) {
			_dispatchMessageFromObjC(messageJSON);
		}

		registerHandler("_disableJavascriptAlertBoxSafetyTimeout", disableJavscriptAlertBoxSafetyTimeout);
	})();
		); // END preprocessorJSCode

#undef __smhn_js_func__
	return [preprocessorJSCode stringByReplacingOccurrencesOfString:@"WebViewJavascriptBridge" withString:bridgeName];
};
