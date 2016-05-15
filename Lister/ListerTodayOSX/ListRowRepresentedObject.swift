/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ListRowRepresentedObject` class provides an abstraction suitable for adapting the details of a list item to the requirements of the `NCWidgetListViewController` class. It is composed of an item's text and list color.
*/

import Cocoa
import ListerKit

class ListRowRepresentedObject: NSObject {
    // MARK: Properties

    var listItem: ListItem
    var color: NSColor

    // MARK: Initializers

    init(listItem: ListItem, color: NSColor) {
        self.listItem = listItem
        self.color = color
    }
}
