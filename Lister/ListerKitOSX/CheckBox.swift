/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A layer-backed custom check box that is IBDesignable and IBInspectable.
*/

import Cocoa

@IBDesignable public class CheckBox: NSButton {
    // MARK: Properties
    
    @IBInspectable public var tintColor: NSColor {
        get {
            return NSColor(CGColor: checkBoxLayer.tintColor)!
        }
        set {
            checkBoxLayer.tintColor = newValue.CGColor
        }
    }
    
    @IBInspectable public var isChecked: Bool {
        get {
            return checkBoxLayer.isChecked
        }
        set {
            checkBoxLayer.isChecked = newValue
        }
    }
    
    private var checkBoxLayer: CheckBoxLayer {
        return layer as! CheckBoxLayer
    }
    
    override public var intrinsicContentSize: NSSize {
        return NSSize(width: 40, height: 40)
    }
    
    // MARK: View Life Cycle
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        wantsLayer = true

        layer = CheckBoxLayer()
        layer!.setNeedsDisplay()
    }

    // MARK: Events
    
    override public func mouseDown(event: NSEvent) {
        isChecked = !isChecked
        
        cell!.performClick(self)
    }
    
    override public func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        
        if let window = window {
            layer?.contentsScale = window.backingScaleFactor
        }
    }
}