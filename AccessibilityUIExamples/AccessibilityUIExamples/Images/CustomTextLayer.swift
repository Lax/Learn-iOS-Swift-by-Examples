/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example demonstrating adding accessibility to an NSView subclass that behaves like a label by implementing the NSAccessibilityStaticText protocol.
*/

import Cocoa

class CustomTextLayer: CATextLayer, NSAccessibilityStaticText {

    var parent: NSView!
    
    // MARK: NSAccessibilityStaticText
    
    func accessibilityFrame() -> NSRect {
        return NSAccessibilityFrameInView(parent, frame)
    }
    
    func accessibilityParent() -> Any? {
        return NSAccessibilityUnignoredAncestor(parent)
    }
    
    func accessibilityValue() -> String? {
        return string as? String
    }
}

