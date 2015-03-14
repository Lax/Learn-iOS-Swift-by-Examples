/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A custom cell that allows the user to select a color.
*/

import UIKit
import ListerKit

/// Provides the ability to send a delegate a message about newly created list info objects.
@objc protocol ListColorCellDelegate {
    func listColorCellDidChangeSelectedColor(listColorCell: ListColorCell)
}

/**
    A UIView subclass that's used to test whether or not a `colorTap(_:)` action occurs from a view
    that we designate as color tappable (e.g. the "Color" label should not be tappable).
*/
class ColorTappableView: UIView {}

class ListColorCell: UITableViewCell {
    // MARK: Properties

    @IBOutlet weak var gray: UIView!

    @IBOutlet weak var blue: UIView!
    
    @IBOutlet weak var green: UIView!
    
    @IBOutlet weak var yellow: UIView!
    
    @IBOutlet weak var orange: UIView!
    
    @IBOutlet weak var red: UIView!

    weak var delegate: ListColorCellDelegate?
    
    var selectedColor = List.Color.Gray

    // MARK: Configuration

    func configure() {
        // Set up a gesture recognizer to track taps on color views in the cell.
        let colorGesture = UITapGestureRecognizer(target: self, action: "colorTap:")
        colorGesture.numberOfTapsRequired = 1
        colorGesture.numberOfTouchesRequired = 1
        
        addGestureRecognizer(colorGesture)
    }
    
    // MARK: UITapGestureRecognizer Handling
    
    @IBAction func colorTap(tapGestureRecognizer: UITapGestureRecognizer) {
        if tapGestureRecognizer.state != .Ended {
            return
        }
        
        let tapLocation = tapGestureRecognizer.locationInView(contentView)

        // If the user tapped on a color (identified by its tag), notify the delegate.
        if let view = contentView.hitTest(tapLocation, withEvent: nil) as? ColorTappableView {
            selectedColor = List.Color(rawValue: view.tag)!

            delegate?.listColorCellDidChangeSelectedColor(self)
        }
    }
}
