/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example demonstrating adding accessibility to an NSView subclass that behaves like a checkbox by implementing the NSAccessibilityCheckBox protocol.
*/

import Cocoa

/*
 IMPORTANT: This is not a template for developing a custom control.
 This sample is intended to demonstrate how to add accessibility to
 existing custom controls that are not implemented using the preferred methods.
 For information on how to create custom controls please visit http://developer.apple.com
*/

class CustomCheckBoxView: NSView {

    // MARK: - Internals
    
    fileprivate struct LayoutInfo {
        static let CheckboxWidth = CGFloat(12.0)
        static let CheckboxHeight = CheckboxWidth
        static let CheckboxTextSpacing = CGFloat(4.0) // Spacing between box and text.
    }

    var checkboxText = NSLocalizedString("Hello World", comment: "text of checkbox")
    
    var checked: Bool = true {
        didSet {
            if let actionHandler = actionHandler {
                actionHandler()
            }
        }
    }
    
    // MARK: - View Lifecycle
    
    required override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override open func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        checked = true // So our actionHandler is called when first added to the window.
    }
    
    // MARK: - Events
 
    var actionHandler: (() -> Void)?

    // MARK: - Mouse Events
    
    fileprivate func toggleCheckedState () {
        checked = !checked
        NSAccessibilityPostNotification(self, NSAccessibilityNotificationName.valueChanged)
        needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        toggleCheckedState()
    }

    // MARK: - Key Event
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 {
            // Space character was types.
            toggleCheckedState()
        } else {
            super.keyDown(with: event)
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        // Draw the checkbox box.
        var boxImage: NSImage
        let imageName = checked ? "CustomCheckboxSelected" : "CustomCheckboxUnselected"
        boxImage = NSImage(named: NSImage.Name(rawValue: imageName))!
        let boxRect = NSRect(x: bounds.origin.x,
                             y: bounds.origin.y + 1,
                             width: LayoutInfo.CheckboxWidth,
                             height: LayoutInfo.CheckboxHeight)
        boxImage.draw(in: boxRect, from: NSRect.zero, operation: NSCompositingOperation.sourceOver, fraction: 1.0)
        
        // Draw the checkbox text.
        let textAttributes = [
            NSAttributedStringKey.font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
            NSAttributedStringKey.foregroundColor: NSColor.black
        ]
        let textRect = NSRect(x: bounds.origin.x + LayoutInfo.CheckboxWidth + LayoutInfo.CheckboxTextSpacing,
                              y: bounds.origin.y,
                              width: bounds.size.width,
                              height: bounds.size.height)
        checkboxText.draw(in: textRect, withAttributes: textAttributes)
        
        // Draw the focus ring.
        NSFocusRingPlacement.only.set()
        let ovalPath = NSBezierPath(rect: boxRect)
        ovalPath.fill()
    }
    
}

// MARK: -

extension CustomCheckBoxView {
    
    // MARK: First Responder
    
    // Set to allow keyDown to be called.
    override var acceptsFirstResponder: Bool { return true }
    
    override func becomeFirstResponder() -> Bool {
        let didBecomeFirstResponder = super.becomeFirstResponder()
        needsDisplay = true
        return didBecomeFirstResponder
    }
    
    override func resignFirstResponder() -> Bool {
        let didResignFirstResponder = super.resignFirstResponder()
        needsDisplay = true
        return didResignFirstResponder
    }
    
}

// MARK: -

extension CustomCheckBoxView {
    
    // MARK: Accessibility
    
    override func accessibilityValue() -> Any? {
        return checked
    }
    
    override func accessibilityLabel() -> String? {
        return checkboxText
    }
    
    override func accessibilityPerformPress() -> Bool {
        // User did control-option-space keyboard shortcut.
        toggleCheckedState()
        return true
    }
    
}

