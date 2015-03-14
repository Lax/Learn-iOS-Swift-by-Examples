/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This controller handles displaying a custom or static notification.
 */

#import "AAPLNotificationController.h"

@implementation AAPLNotificationController

- (instancetype)init {
    self = [super init];

    if (self) {
        // Initialize variables here.
        // Configure interface objects here.
    }
    
    return self;
}

- (void)willActivate {
    // This method is called when the controller is about to be visible to the wearer.
    NSLog(@"%@ will activate", self);
}

- (void)didDeactivate {
    // This method is called when the controller is no longer visible.
    NSLog(@"%@ did deactivate", self);
}

/*
- (void)didReceiveLocalNotification:(UILocalNotification *)localNotification withCompletion:(void (^)(WKUserNotificationInterfaceType))completionHandler {
    // This method is called when a local notification needs to be presented.
    // Implement it if you use a dynamic glance interface.
    // Populate your dynamic glance inteface as quickly as possible.
    //
    // After populating your dynamic glance interface call the completion block.
    completionHandler(WKUserNotificationInterfaceTypeCustom);
}
*/

- (void)didReceiveRemoteNotification:(NSDictionary *)remoteNotification withCompletion:(void (^)(WKUserNotificationInterfaceType))completionHandler {
    // This method is called when a remote notification needs to be presented.
    // Implement it if you use a dynamic glance interface.
    // Populate your dynamic glance inteface as quickly as possible.
    //
    // After populating your dynamic glance interface call the completion block.
    completionHandler(WKUserNotificationInterfaceTypeCustom);
    
    // Use the following constant to display the static notification.
    //completionHandler(WKUserNotificationInterfaceTypeDefault);
}

@end



