/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Umbrella header for the ListerKit framework.
*/

@import Foundation;

// Models
#import <ListerKit/AAPLList.h>
#import <ListerKit/AAPLListItem.h>


// Documents - UI/NSDocument architecture is unavailable on the watch platform.
#if !TARGET_OS_WATCH
#import <ListerKit/AAPLListDocument.h>
#endif

// Configuration
#import <ListerKit/AAPLAppConfiguration.h>

// List Presentation
#import <ListerKit/AAPLListPresenterDelegate.h>
#import <ListerKit/AAPLListPresenting.h>
#import <ListerKit/AAPLAllListItemsPresenter.h>
#import <ListerKit/AAPLIncompleteListItemsPresenter.h>

// UI
#import <ListerKit/AAPLListColor+UI.h>

// Custom View Drawing - CoreGraphics and other custom drawing APIs are not available on the watch platform.
#if !TARGET_OS_WATCH
#import <ListerKit/AAPLCheckBox.h>
#import <ListerKit/AAPLCheckBoxLayer.h>
#endif

#if TARGET_OS_IOS || TARGET_OS_WATCH
#import <ListerKit/AAPLListInfo.h>
#import <ListerKit/AAPLListUtilities.h>
#endif

#if TARGET_OS_IOS
#import <ListerKit/AAPLListCoordinator.h>
#import <ListerKit/AAPLLocalListCoordinator.h>
#import <ListerKit/AAPLCloudListCoordinator.h>
#import <ListerKit/AAPLListsController.h>
#endif

#if TARGET_OS_WATCH
#import <ListerKit/AAPLConnectivityListsController.h>
#endif

#if TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IOS || TARGET_OS_WATCH)
#import <ListerKit/AAPLListFormatting.h>
#import <ListerKit/AAPLTodayListManager.h>
#endif
