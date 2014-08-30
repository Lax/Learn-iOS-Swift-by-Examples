/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Controls the logic for displaying the UI for creating a new list item for the table view.
            
*/

import Cocoa

// A protocol that allows a delegate of AddItemViewController to be aware of any new items that should be created.
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

        // It's a known issue that presentingViewController currently returns nil. To work around this, you can use the escape key instead of the enter key to close the popover / create a new item.
        presentingViewController?.dismissViewController(self)
    }
}
