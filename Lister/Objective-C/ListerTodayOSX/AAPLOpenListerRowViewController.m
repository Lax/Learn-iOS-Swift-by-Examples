/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLOpenListerRowViewController class is an \c NSViewController subclass that provides a row in the \c NCWidgetListViewController to allow the user to open the Today document in Lister.
*/

#import "AAPLOpenListerRowViewController.h"
@import ListerKit;

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
