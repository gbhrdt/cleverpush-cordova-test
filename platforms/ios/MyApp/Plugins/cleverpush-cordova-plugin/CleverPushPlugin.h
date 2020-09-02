#import <Foundation/Foundation.h>
#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>

@interface CleverPushPlugin : CDVPlugin {}

- (void)setNotificationOpenedHandler:(CDVInvokedUrlCommand*)command;
- (void)setNotificationReceivedHandler:(CDVInvokedUrlCommand*)command;
- (void)setSubscribedHandler:(CDVInvokedUrlCommand*)command;
- (void)init:(CDVInvokedUrlCommand*)command;

@end
