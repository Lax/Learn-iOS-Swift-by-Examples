/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

@import CloudKit;
#import "AAPLAppDelegate.h"
#import "AAPLTableViewController.h"

@interface AAPLAppDelegate ()
@end

@implementation AAPLAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert categories:nil];
    [application registerUserNotificationSettings:notificationSettings];
    [application registerForRemoteNotifications];
    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if(self.tableController)
    {
        // Sends the ID of the record save that triggered the push to the tableViewController
        CKQueryNotification *recordInfo = [CKQueryNotification notificationFromRemoteNotificationDictionary:userInfo];
        [self.tableController loadNewPostsWithRecordID:recordInfo.recordID];
    }
}

@end
