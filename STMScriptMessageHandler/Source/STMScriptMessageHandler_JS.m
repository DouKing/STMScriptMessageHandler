//
//  STMScriptMessageHandler_JS.m
//  STMScriptMessageHandler
//
//  Created by DouKing on 2021/2/26.
//

#import "STMScriptMessageHandler_JS.h"

// window.webkit.messageHandlers.bridge.postMessage(<messageBody>)
// App = window.webkit.messageHandlers

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
			_doSend({ handlerName: handlerName, data: data }, responseCallback);
		}
		function disableJavscriptAlertBoxSafetyTimeout() {
			dispatchMessagesWithTimeoutSafety = false;
		}

		function _doSend(message, responseCallback) {
			if (responseCallback) {
				var callbackId = 'cb_' + (uniqueId++) + '_' + new Date().getTime();
				responseCallbacks[callbackId] = responseCallback;
				message['callbackId'] = callbackId;
			}
			window.webkit.messageHandlers.WebViewJavascriptBridge.postMessage(message)
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
