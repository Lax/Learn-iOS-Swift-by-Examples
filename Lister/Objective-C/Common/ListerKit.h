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

// Documents
#import <ListerKit/AAPLListDocument.h>

// Configuration
#import <ListerKit/AAPLAppConfiguration.h>

// List Presentation
#import <ListerKit/AAPLListPresenterDelegate.h>
#import <ListerKit/AAPLListPresenting.h>
#import <ListerKit/AAPLAllListItemsPresenter.h>
#import <ListerKit/AAPLIncompleteListItemsPresenter.h>

// UI
#import <ListerKit/AAPLListColor+UI.h>
#import <ListerKit/AAPLCheckBox.h>
#import <ListerKit/AAPLCheckBoxLayer.h>

#if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
#import <ListerKit/AAPLListFormatting.h>
#import <ListerKit/AAPLTodayListManager.h>
#endif

#if TARGET_OS_IPHONE
#import <ListerKit/AAPLListInfo.h>
#import <ListerKit/AAPLListCoordinator.h>
#import <ListerKit/AAPLLocalListCoordinator.h>
#import <ListerKit/AAPLCloudListCoordinator.h>
#import <ListerKit/AAPLListsController.h>
#import <ListerKit/AAPLListUtilities.h>
#endif