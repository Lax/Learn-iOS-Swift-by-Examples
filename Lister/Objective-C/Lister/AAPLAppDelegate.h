/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The application delegate.
            
*/

@import UIKit;

/*!
 * The identifier for an empty view controller defined in the main storyboard.
 */
extern NSString *const AAPLAppDelegateMainStoryboardEmptyViewControllerIdentifier;

/*!
 * The identifier for a list view controller defined in the main storyboard.
 */
extern NSString *const AAPLAppDelegateMainStoryboardListViewControllerIdentifier;

/*!
 * The identifier for a list navigation view controller defined in the main storyboard.
 */
extern NSString *const AAPLAppDelegateMainStoryboardListNavigationViewControllerIdentifier;

/*!
 * The segue identifier for the transition between the \c ListDocumentsViewController and the 
 * \c NewListDocumentController.
 */
extern NSString *const AAPLAppDelegateMainStoryboardListDocumentsViewControllerToNewListDocumentControllerSegueIdentifier;

/*!
 * The segue identifier for the transition between the \c ListDocumentsViewController and the
 * \c ListViewController.
 */
extern NSString *const AAPLAppDelegateMainStoryboardListDocumentsViewControllerToListViewControllerSegueIdentifier;

/*!
 * The segue identifier for the transition between the \c ListDocumentsViewController and the
 * \c ListViewController initiated due to the resumption of a user activity.
 */
extern NSString *const AAPLAppDelegateMainStoryboardListDocumentsViewControllerContinueUserActivityToListViewControllerSegueIdentifier;

@interface AAPLAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;

@end
