/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to customize a UIToolbar.
*/

import UIKit

class CustomToolbarViewController: UIViewController {
    // MARK: - Properties

    @IBOutlet weak var toolbar: UIToolbar!

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureToolbar()
    }

    // MARK: - Configuration
    
    func configureToolbar() {
        let toolbarBackgroundImage = UIImage(named: "toolbar_background")
        toolbar.setBackgroundImage(toolbarBackgroundImage, forToolbarPosition: .bottom, barMetrics: .default)

        let toolbarButtonItems = [
            customImageBarButtonItem,
            flexibleSpaceBarButtonItem,
            customBarButtonItem
        ]

        toolbar.setItems(toolbarButtonItems, animated: true)
    }

    // MARK: - UIBarButtonItem Creation and Configuration

    var customImageBarButtonItem: UIBarButtonItem {
        let customBarButtonItemImage = UIImage(named: "tools_icon")

        let customImageBarButtonItem = UIBarButtonItem(image: customBarButtonItemImage, style: .plain, target: self, action: #selector(CustomToolbarViewController.barButtonItemClicked(_:)))

        customImageBarButtonItem.tintColor = UIColor.applicationPurpleColor

        return customImageBarButtonItem
    }

    var flexibleSpaceBarButtonItem: UIBarButtonItem {
        // Note that there's no target/action since this represents empty space.
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    }

    var customBarButtonItem: UIBarButtonItem {
        let barButtonItem = UIBarButtonItem(title: NSLocalizedString("Button", comment: ""), style: .plain, target: self, action: #selector(CustomToolbarViewController.barButtonItemClicked(_:)))

        let backgroundImage = UIImage(named: "WhiteButton")
        barButtonItem.setBackgroundImage(backgroundImage, for: UIControlState(), barMetrics: .default)

        let attributes = [
            NSForegroundColorAttributeName: UIColor.applicationPurpleColor
        ]
        barButtonItem.setTitleTextAttributes(attributes, for: UIControlState())

        return barButtonItem
    }

    // MARK: - Actions
    
    func barButtonItemClicked(_ barButtonItem: UIBarButtonItem) {
        NSLog("A bar button item on the custom toolbar was clicked: \(barButtonItem).")
    }
}
