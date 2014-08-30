/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Provides an abstraction suitable for adapting the details of a list item to the requirements of NCWidgetListViewController. It is composed of an item's text and list color.
            
*/

import Cocoa
import ListerKitOSX

class ListRowRepresentedObject: NSObject {
    // MARK: Properties

    var item: ListItem
    var color: NSColor

    // MARK: Initializers

    init(item: ListItem, color: NSColor) {
        self.item = item
        self.color = color
    }
}
