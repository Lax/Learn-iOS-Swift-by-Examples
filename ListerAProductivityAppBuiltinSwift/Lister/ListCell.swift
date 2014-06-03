/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A custom cell used for displaying list documents.
            
*/

import UIKit

class ListCell: UITableViewCell {
    // MARK: Properties

    @IBOutlet var label: UILabel
    @IBOutlet var listColor: UIView
    
    // MARK: Reuse
    
    override func prepareForReuse() {
        label.text = ""
        listColor.backgroundColor = UIColor.clearColor()
    }
}
