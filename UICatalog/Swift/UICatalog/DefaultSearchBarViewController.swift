/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A view controller that demonstrates how to use a default UISearchBar.
            
*/

import UIKit

class DefaultSearchBarViewController: UIViewController, UISearchBarDelegate {
    // MARK: Properties

    @IBOutlet weak var searchBar: UISearchBar!

    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureSearchBar()
    }

    // MARK: Configuration
    
    func configureSearchBar() {
        searchBar.showsCancelButton = true
        searchBar.showsScopeBar = true

        searchBar.scopeButtonTitles = [
            NSLocalizedString("Scope One", comment: ""),
            NSLocalizedString("Scope Two", comment: "")
        ]
    }

    // MARK: UISearchBarDelegate

    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        NSLog("The default search selected scope button index changed to \(selectedScope).")
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        NSLog("The default search bar keyboard search button was tapped: \(searchBar.text).")

        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        NSLog("The default search bar cancel button was tapped.")

        searchBar.resignFirstResponder()
    }
}
