/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example demonstrating setup of an accessibility rotor to search for fruit buttons..
*/

import Cocoa

@available(OSX 10.13, *)
class CustomRotorsPageView: NSView {
    
    var contentView = NSView()
    
    // MARK: - View Lifecycle
    
    required override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Drawing
    
    override func draw(_ dirtyRect: NSRect) {
        // Draw the outline background.
        NSColor.yellow.set()
        bounds.fill()
    }
    
    // MAR: - Accessibility
    
    override func isAccessibilityElement() -> Bool {
        return true
    }
    
    override func accessibilityRole() -> NSAccessibilityRole? {
        return NSAccessibilityRole.pageRole
    }
    
}
