/*
Copyright (C) 2017 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Base or common view controller to share a common UITableViewCell prototype between subclasses.
*/

import UIKit

class BaseTableViewController: UITableViewController {
    
    // MARK: - Types
    
    static let nibName = "TableCell"
    static let tableViewCellIdentifier = "cellID"
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let nib = UINib(nibName: BaseTableViewController.nibName, bundle: nil)
        
        // Required if our subclasses are to use `dequeueReusableCellWithIdentifier(_:forIndexPath:)`.
        tableView.register(nib, forCellReuseIdentifier: BaseTableViewController.tableViewCellIdentifier)
    }
    
    // MARK: - Configuration
    
    func configureCell(_ cell: UITableViewCell, forProduct product: Product) {
        cell.textLabel?.text = product.title
        
        /*
            Build the price and year string.
            Use NSNumberFormatter to get the currency format out of this NSNumber (product.introPrice).
        */
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.formatterBehavior = .default

        let priceString = numberFormatter.string(from: NSNumber(value: product.introPrice))

        cell.detailTextLabel?.text = "\(priceString!) | \(product.yearIntroduced)"
    }
}
