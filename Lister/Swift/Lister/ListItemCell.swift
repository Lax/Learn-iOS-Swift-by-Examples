/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A custom cell used to display a list item or the row used to create a new item.
*/

import UIKit
import ListerKit

class ListItemCell: UITableViewCell {
    // MARK: Properties

    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var checkBox: CheckBox!
    
    var isComplete = false {
        didSet {
            textField.enabled = !isComplete
            checkBox.isChecked = isComplete
            
            textField.textColor = isComplete ? UIColor.lightGrayColor() : UIColor.darkTextColor()
        }
    }
}
