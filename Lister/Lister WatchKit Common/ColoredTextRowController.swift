/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ColoredTextRowController` class defines a simple interface that the `ListsInterfaceController` uses to represent a `List` object in the table.
*/

import WatchKit

/**
    A lightweight controller object that is responsible for displaying the content in a group within the
    `ListsInterfaceController` controller's `WKInterfaceTable` property.
*/
class ColoredTextRowController: NSObject {
    // MARK: Properties
    
    @IBOutlet weak var listColorGroup: WKInterfaceGroup!

    @IBOutlet weak var textLabel: WKInterfaceLabel!
    
    // MARK: Methods
    
    func setText(text: String) {
        textLabel.setText(text)
    }
    
    func setColor(color: UIColor) {
        listColorGroup.setBackgroundColor(color)
    }
}
