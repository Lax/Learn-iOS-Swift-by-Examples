/*
Copyright (C) 2017 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The application's primary table view controller showing a list of products.
*/

import UIKit

class MainTableViewController: BaseTableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    // MARK: - Types
    
    /// State restoration values.
    enum RestorationKeys: String {
        case viewControllerTitle
        case searchControllerIsActive
        case searchBarText
        case searchBarIsFirstResponder
    }

    struct SearchControllerRestorableState {
        var wasActive = false
        var wasFirstResponder = false
    }
    
    // MARK: - Properties
    
    /// Data model for the table view.
    var products = [Product]()
    
    /** The following 2 properties are set in viewDidLoad(),
        They are implicitly unwrapped optionals because they are used in many other places
		throughout this view controller.
    */
    
    /// Search controller to help us with filtering.
    var searchController: UISearchController!
    
    /// Secondary search results table view.
    var resultsTableController: ResultsTableController!
    
    /// Restoration state for UISearchController
    var restoredState = SearchControllerRestorableState()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultsTableController = ResultsTableController()
        
        /** We want ourselves to be the delegate for this filtered table so
			didSelectRowAtIndexPath(_:) is called for both tables.
		*/
        resultsTableController.tableView.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.sizeToFit()
		
		if #available(iOS 11.0, *) {
			// For iOS 11 and later, we place the search bar in the navigation bar.
			navigationController?.navigationBar.prefersLargeTitles = true

			navigationItem.searchController = searchController
			
			// We want the search bar visible all the time.
			navigationItem.hidesSearchBarWhenScrolling = false
		} else {
			// For iOS 10 and earlier, we place the search bar in the table view's header.
			tableView.tableHeaderView = searchController.searchBar
		}
		
        searchController.delegate = self
        searchController.dimsBackgroundDuringPresentation = false // default is YES
        searchController.searchBar.delegate = self    // so we can monitor text changes + others
        
        /** Search is now just presenting a view controller. As such, normal view controller
            presentation semantics apply. Namely that presentation will walk up the view controller
            hierarchy until it finds the root view controller or one that defines a presentation context.
        */
        definesPresentationContext = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Restore the searchController's active state.
        if restoredState.wasActive {
            searchController.isActive = restoredState.wasActive
            restoredState.wasActive = false
            
            if restoredState.wasFirstResponder {
                searchController.searchBar.becomeFirstResponder()
                restoredState.wasFirstResponder = false
            }
        }
    }
	
}

// MARK: - UITableViewDataSource

extension MainTableViewController {
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return products.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: BaseTableViewController.tableViewCellIdentifier, for: indexPath)
		
		let product = products[indexPath.row]
		configureCell(cell, forProduct: product)
		
		return cell
	}
	
}

// MARK: - UITableViewDelegate

extension MainTableViewController {
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let selectedProduct: Product
		
		// Check to see which table view cell was selected.
		if tableView === self.tableView {
			selectedProduct = products[indexPath.row]
		} else {
			selectedProduct = resultsTableController.filteredProducts[indexPath.row]
		}
		
		// Set up the detail view controller to show.
		let detailViewController = DetailViewController.detailViewControllerForProduct(selectedProduct)
		
		navigationController?.pushViewController(detailViewController, animated: true)
	}
	
}

// MARK: - UISearchBarDelegate

extension MainTableViewController {
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}
	
}

// MARK: - UISearchControllerDelegate

extension MainTableViewController {
	func presentSearchController(_ searchController: UISearchController) {
		//debugPrint("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
	}
	
	func willPresentSearchController(_ searchController: UISearchController) {
		//debugPrint("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
	}
	
	func didPresentSearchController(_ searchController: UISearchController) {
		//debugPrint("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
	}
	
	func willDismissSearchController(_ searchController: UISearchController) {
		//debugPrint("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
	}
	
	func didDismissSearchController(_ searchController: UISearchController) {
		//debugPrint("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
	}
	
}

// MARK: - UISearchResultsUpdating

extension MainTableViewController {
	func updateSearchResults(for searchController: UISearchController) {
		// Update the filtered array based on the search text.
		let searchResults = products
		
		// Strip out all the leading and trailing spaces.
		let whitespaceCharacterSet = CharacterSet.whitespaces
		let strippedString = searchController.searchBar.text!.trimmingCharacters(in: whitespaceCharacterSet)
		let searchItems = strippedString.components(separatedBy: " ") as [String]
		
		// Build all the "AND" expressions for each value in the searchString.
		let andMatchPredicates: [NSPredicate] = searchItems.map { searchString in
			/** Each searchString creates an OR predicate for: name, yearIntroduced, introPrice.
			Example if searchItems contains "iphone 599 2007":
			name CONTAINS[c] "iphone"
			name CONTAINS[c] "599", yearIntroduced ==[c] 599, introPrice ==[c] 599
			name CONTAINS[c] "2007", yearIntroduced ==[c] 2007, introPrice ==[c] 2007
			*/
			var searchItemsPredicate = [NSPredicate]()
			
			// Below we use NSExpression represent expressions in our predicates.
			// NSPredicate is made up of smaller, atomic parts: two NSExpressions (a left-hand value and a right-hand value).
			
			// Name field matching.
			let titleExpression = NSExpression(forKeyPath: "title")
			let searchStringExpression = NSExpression(forConstantValue: searchString)
			
			let titleSearchComparisonPredicate =
				NSComparisonPredicate(leftExpression: titleExpression,
				                      rightExpression: searchStringExpression,
				                      modifier: .direct,
				                      type: .contains,
				                      options: .caseInsensitive)
			
			searchItemsPredicate.append(titleSearchComparisonPredicate)
			
			let numberFormatter = NumberFormatter()
			numberFormatter.numberStyle = .none
			numberFormatter.formatterBehavior = .default
			
			let targetNumber = numberFormatter.number(from: searchString)
			
			// `searchString` may fail to convert to a number.
			if targetNumber != nil {
				// Use `targetNumberExpression` in both the following predicates.
				let targetNumberExpression = NSExpression(forConstantValue: targetNumber!)
				
				// `yearIntroduced` field matching.
				let yearIntroducedExpression = NSExpression(forKeyPath: "yearIntroduced")
				let yearIntroducedPredicate =
					NSComparisonPredicate(leftExpression: yearIntroducedExpression,
					                      rightExpression: targetNumberExpression,
					                      modifier: .direct,
					                      type: .equalTo,
					                      options: .caseInsensitive)
				
				searchItemsPredicate.append(yearIntroducedPredicate)
				
				// `price` field matching.
				let lhs = NSExpression(forKeyPath: "introPrice")
				
				let finalPredicate =
					NSComparisonPredicate(leftExpression: lhs,
					                      rightExpression: targetNumberExpression,
					                      modifier: .direct,
					                      type: .equalTo,
					                      options: .caseInsensitive)
				
				searchItemsPredicate.append(finalPredicate)
			}
			
			// Add this OR predicate to our master AND predicate.
			let orMatchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates:searchItemsPredicate)
			
			return orMatchPredicate
		}
		
		// Match up the fields of the Product object.
		let finalCompoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: andMatchPredicates)
		
		let filteredResults = searchResults.filter { finalCompoundPredicate.evaluate(with: $0) }
		
		// Hand over the filtered results to our search results table.
		if let resultsController = searchController.searchResultsController as? ResultsTableController {
			resultsController.filteredProducts = filteredResults
			resultsController.tableView.reloadData()
		}
	}
	
}

// MARK: - UIStateRestoration

extension MainTableViewController {
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		
		// Encode the view state so it can be restored later.
		
		// Encode the title.
		coder.encode(navigationItem.title!, forKey:RestorationKeys.viewControllerTitle.rawValue)
		
		// Encode the search controller's active state.
		coder.encode(searchController.isActive, forKey:RestorationKeys.searchControllerIsActive.rawValue)
		
		// Encode the first responser status.
		coder.encode(searchController.searchBar.isFirstResponder, forKey:RestorationKeys.searchBarIsFirstResponder.rawValue)
		
		// Encode the search bar text.
		coder.encode(searchController.searchBar.text, forKey:RestorationKeys.searchBarText.rawValue)
	}
	
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		
		// Restore the title.
		guard let decodedTitle = coder.decodeObject(forKey: RestorationKeys.viewControllerTitle.rawValue) as? String else {
			fatalError("A title did not exist. In your app, handle this gracefully.")
		}
		title = decodedTitle
		
		/** Restore the active state:
		We can't make the searchController active here since it's not part of the view
		hierarchy yet, instead we do it in viewWillAppear.
		*/
		restoredState.wasActive = coder.decodeBool(forKey: RestorationKeys.searchControllerIsActive.rawValue)
		
		/** Restore the first responder status:
		Like above, we can't make the searchController first responder here since it's not part of the view
		hierarchy yet, instead we do it in viewWillAppear.
		*/
		restoredState.wasFirstResponder = coder.decodeBool(forKey: RestorationKeys.searchBarIsFirstResponder.rawValue)
		
		// Restore the text in the search field.
		searchController.searchBar.text = coder.decodeObject(forKey: RestorationKeys.searchBarText.rawValue) as? String
	}
	
}
