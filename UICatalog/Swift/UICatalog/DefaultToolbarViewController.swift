/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A view controller that demonstrates how to use a default UIToolbar.
            
*/

import UIKit

class DefaultToolbarViewController: UIViewController {
    // MARK: Properties

    @IBOutlet weak var toolbar: UIToolbar!

    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureToolbar()
    }

    // MARK: Configuration

    func configureToolbar() {
        let toolbarButtonItems = [
            trashBarButtonItem,
            flexibleSpaceBarButtonItem,
            customTitleBarButtonItem
        ]
        toolbar.setItems(toolbarButtonItems, animated: true)
    }

    // MARK: UIBarButtonItem Creation and Configuration

    var trashBarButtonItem: UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: "barButtonItemClicked:")
    }

    var flexibleSpaceBarButtonItem: UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
    }

    var customTitleBarButtonItem: UIBarButtonItem {
        let customTitle = NSLocalizedString("Action", comment: "")

        return UIBarButtonItem(title: customTitle, style: .Plain, target: self, action: "barButtonItemClicked:")
    }

    // MARK: Actions

    func barButtonItemClicked(barButtonItem: UIBarButtonItem) {
        NSLog("A bar button item on the default toolbar was clicked: \(barButtonItem).")
    }
}
