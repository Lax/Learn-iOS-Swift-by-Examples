/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to customize a UIToolbar.
*/

import UIKit

class TintedToolbarViewController: UIViewController {
    // MARK: - Properties
    
    @IBOutlet weak var toolbar: UIToolbar!

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureToolbar()
    }

    // MARK: - Configuration

    func configureToolbar() {
        // See the `UIBarStyle` enum for more styles, including `.Default`.
        toolbar.barStyle = .blackTranslucent

        toolbar.tintColor = UIColor.applicationGreenColor
        toolbar.backgroundColor = UIColor.applicationBlueColor

        let toolbarButtonItems = [
            refreshBarButtonItem,
            flexibleSpaceBarButtonItem,
            actionBarButtonItem
        ]

        toolbar.setItems(toolbarButtonItems, animated: true)
    }

    // MARK: - UIBarButtonItem Creation and Configuration

    var refreshBarButtonItem: UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(TintedToolbarViewController.barButtonItemClicked(_:)))
    }

    var flexibleSpaceBarButtonItem: UIBarButtonItem {
        // Note that there's no target/action since this represents empty space.
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    }

    var actionBarButtonItem: UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(TintedToolbarViewController.barButtonItemClicked(_:)))
    }

    // MARK: - Actions

    func barButtonItemClicked(_ barButtonItem: UIBarButtonItem) {
        NSLog("A bar button item on the tinted toolbar was clicked: \(barButtonItem).")
    }
}
