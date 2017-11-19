/*
See LICENSE folder for this sample’s licensing information.

Abstract:
NSAccessibilityElement subclass for outline view items.
*/

import Cocoa

class CustomOutlineViewAccessibilityRowElement: NSAccessibilityElement {
    
    var disclosureTriangleCenterPoint = CGPoint()
    var canDisclose = false
    
    /**
     Override activation point to calculate it's position in screen coordinates relative to it's parent.
     This is necessary to support the window moving.
     */
    override func accessibilityActivationPoint() -> NSPoint {
        var result = NSPoint()
        if let parentView = accessibilityParent() as? CustomOutlineView {
            result = NSAccessibilityPointInView(parentView, disclosureTriangleCenterPoint)
        }
        return result
    }
    
    /** Override accessibilityDisclosed setter to update the the node this element represents
    This allows an accessibility client to expand or collapse a row in an outline
    (rather than just being able to read that state)
    VoiceOver, for example, exposes this via the Control+Command+\ command.
    */
    override func setAccessibilityDisclosed(_ accessibilityDisclosed: Bool) {
        if let parentView = accessibilityParent() as? CustomOutlineView {
            super.setAccessibilityDisclosed(accessibilityDisclosed)
            parentView.setExpandedStatus(expanded: accessibilityDisclosed, rowIndex: accessibilityIndex())
        }
    }
    
    // Disallow calling accessibilityDisclosed setter on elements that can't disclose (leaf nodes).
    override func isAccessibilitySelectorAllowed(_ selector: Selector) -> Bool {
        if selector == #selector(setAccessibilityDisclosed) {
            return canDisclose
        }
        return super.isAccessibilitySelectorAllowed(selector)
    }
    
    override func accessibilityRole() -> NSAccessibilityRole? {
        return NSAccessibilityRole.row
    }
    
    override func accessibilitySubrole() -> NSAccessibilitySubrole? {
        return NSAccessibilitySubrole.outlineRow
    }
}
