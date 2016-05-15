/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ListTableView` class is an `NSTableView` subclass that ensures that the text field is always the first responder for an event.
*/

import Cocoa

class ListTableView: NSTableView {
    override func validateProposedFirstResponder(responder: NSResponder, forEvent event: NSEvent?) -> Bool {
        if responder is NSTextField {
            return true
        }

        return super.validateProposedFirstResponder(responder, forEvent: event)
    }
}
