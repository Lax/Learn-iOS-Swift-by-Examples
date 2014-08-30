/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A layer-backed custom check box that is IBDesignable and IBInspectable.
            
*/

import Cocoa

@IBDesignable class CheckBox: NSButton {
    // MARK: Properties
    
    @IBInspectable var tintColor: NSColor {
        get {
            return NSColor(CGColor: checkBoxLayer.tintColor)
        }
        set {
            checkBoxLayer.tintColor = newValue.CGColor
        }
    }
    
    @IBInspectable var isChecked: Bool {
        get {
            return checkBoxLayer.isChecked
        }
        set {
            checkBoxLayer.isChecked = newValue
        }
    }
    
    var checkBoxLayer: CheckBoxLayer {
        return layer as CheckBoxLayer
    }
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: 40, height: 40)
    }
    
    // MARK: View Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        wantsLayer = true
        
        layer = CheckBoxLayer()
        
        layer.setNeedsDisplay()
    }
    
    // MARK: Events
    
    override func mouseDown(event: NSEvent) {
        isChecked = !isChecked
        
        cell().performClick(self)
    }
}