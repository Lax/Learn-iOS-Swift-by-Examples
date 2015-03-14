/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A table view controller that displays filtered strings based on callbacks from a UISearchController.
*/

#import "AAPLSearchControllerBaseViewController.h"

/// The identifier string that corresponds to the AAPLSearchResultsViewController's view controller defined in the main storyboard.
extern NSString *const AAPLSearchResultsViewControllerStoryboardIdentifier;

@interface AAPLSearchResultsViewController : AAPLSearchControllerBaseViewController <UISearchResultsUpdating>
@end
