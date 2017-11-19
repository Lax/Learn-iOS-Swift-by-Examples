/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example demonstrating setup of an accessibility rotor to search for fruit buttons.
*/

import Cocoa

/*
 IMPORTANT: This is not a template for developing a custom control.
 This sample is intended to demonstrate how to add accessibility to
 existing custom controls that are not implemented using the preferred methods.
 For information on how to create custom controls please visit http://developer.apple.com
*/

class CustomRotorsElementView: NSView {

    // MARK: - View Lifecycle
    
    required override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    fileprivate func commonInit() {
        //•• needed?
    }
    
    // MARK: - Accessibility
    
    override func isAccessibilityElement() -> Bool {
        NSLog("CustomRotorsElementView: accessibilityLabel")
        return true
    }
    
    override func accessibilityRole() -> String? {
        NSLog("CustomRotorsElementView: accessibilityRole")
        return NSAccessibilityGroupRole
    }
    
}

