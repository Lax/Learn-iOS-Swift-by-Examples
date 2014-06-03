/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A CALayer subclass that draws a check box within its layer. This is shared between ListerKit and ListerKitOSX to draw their respective CheckBox controls.
            
*/

import QuartzCore

class CheckBoxLayer: CALayer {
    // MARK: Types

    struct SharedColors {
        static let defaultTintColor = CGColorCreate(CGColorSpaceCreateDeviceRGB(), [0.5, 0.5, 0.5])
    }
    
    // MARK: Properties

    var tintColor: CGColor = SharedColors.defaultTintColor {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var isChecked: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var strokeFactor: CGFloat = 0.07 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var insetFactor: CGFloat = 0.17 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var markInsetFactor: CGFloat = 0.34 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // MARK: Overrides
    
    override class func needsDisplayForKey(key: String) -> Bool {
        // Check to see if the key is contained in the array.
        // The array contains a ist of keys that this layer subclass supports.
        if ["tintColor", "isChecked", "strokeFactor", "insetFactor", "markInsetFactor"] ~= key {
            return true
        }

        return super.needsDisplayForKey(key)
    }

    // The method that does the heavy lifting of check box drawing code.
    override func drawInContext(context: CGContext) {
        super.drawInContext(context)
        
        let size = min(bounds.size.width, bounds.size.height)
        
        var transform = affineTransform()
        
        var xTranslate: CGFloat = 0
        var yTranslate: CGFloat = 0
        
        if bounds.size.width < bounds.size.height {
            yTranslate = (bounds.size.height - size) / 2.0
        }
        else {
            xTranslate = (bounds.size.width - size) / 2.0
        }
        transform = CGAffineTransformTranslate(transform, xTranslate, yTranslate)
        
        let strokeWidth: CGFloat = strokeFactor * size
        let checkBoxInset: CGFloat = insetFactor * size

        // Create the outer border for the check box.
        let outerDimension: CGFloat = size - 2.0 * checkBoxInset
        var checkBoxRect = CGRect(x: checkBoxInset, y: checkBoxInset, width: outerDimension, height: outerDimension)
        checkBoxRect = CGRectApplyAffineTransform(checkBoxRect, transform)
        
        // Make the desired width of the outer box.
        CGContextSetLineWidth(context, strokeWidth)
        
        // Set the tint color of the outer box.
        CGContextSetStrokeColorWithColor(context, tintColor)
        
        // Draw the outer box.
        CGContextStrokeRect(context, checkBoxRect)
        
        // Draw the inner box if it's checked.
        if isChecked {
            let markInset: CGFloat = markInsetFactor * size
            
            let markDimension: CGFloat = size - 2.0 * markInset
            var markRect = CGRect(x: markInset, y: markInset, width: markDimension, height: markDimension)
            markRect = CGRectApplyAffineTransform(markRect, transform)
            
            CGContextSetFillColorWithColor(context, tintColor)
            CGContextFillRect(context, markRect)
        }
    }
}
