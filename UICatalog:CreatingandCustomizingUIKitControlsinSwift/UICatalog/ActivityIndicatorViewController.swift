/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A view controller that demonstrates how to use UIActivityIndicatorView.
            
*/

import UIKit

class ActivityIndicatorViewController: UITableViewController {
    // MARK: Properties

    @IBOutlet var grayStyleActivityIndicatorView: UIActivityIndicatorView
    @IBOutlet var tintedActivityIndicatorView: UIActivityIndicatorView
    
    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureGrayActivityIndicatorView()
        configureTintedActivityIndicatorView()
        
        // When activity is done, use UIActivityIndicatorView.stopAnimating().
    }
    
    // MARK: Configuration

    func configureGrayActivityIndicatorView() {
        grayStyleActivityIndicatorView.activityIndicatorViewStyle = .Gray
        
        grayStyleActivityIndicatorView.startAnimating()
        
        grayStyleActivityIndicatorView.hidesWhenStopped = true
    }
    
    func configureTintedActivityIndicatorView() {
        tintedActivityIndicatorView.activityIndicatorViewStyle = .Gray
        
        tintedActivityIndicatorView.color = UIColor.applicationPurpleColor()
        
        tintedActivityIndicatorView.startAnimating()
    }
}
