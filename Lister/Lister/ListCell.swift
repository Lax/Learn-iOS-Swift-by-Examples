/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A custom cell used to display a list in the `ListDocumentsViewController`.
*/

import UIKit

class ListCell: UITableViewCell {
    // MARK: Properties

    @IBOutlet weak var label: UILabel!

    @IBOutlet weak var listColorView: UIView!
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        let color = listColorView.backgroundColor!
        
        super.setHighlighted(highlighted, animated: animated)
        
        // Reset the background color for the list color; the default implementation makes it clear.
        listColorView.backgroundColor = color
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        let color = listColorView.backgroundColor!
        
        super.setSelected(selected, animated: animated)
        
        // Reset the background color for the list color; the default implementation makes it clear.
        listColorView.backgroundColor = color
        
        // Ensure that tapping on a selected cell doesn't re-trigger the display of the document.
        userInteractionEnabled = !selected
    }
}
