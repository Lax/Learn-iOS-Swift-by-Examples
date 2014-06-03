/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A custom cell used for displaying list items, and the row allowing for the creation of new items.
            
*/

import UIKit
import ListerKit

class ListItemCell: UITableViewCell {
    // MARK: Properties

    @IBOutlet var textField: UITextField
    @IBOutlet var checkBox: CheckBox
    
    var isComplete: Bool = false {
        didSet {
            textField.enabled = !isComplete
            checkBox.isChecked = isComplete
            
            textField.textColor = isComplete ? UIColor.lightGrayColor() : UIColor.darkTextColor()
        }
    }
    
    // MARK: Reuse

    override func prepareForReuse() {
        textField.text = ""
        textField.textColor = UIColor.darkTextColor()
        textField.enabled = true
        checkBox.isChecked = false
        checkBox.hidden = false
    }
}
