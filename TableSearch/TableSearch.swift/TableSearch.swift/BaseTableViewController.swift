/*
Copyright (C) 2014 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:

Base or common view controller to share a common UITableViewCell prototype between subclasses.

*/

import UIKit

class BaseTableViewController: UITableViewController {
    // MARK: Types
    
    struct Constants {
        struct Nib {
            static let name = "TableCell"
        }
        
        struct TableViewCell {
            static let identifier = "cellID"
        }
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let nib = UINib(nibName: Constants.Nib.name, bundle: nil)
        
        // Required if our subclasses are to use: dequeueReusableCellWithIdentifier:forIndexPath:
        tableView.registerNib(nib, forCellReuseIdentifier: Constants.TableViewCell.identifier)
    }
    
    // MARK:
    
    func configureCell(cell: UITableViewCell, forProduct product: Product) {
        cell.textLabel?.text = product.title
        
        // Build the price and year string.
        //
        // use NSNumberFormatter to get the currency format out of this NSNumber (product.introPrice)
        let numberFormatter = NSNumberFormatter()
        numberFormatter.numberStyle = .CurrencyStyle
        numberFormatter.formatterBehavior = .BehaviorDefault

        let priceString = numberFormatter.stringFromNumber(product.introPrice)

        cell.detailTextLabel?.text = "\(priceString!) | \(product.yearIntroduced)"
    }
}