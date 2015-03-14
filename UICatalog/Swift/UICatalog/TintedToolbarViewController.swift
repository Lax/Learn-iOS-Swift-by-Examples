/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to customize a UIToolbar.
*/

import UIKit

class TintedToolbarViewController: UIViewController {
    // MARK: Properties
    
    @IBOutlet weak var toolbar: UIToolbar!

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureToolbar()
    }

    // MARK: Configuration

    func configureToolbar() {
        // See the UIBarStyle enum for more styles, including UIBarStyle.Default.
        toolbar.barStyle = .BlackTranslucent

        toolbar.tintColor = UIColor.applicationGreenColor()
        toolbar.backgroundColor = UIColor.applicationBlueColor()

        let toolbarButtonItems = [
            refreshBarButtonItem,
            flexibleSpaceBarButtonItem,
            actionBarButtonItem
        ]
        toolbar.setItems(toolbarButtonItems, animated: true)
    }

    // MARK: UIBarButtonItem Creation and Configuration

    var refreshBarButtonItem: UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "barButtonItemClicked:")
    }

    var flexibleSpaceBarButtonItem: UIBarButtonItem {
        // Note that there's no target/action since this represents empty space.
        return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
    }

    var actionBarButtonItem: UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "barButtonItemClicked:")
    }

    // MARK: Actions

    func barButtonItemClicked(barButtonItem: UIBarButtonItem) {
        NSLog("A bar button item on the tinted toolbar was clicked: \(barButtonItem).")
    }
}
