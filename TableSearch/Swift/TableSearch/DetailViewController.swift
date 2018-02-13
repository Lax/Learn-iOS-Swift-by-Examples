/*
Copyright (C) 2017 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The detail view controller navigated to from our main and results table.
*/

import UIKit

class DetailViewController: UIViewController {
    
    // MARK: - Types

    // Constants for Storyboard/ViewControllers.
    static let storyboardName = "MainStoryboard"
    static let viewControllerIdentifier = "DetailViewController"
    
    // Constants for state restoration.
    static let restoreProduct = "restoreProductKey"
    
    // MARK: - Properties
    
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    var product: Product!
    
    // MARK: - Initialization
    
    class func detailViewControllerForProduct(_ product: Product) -> DetailViewController {
        let storyboard = UIStoryboard(name: DetailViewController.storyboardName, bundle: nil)

        let viewController =
			storyboard.instantiateViewController(withIdentifier: DetailViewController.viewControllerIdentifier) as! DetailViewController
        
        viewController.product = product
        
        return viewController
    }
    
    // MARK: - View Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        title = product.title
        
        yearLabel.text = "\(product.yearIntroduced)"
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.formatterBehavior = .default
        let priceString = numberFormatter.string(from: NSNumber(value: product.introPrice))
        priceLabel.text = priceString
    }
	
}

// MARK: - UIStateRestoration

extension DetailViewController {
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		
		// Encode the product.
		coder.encode(product, forKey: DetailViewController.restoreProduct)
	}
	
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		
		// Restore the product.
		if let decodedProduct = coder.decodeObject(forKey: DetailViewController.restoreProduct) as? Product {
			product = decodedProduct
		} else {
			fatalError("A product did not exist. In your app, handle this gracefully.")
		}
	}
	
}
