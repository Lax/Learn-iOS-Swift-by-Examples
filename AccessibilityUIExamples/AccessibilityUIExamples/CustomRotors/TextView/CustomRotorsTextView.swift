/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example demonstrating setup of accessibility rotors to search for various text attributes on an text view.
*/

import Cocoa

@available(OSX 10.13, *)
class CustomRotorsTextView: NSTextView {
    
    weak var rotorDelegate: CustomRotorsTextViewDelegate?
    
    // MARK: Accessibility
    
    override func accessibilityCustomRotors() -> [NSAccessibilityCustomRotor] {
        return rotorDelegate?.createCustomRotors() ?? []
    }
}

// MARK: -

@available(OSX 10.13, *)
protocol CustomRotorsTextViewDelegate : class {
    func createCustomRotors() -> [NSAccessibilityCustomRotor]
}
