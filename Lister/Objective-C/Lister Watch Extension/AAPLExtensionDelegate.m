/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLExtensionDelegate that manages app level behavior for the WatchKit extension.
*/

#import "AAPLExtensionDelegate.h"
#import "AAPLListsInterfaceController.h"
#import "AAPLWatchStoryboardConstants.h"

@implementation AAPLExtensionDelegate

#pragma mark - WKExtensionDelegate

- (void)handleUserActivity:(NSDictionary *)userInfo {
    [self.mainInterfaceController handleUserActivity:userInfo];
}

@end
