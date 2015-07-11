/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ListItemView` class is an `NSTableCellView` subclass that has a few controls that represent the state of a ListItem object.
*/

import Cocoa
import ListerKit

/// Delegate protocol to let other objects know about changes to the text field and completion state.
@objc protocol ListItemViewDelegate {
    func listItemViewDidToggleCompletionState(listItemView: ListItemView)
    func listItemViewTextDidEndEditing(listItemView: ListItemView)
}

class ListItemView: NSTableCellView, NSTextFieldDelegate {
    // MARK: Properties

    @IBOutlet weak var statusCheckBox: CheckBox!
    
    weak var delegate: ListItemViewDelegate?
    
    var isComplete = false {
        didSet {
            statusCheckBox.isChecked = isComplete
            textField!.textColor = isComplete ? NSColor.completeItemTextColor() : NSColor.incompleteItemTextColor()
            textField!.enabled = !isComplete
        }
    }

    var tintColor: NSColor {
        set {
            statusCheckBox.tintColor = newValue
        }

        get {
            return statusCheckBox.tintColor
        }
    }
    
    var stringValue: String {
        set {
            textField!.stringValue = newValue
        }
    
        get {
            return textField!.stringValue
        }
    }

    // MARK: View Life Cycle

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Listen for the NSControlTextDidEndEditingNotification notification to notify the delegate of any
        // updates it has to do its underlying model.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleControlTextDidEndEditingNotification:", name: NSControlTextDidEndEditingNotification, object: textField)
    }
    
    // MARK: Lifetime

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSControlTextDidEndEditingNotification, object: textField)
    }
    
    // MARK: IBActions

    @IBAction func statusCheckBoxButtonClicked(sender: CheckBox) {
        delegate?.listItemViewDidToggleCompletionState(self)
    }

    // MARK: Notifications

    func handleControlTextDidEndEditingNotification(notification: NSNotification) {
        delegate?.listItemViewTextDidEndEditing(self)
    }
}
