/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to customize a UISearchBar.
*/

import UIKit

class CustomSearchBarViewController: UIViewController, UISearchBarDelegate {
    // MARK: - Properties

    @IBOutlet weak var searchBar: UISearchBar!

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureSearchBar()
    }

    // MARK: - Configuration
    
    func configureSearchBar() {
        searchBar.showsCancelButton = true
        searchBar.showsBookmarkButton = true

        searchBar.tintColor = UIColor.applicationPurpleColor

        searchBar.backgroundImage = UIImage(named: "search_bar_background")

        // Set the bookmark image for both normal and highlighted states.
        let bookmarkImage = UIImage(named: "bookmark_icon")
        searchBar.setImage(bookmarkImage, for: .bookmark, state: UIControlState())

        let bookmarkHighlightedImage = UIImage(named: "bookmark_icon_highlighted")
        searchBar.setImage(bookmarkHighlightedImage, for: .bookmark, state: .highlighted)
    }

    // MARK: - UISearchBarDelegate

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        NSLog("The custom search bar keyboard search button was tapped: \(searchBar).")
        
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        NSLog("The custom search bar cancel button was tapped.")

        searchBar.resignFirstResponder()
    }

    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        NSLog("The custom bookmark button inside the search bar was tapped.")
    }
}
