/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller that demonstrates how to use a default UISearchBar.
*/

#import "AAPLDefaultSearchBarViewController.h"

@interface AAPLDefaultSearchBarViewController()<UISearchBarDelegate>

@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;

@end


#pragma mark -

@implementation AAPLDefaultSearchBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureSearchBar];
}


#pragma mark - Configuration

- (void)configureSearchBar {
    self.searchBar.showsCancelButton = YES;
    self.searchBar.showsScopeBar = YES;

    self.searchBar.scopeButtonTitles = @[
        NSLocalizedString(@"Scope One", nil),
        NSLocalizedString(@"Scope Two", nil)
    ];
}


#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    NSLog(@"The default search selected scope button index changed to %ld.", (long)selectedScope);
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSLog(@"The default search bar keyboard search button was tapped: %@.", searchBar.text);
    
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    NSLog(@"The default search bar cancel button was tapped.");
    
    [searchBar resignFirstResponder];
}

@end
