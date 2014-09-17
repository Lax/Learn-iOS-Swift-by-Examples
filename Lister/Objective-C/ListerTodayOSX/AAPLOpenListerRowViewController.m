/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                 The AAPLOpenListerRowViewController class is an NSViewController subclass that provides a row in the NCWidgetListViewController to allow the user to open the Today document in Lister.
              
*/

#import "AAPLOpenListerRowViewController.h"
@import ListerKitOSX;

@implementation AAPLOpenListerRowViewController

#pragma mark - IBActions

- (IBAction)openInLister:(NSButton *)sender {
    [[AAPLTodayListManager sharedTodayListManager] fetchTodayDocumentURLWithCompletionHandler:^(NSURL *todayDocumentURL) {
        if (todayDocumentURL) {
            [[NSWorkspace sharedWorkspace] openURLs:@[todayDocumentURL] withAppBundleIdentifier:AAPLAppConfigurationListerOSXBundleIdentifier options:NSWorkspaceLaunchAsync additionalEventParamDescriptor:NULL launchIdentifiers:NULL];
        }
    }];
}

@end
