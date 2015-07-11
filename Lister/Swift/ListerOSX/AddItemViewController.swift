/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `AddItemViewController` class displays the user interface for creating a new list item in the table view.
*/

import Cocoa

// A protocol that allows a delegate of `AddItemViewController` to be aware of any new items that should be created.
@objc protocol AddItemViewControllerDelegate {
    func addItemViewController(addItemViewController: AddItemViewController, didCreateNewItemWithText text: String)
}

class AddItemViewController: NSViewController {
    // MARK: Properties

    weak var delegate: AddItemViewControllerDelegate?

    // MARK: IBActions

    @IBAction func textChanged(textField: NSTextField) {
        let cleansedString = textField.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if !cleansedString.isEmpty {
            delegate?.addItemViewController(self, didCreateNewItemWithText: cleansedString)
        }

        // Tell the presenting view controller to dismiss the popover.
        presentingViewController?.dismissViewController(self)
    }
}
