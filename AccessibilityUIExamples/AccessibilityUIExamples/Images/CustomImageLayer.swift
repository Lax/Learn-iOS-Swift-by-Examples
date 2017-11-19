/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example demonstrating adding accessibility to a CALayer subclass that behaves like an image by implementing the NSAccessibilityImage protocol.
*/

import Cocoa
import QuartzCore

class CustomImageLayer: CALayer, NSAccessibilityImage {

    var parent: NSView!
    var titleElement: CustomTextLayer!
    
    // MARK: NSAccessibilityImage
    
    func accessibilityFrame() -> NSRect {
        return NSAccessibilityFrameInView(parent, frame)
    }
    
    func accessibilityParent() -> Any? {
        return NSAccessibilityUnignoredAncestor(parent)
    }
    
    func accessibilityLabel() -> String? {
        return titleElement.string as? String
    }
    
    func accessibilityTitleUIElement() -> Any? {
        return titleElement
    }

}

