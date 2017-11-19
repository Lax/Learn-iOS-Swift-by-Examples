/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example demonstrating adding accessibility to an NSView subclass that behaves like a button by implementing the NSAccessibilityButton protocol.
*/

import Cocoa

/*
 IMPORTANT: This is not a template for developing a custom control.
 This sample is intended to demonstrate how to add accessibility to
 existing custom controls that are not implemented using the preferred methods.
 For information on how to create custom controls please visit http://developer.apple.com
*/

// Note that CustomButtonView is an NSView subclass and needs to adopt "NSAccessibilityButton" or in this case implement the required functions.
/// - Tag: customButtonDeclare
class CustomButtonView: NSView {
    
    // MARK: - Internals
    
    private var pressed = false
    private var highlighted = false
    private var depressed = false
    
    var actionHandler: (() -> Void)?
    
    // Set to allow keyDown to be called.
    override var acceptsFirstResponder: Bool { return true }
    
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
        // Track the mouse for enter and exit for proper highlighting.
        let trackingArea = NSTrackingArea(rect: bounds,
                                          options: [NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited],
                                          owner: self,
                                          userInfo: nil)
        addTrackingArea(trackingArea)
    }
    
    // MARK: - Actions
    
    fileprivate func pressDown() {
        pressed = true
        depressed = true
        needsDisplay = true
    }
    
    fileprivate func pressUpInside(inside: Bool, highlight: Bool) {
        pressed = false
        depressed = false
        highlighted = highlight ? inside : false
        needsDisplay = true
        
        if inside {
            // Call our action handler (ultimately winding up in the view controller).
            if let actionHandler = actionHandler {
                actionHandler()
            }
        }
    }
    
    fileprivate func performAfterDelay(delay: Double, onCompletion: @escaping() -> Void) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay, execute: {
            onCompletion()
        })
    }
    
    fileprivate func performPress () {
        // Set down and release after momentary delay so the button flickers.
        pressDown()
        
        let delayInSeconds = 0.1
        performAfterDelay(delay: delayInSeconds) {
            self.pressUpInside(inside: true, highlight: false)
        }
    }
    
    // MARK: - Drawing
    
    override func drawFocusRingMask() {
        bounds.fill()
    }

    override var focusRingMaskBounds: NSRect {
        return bounds
    }
    
    override func draw(_ dirtyRect: NSRect) {
        let upImage = NSImage(named: NSImage.Name(rawValue: ButtonImages.buttonUp))
        let downImage = NSImage(named: NSImage.Name(rawValue: ButtonImages.buttonDown))
        let highlightImage = NSImage(named: NSImage.Name(rawValue: ButtonImages.buttonHighlight))
        
        var imageToDraw = upImage
        
        if depressed {
            imageToDraw = downImage
        } else if highlighted {
            imageToDraw = highlightImage
        }
        
        imageToDraw?.draw(in: bounds, from: NSRect.zero, operation: NSCompositingOperation.sourceOver, fraction: 1.0)
    }

    // MARK: - Mouse events
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        pressDown()
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        let localPoint = convert(event.locationInWindow, from:nil)
        let isInside = bounds.contains(localPoint)
        pressUpInside(inside: isInside, highlight: true)
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        
        highlighted = true
        depressed = pressed // Restore pressed state, possibly set before mouseExited.
        needsDisplay = true
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        
        highlighted = pressed
        depressed = false
        needsDisplay = true
    }
    
    // MARK: - Keyboard Events
    
    override func keyDown(with event: NSEvent) {
        guard let charactersIgnoringModifiers = event.charactersIgnoringModifiers, charactersIgnoringModifiers.characters.count == 1,
              let char = charactersIgnoringModifiers.characters.first
            else {
                super.keyDown(with: event)
                return
            }
        if char == " " {
            performPress()
        }
    }

}

// MARK: - Accessibility

extension CustomButtonView {

    override func accessibilityLabel() -> String? {
        return NSLocalizedString("Play", comment: "accessibility label of the Play button")
    }
    
    override func accessibilityHelp() -> String {
        return NSLocalizedString("Increase press count.", comment: "accessibility help of the Play button")
    }
    
    override func accessibilityPerformPress() -> Bool {
        // User did control-option-space keyboard shortcut.
        performPress()
        return true
    }

    /// - Tag: customButtonAdoption
    override func accessibilityRole() -> NSAccessibilityRole? {
        return NSAccessibilityRole.button
    }
    
    override func isAccessibilityElement() -> Bool {
        return true
    }
}

