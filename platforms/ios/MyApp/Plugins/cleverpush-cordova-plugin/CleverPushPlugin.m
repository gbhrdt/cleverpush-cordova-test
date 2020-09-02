#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "CleverPushPlugin.h"
#import <CleverPush/CleverPush.h>

NSString* notificationReceivedCallbackId;
NSString* notificationOpenedCallbackId;
NSString* subscribedCallbackId;

CPNotificationOpenedResult* notificationOpenedResult;
NSString* pendingSubscribedResult;

id <CDVCommandDelegate> pluginCommandDelegate;

void successCallback(NSString* callbackId, NSDictionary* data) {
    CDVPluginResult* commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
    commandResult.keepCallback = @1;
    [pluginCommandDelegate sendPluginResult:commandResult callbackId:callbackId];
}

void subscriptionCallback(NSString* callbackId, NSString* data) {
    CDVPluginResult* commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:data];
    commandResult.keepCallback = @1;
    [pluginCommandDelegate sendPluginResult:commandResult callbackId:callbackId];
}

void failureCallback(NSString* callbackId, NSDictionary* data) {
    CDVPluginResult* commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:data];
    commandResult.keepCallback = @1;
    [pluginCommandDelegate sendPluginResult:commandResult callbackId:callbackId];
}

NSString* stringifyNotificationOpenedResult(CPNotificationOpenedResult* result) {
    NSMutableDictionary* obj = [NSMutableDictionary new];
    [obj setObject:result.notification forKeyedSubscript:@"notification"];
    [obj setObject:result.subscription forKeyedSubscript:@"subscription"];
    [obj setObject:result.action forKeyedSubscript:@"action"];

    NSError * err;
    NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:obj options:0 error:&err];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

NSString* stringifyNotificationReceivedResult(CPNotificationReceivedResult* result) {
    NSMutableDictionary* obj = [NSMutableDictionary new];
    [obj setObject:result.notification forKeyedSubscript:@"notification"];
    [obj setObject:result.subscription forKeyedSubscript:@"subscription"];

    NSError * err;
    NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:obj options:0 error:&err];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

void processNotificationReceived(CPNotificationReceivedResult* result) {
    NSString* data = stringifyNotificationReceivedResult(result);
    NSError *jsonError;
    NSData *objectData = [data dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&jsonError];
    if (!jsonError) {
        successCallback(notificationReceivedCallbackId, json);
    }
}

void processNotificationOpened(CPNotificationOpenedResult* result) {
    NSString* data = stringifyNotificationOpenedResult(result);
    NSError *jsonError;
    NSData *objectData = [data dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&jsonError];
    if (!jsonError) {
        successCallback(notificationOpenedCallbackId, json);
        notificationOpenedResult = nil;
    }
}

void initCleverPushObject(NSDictionary* launchOptions, const char* channelId) {
    NSString* channelIdStr = (channelId ? [NSString stringWithUTF8String:channelId] : nil);

    [CleverPush
        initWithLaunchOptions:launchOptions
        channelId:channelIdStr
        handleNotificationReceived:^(CPNotificationReceivedResult* receivedResult) {
            if (pluginCommandDelegate && notificationReceivedCallbackId != nil) {
                processNotificationReceived(receivedResult);
            }
        }
        handleNotificationOpened:^(CPNotificationOpenedResult* openResult) {
            notificationOpenedResult = openResult;
            if (pluginCommandDelegate && notificationOpenedCallbackId != nil) {
                processNotificationOpened(openResult);
            }
        }
        handleSubscribed:^(NSString *subscriptionId) {
            if (pluginCommandDelegate && subscribedCallbackId != nil) {
                subscriptionCallback(subscribedCallbackId, subscriptionId);
            } else {
                pendingSubscribedResult = subscriptionId;
            }
        }
    ];
}


@implementation UIApplication(CleverPushCordovaPush)
    static void injectSelector(Class newClass, SEL newSel, Class addToClass, SEL makeLikeSel) {
        Method newMeth = class_getInstanceMethod(newClass, newSel);
        IMP imp = method_getImplementation(newMeth);
        const char* methodTypeEncoding = method_getTypeEncoding(newMeth);

        BOOL successful = class_addMethod(addToClass, makeLikeSel, imp, methodTypeEncoding);
        if (!successful) {
            class_addMethod(addToClass, newSel, imp, methodTypeEncoding);
            newMeth = class_getInstanceMethod(addToClass, newSel);

            Method orgMeth = class_getInstanceMethod(addToClass, makeLikeSel);

            method_exchangeImplementations(orgMeth, newMeth);
        }
    }

+ (void)load {
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(setDelegate:)), class_getInstanceMethod(self, @selector(setCleverPushCordovaDelegate:)));
}

static Class delegateClass = nil;

- (void) setCleverPushCordovaDelegate:(id<UIApplicationDelegate>)delegate {
    if(delegateClass != nil)
    return;
    delegateClass = [delegate class];

    injectSelector(self.class, @selector(cleverPushApplication:didFinishLaunchingWithOptions:),
                   delegateClass, @selector(application:didFinishLaunchingWithOptions:));
    [self setCleverPushCordovaDelegate:delegate];
}

- (BOOL)cleverPushApplication:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    initCleverPushObject(launchOptions, nil);

    if ([self respondsToSelector:@selector(cleverPushApplication:didFinishLaunchingWithOptions:)]) {
        return [self cleverPushApplication:application didFinishLaunchingWithOptions:launchOptions];
    }
    return YES;
}

@end


@implementation CleverPushPlugin

- (void)setNotificationReceivedHandler:(CDVInvokedUrlCommand*)command {
    notificationReceivedCallbackId = command.callbackId;
}

- (void)setNotificationOpenedHandler:(CDVInvokedUrlCommand*)command {
    notificationOpenedCallbackId = command.callbackId;
}

- (void)setSubscribedHandler:(CDVInvokedUrlCommand*)command {
    subscribedCallbackId = command.callbackId;
}

- (void)init:(CDVInvokedUrlCommand*)command {
    pluginCommandDelegate = self.commandDelegate;

    NSString* channelId = (NSString*)command.arguments[0];

    initCleverPushObject(nil, [channelId UTF8String]);
    
    if (pendingSubscribedResult) {
        subscriptionCallback(subscribedCallbackId, pendingSubscribedResult);
        pendingSubscribedResult = nil;
    }
    
    if (notificationOpenedResult) {
        processNotificationOpened(notificationOpenedResult);
    }
}

@end
