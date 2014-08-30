/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A view controller that demonstrates how to show search results from a search controller within the source view controller (in this case, in the table view's header view).
            
*/

import UIKit

class SearchShowResultsInSourceViewController: SearchResultsViewController {
    // MARK: Properties
    
    // `searchController` is set in viewDidLoad(_:).
    var searchController: UISearchController!

    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create the search controller, but we'll make sure that this SearchShowResultsInSourceViewController
        // performs the results updating.
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        
        // Make sure the that the search bar is visible within the navigation bar.
        searchController.searchBar.sizeToFit()
        
        // Include the search controller's search bar within the table's header view.
        tableView.tableHeaderView = searchController.searchBar

        definesPresentationContext = true
    }
}
