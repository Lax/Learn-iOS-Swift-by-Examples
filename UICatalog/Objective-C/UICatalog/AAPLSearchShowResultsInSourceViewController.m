/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A view controller that demonstrates how to show search results from a search controller within the source view controller (in this case, in the table view's header view).
            
*/

#import "AAPLSearchShowResultsInSourceViewController.h"

@interface AAPLSearchShowResultsInSourceViewController ()

@property (nonatomic, strong) UISearchController *searchController;

@end

@implementation AAPLSearchShowResultsInSourceViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create the search controller, but we'll make sure that this AAPLSearchShowResultsInSourceViewController
    // performs the results updating.
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;

    // Make sure the that the search bar is visible within the navigation bar.
    [self.searchController.searchBar sizeToFit];
    
    // Include the search controller's search bar within the table's header view.
    self.tableView.tableHeaderView = self.searchController.searchBar;
    
    self.definesPresentationContext = YES;
}

@end
