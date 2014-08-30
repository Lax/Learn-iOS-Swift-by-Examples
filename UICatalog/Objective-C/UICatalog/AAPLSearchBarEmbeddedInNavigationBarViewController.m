/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A view controller that demonstrates how to present a search controller's search bar within a navigation bar.
            
*/

#import "AAPLSearchBarEmbeddedInNavigationBarViewController.h"
#import "AAPLSearchResultsViewController.h"

@interface AAPLSearchBarEmbeddedInNavigationBarViewController ()

@property (nonatomic, strong) UISearchController *searchController;

@end

@implementation AAPLSearchBarEmbeddedInNavigationBarViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create the search results view controller and use it for the UISearchController.
    AAPLSearchResultsViewController *searchResultsController = [self.storyboard instantiateViewControllerWithIdentifier:AAPLSearchResultsViewControllerStoryboardIdentifier];
    
    // Create the search controller and make it perform the results updating.
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:searchResultsController];
    self.searchController.searchResultsUpdater = searchResultsController;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    
    // Configure the search controller's search bar. For more information on how to configure
    // search bars, see the "Search Bar" group under "Search".
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchController.searchBar.placeholder = NSLocalizedString(@"Search", nil);

    // Include the search bar within the navigation bar.
    self.navigationItem.titleView = self.searchController.searchBar;

    self.definesPresentationContext = YES;
}

@end
