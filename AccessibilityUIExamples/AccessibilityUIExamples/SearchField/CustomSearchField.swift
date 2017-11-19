/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example demonstrating adding accessibility to an NSSearchField subclass that
 shows how to use the NSAccessibilitySharedFocusElementsAttribute
*/

import Cocoa

// IMPORTANT: This is not a template for developing a custom control.
// This sample is intended to demonstrate how to add accessibility to
// existing custom controls that are not implemented using the preferred methods.
// For information on how to create custom controls please visit http://developer.apple.com

class CustomSearchField: NSSearchField {

    // So we can inform the delegate of our search results (focused elements).
    weak var sharedFocusDelegate: SharedFocusSearchFieldDelegate?

    // MARK: - Accessibility
    
    // Returns array of elements with which this element shares keyboard focus.ell
    override func accessibilitySharedFocusElements() -> [Any]? {
        return sharedFocusDelegate?.accessibilitySharedFocusElementsForSearchFieldCell()
    }
    
}

// MARK: - SharedFocusSearchFieldDelegate

protocol SharedFocusSearchFieldDelegate : class {
    func accessibilitySharedFocusElementsForSearchFieldCell() -> [Any]
}
