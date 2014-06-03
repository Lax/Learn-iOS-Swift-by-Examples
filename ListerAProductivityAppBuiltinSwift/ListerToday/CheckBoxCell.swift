/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A check box cell for the Today view.
            
*/

import UIKit
import ListerKit

class CheckBoxCell: UITableViewCell {
    // MARK: Properties
    
    @IBOutlet var label: UILabel
    @IBOutlet var checkBox: CheckBox
    
    // MARK: Reuse
    
    override func prepareForReuse() {
        textLabel.text = ""
        textLabel.textColor = UIColor.whiteColor()
        checkBox.isChecked = false
        checkBox.hidden = false
        checkBox.tintColor = UIColor.clearColor()
    }
}
