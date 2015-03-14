/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLListDocumentsViewController displays a list of available documents for users to open.
*/

@import UIKit;
@import ListerKit;

@class AAPLAppLaunchContext;

@interface AAPLListDocumentsViewController : UITableViewController

@property (nonatomic, strong) AAPLListsController *listsController;

- (void)configureViewControllerWithLaunchContext:(AAPLAppLaunchContext *)launchContext;

@end
