/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Defines the row controllers used in the `ListInterfaceController` class.
*/

import WatchKit

/// An empty row controller that is displayed when there are no list items in a list.
class NoItemsRowController: NSObject {}

/**
    A row controller that represents a `ListItem` object. The `ListItemRowController` is used by the
    `ListInterfaceController`.
*/
class ListItemRowController: NSObject {
    // MARK: Properties
    
    @IBOutlet weak var textLabel: WKInterfaceLabel!
    
    @IBOutlet weak var checkBox: WKInterfaceImage!
    
    // MARK: Methods

    func setText(text: String) {
        textLabel.setText(text)
    }
    
    func setTextColor(color: UIColor) {
        textLabel.setTextColor(color)
    }
    
    func setCheckBoxImageNamed(imageName: String) {
        checkBox.setImageNamed(imageName)
    }
}
