/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This file contains simple cell elements for display in our UICollectionViewController
*/

import UIKit

/**
    The `DocumentCell` class reflects the content of one document in our collection
    view. It manages an image view to display the thumbnail as well as two labels
    for the display name and container name (for external documents) of the document
    respectively.
*/
class DocumentCell: UICollectionViewCell {
    // MARK: Properties
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var label: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    
    var thumbnail: UIImage? {
        didSet {
            imageView.image = thumbnail
            contentView.backgroundColor = thumbnail != nil ? UIColor.whiteColor() : UIColor.lightGrayColor()
        }
    }
    
    var title = "" {
        didSet {
            label.text = title
        }
    }
    
    var subtitle = "" {
        didSet {
            subtitleLabel.text = subtitle
        }
    }
    
    // MARK: Overrides
    
    override func prepareForReuse() {
        title = ""
        subtitle = ""
        thumbnail = nil
    }
}


/**
    The `HeaderView` class is a simple view for displaying our section headers in
    the collection view.
*/
class HeaderView : UICollectionReusableView {
    @IBOutlet var label: UILabel!
    
    var title = "" {
        didSet {
            label.text = title
        }
    }
    
    override func prepareForReuse() {
        title = ""
    }
}
