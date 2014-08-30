/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A table view controller that displays filtered strings based on callbacks from a UISearchController.
            
*/

#import "AAPLSearchResultsViewController.h"

NSString *const AAPLSearchResultsViewControllerStoryboardIdentifier = @"AAPLSearchResultsViewControllerStoryboardIdentifier";

@implementation AAPLSearchResultsViewController

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    // -updateSearchResultsForSearchController: is called when the controller is being dismissed to allow those who are using the controller they are search as the results controller a chance to reset their state. No need to update anything if we're being dismissed.
    if (!searchController.active) {
        return;
    }

    self.filterString = searchController.searchBar.text;
}

@end