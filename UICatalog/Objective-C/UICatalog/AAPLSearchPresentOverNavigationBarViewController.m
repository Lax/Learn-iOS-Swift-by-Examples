/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to present a search controller over a navigation bar.
*/

#import "AAPLSearchPresentOverNavigationBarViewController.h"
#import "AAPLSearchResultsViewController.h"

@interface AAPLSearchPresentOverNavigationBarViewController ()

@property (nonatomic, strong) UISearchController *searchController;

@end

@implementation AAPLSearchPresentOverNavigationBarViewController

#pragma mark - View Life Cycle

- (IBAction)searchButtonClicked:(UIBarButtonItem *)sender {
    // Create the search results view controller and use it for the UISearchController.
    AAPLSearchResultsViewController *searchResultsController = [self.storyboard instantiateViewControllerWithIdentifier:AAPLSearchResultsViewControllerStoryboardIdentifier];
    
    // Create the search controller and make it perform the results updating.
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:searchResultsController];
    self.searchController.searchResultsUpdater = searchResultsController;
    self.searchController.hidesNavigationBarDuringPresentation = NO;

    // Present the view controller.
    [self presentViewController:self.searchController animated:YES completion:nil];
}

@end
