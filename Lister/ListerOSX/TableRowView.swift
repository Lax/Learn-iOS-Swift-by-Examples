/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `TableRowView` class is an `NSTableRowView` subclass that draws a specific background color. The table view creates these row views automatically because the `NSTableViewRowViewKey` key is set on one of the `ListViewController` object's rows in the storyboard.
*/

import Cocoa

class TableRowView: NSTableRowView {
    override func drawSelectionInRect(dirtyRect: NSRect) {
        super.drawSelectionInRect(dirtyRect)

        struct SharedColors {
            static let backgroundColor = NSColor(red: 0.76, green: 0.82, blue: 0.92, alpha: 1)
        }
        
        SharedColors.backgroundColor.set()

        NSRectFill(dirtyRect)
    }
}
