/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The application delegate which creates the window and root view controller.
 */

#import "AAPLAppDelegate.h"

@implementation AAPLAppDelegate

- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void(^)(NSDictionary *replyInfo))reply{
    // Receives text input result from the WatchKit app extension.
    NSLog(@"User Info: %@", userInfo);
    
    // Sends a confirmation message to the WatchKit app extension that the text input result was received.
    reply(@{@"Confirmation" : @"Text was received."});
}

@end
