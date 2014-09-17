/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A view controller that demonstrates how to present a search controller over a navigation bar.
            
*/

import UIKit

class SearchPresentOverNavigationBarViewController: SearchControllerBaseViewController {
    // MARK: Properties
    
    // `searchController` is set when the search button is clicked.
    var searchController: UISearchController!

    // MARK: Actions
    
    @IBAction func searchButtonClicked(button: UIBarButtonItem) {
        // Create the search results view controller and use it for the UISearchController.
        let searchResultsController = storyboard!.instantiateViewControllerWithIdentifier(SearchResultsViewController.StoryboardConstants.identifier) as SearchResultsViewController

        // Create the search controller and make it perform the results updating.
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.searchResultsUpdater = searchResultsController
        searchController.hidesNavigationBarDuringPresentation = false

        // Present the view controller.
        presentViewController(searchController, animated: true, completion: nil)
    }
}
