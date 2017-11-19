/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example demonstrating adding accessibility to an NSView subclass that behaves like a
 radio button group by implementing the NSAccessibilityGroup protocol and using NSAccessibilityElement.
*/

import Cocoa

/*
 IMPORTANT: This is not a template for developing a custom control.
 This sample is intended to demonstrate how to add accessibility to
 existing custom controls that are not implemented using the preferred methods.
 For information on how to create custom controls please visit http://developer.apple.com
 */

class RadioButtonAccessibilityElement: NSAccessibilityElement {
    
    var button = 0
    
    override func setAccessibilityFocused(_ accessibilityFocused: Bool) {
        if accessibilityFocused {
            if let parent = accessibilityParent() as? CustomRadioButtonsView {
                _ = parent.becomeFirstResponder()
                parent.selectedButton = button
            }
        }
    }
}

// MARK: -

class CustomRadioButtonsView: NSView, NSAccessibilityGroup {

    // MARK: - Internals
    
    fileprivate struct LayoutInfo {
        static let RadioButtonHeight = CGFloat(22.0)
        static let RadioCircleWidth = CGFloat(10.0)
        static let RadioCircleHeight = RadioCircleWidth
        static let RadioToTextSpacing = CGFloat(7.0)
    }
    
    var selectedButton: Int = 0 {
        didSet {
            if let actionHandler = actionHandler {
                actionHandler()
            }
            NSAccessibilityPostNotification(self, NSAccessibilityNotificationName.focusedUIElementChanged)
            needsDisplay = true
        }
    }
    
    var actionHandler: (() -> Void)?
    
    var children = [RadioButtonAccessibilityElement]()
    
    var radioButtonText = [String]()
    fileprivate var mouseDownButton = 0
    
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
        radioButtonText = [
            NSLocalizedString("Choice one", comment: "text of first choice"),
            NSLocalizedString("Choice two", comment: "text of second choice"),
            NSLocalizedString("Choice three", comment: "text of thrid choice")]
        
            let count = radioButtonText.count
            for button in 0..<count {
                let radioButton = RadioButtonAccessibilityElement()

                var bounds = rectForButton(button: button)
                bounds = NSAccessibilityFrameInView(self, bounds)
                radioButton.button = button

                let buttonText = radioButtonText[button]
                radioButton.setAccessibilityLabel(buttonText)

                radioButton.setAccessibilityParent(self)
                radioButton.setAccessibilityRole(NSAccessibilityRole.radioButton)
                radioButton.setAccessibilityFrame(bounds)

                children.append(radioButton)
            }
    }
 
    override open func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        // So our actionHandler is called when first added to the window.
        selectedButton = 0
    }
    
    // MARK: - Measurements
    
    func rectForButton(button: Int) -> NSRect {
        return NSRect(x: bounds.origin.x,
                      y: bounds.size.height - LayoutInfo.RadioButtonHeight * CGFloat(button + 1),
                      width: bounds.size.width,
                      height: LayoutInfo.RadioButtonHeight)
    }

    fileprivate func textDrawingRectForButton(button: Int) -> NSRect {
        let buttonRect = rectForButton(button: button)
        let textOriginXOffset = LayoutInfo.RadioCircleWidth + LayoutInfo.RadioToTextSpacing
        return NSRect(x: buttonRect.origin.x + CGFloat(textOriginXOffset),
                      y: buttonRect.origin.y,
                      width: buttonRect.size.width - CGFloat(textOriginXOffset),
                      height: buttonRect.size.height)
    }

    fileprivate func textHitTestRectForButton(button: Int) -> NSRect {
        let textDrawingRect = textDrawingRectForButton(button: button)
        let text = radioButtonText[button] as NSString!
        let size = NSSize(width: textDrawingRect.size.width, height: NSFont.systemFontSize)
        
        let textBoundingRect = text?.boundingRect(with: size, options: [], attributes: nil, context: nil)
        
        return NSRect(x: textDrawingRect.origin.x,
                      y: textDrawingRect.origin.y,
                      width: textBoundingRect!.size.width,
                      height: textDrawingRect.size.height)
    }

    func radioCircleHitTestRectForButton(button: Int) -> NSRect {
        return radioCircleDrawingRectForButton(button: button)
    }
 
    fileprivate func radioCircleDrawingRectForButton(button: Int) -> NSRect {
        let buttonRect = rectForButton(button: button)
        
        return NSRect(x: buttonRect.origin.x,
                      y: buttonRect.origin.y + (buttonRect.size.height - LayoutInfo.RadioCircleHeight) / 2.0 + 2.0,
                      width: LayoutInfo.RadioCircleWidth,
                      height: LayoutInfo.RadioCircleHeight)
    }
    
    fileprivate func buttonForPoint(point: NSPoint) -> Int {
        return Int(floor((bounds.size.height - point.y) / LayoutInfo.RadioButtonHeight))
    }

    // MARK: - Mouse Events
    
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        mouseDownButton = buttonForPoint(point: point)
        needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let mouseUpButton = buttonForPoint(point: point)
        if mouseUpButton == mouseDownButton {
            selectedButton = mouseUpButton
        }
    }

    // MARK: - Keyboard Events
    
    override func keyDown(with event: NSEvent) {
        guard event.modifierFlags.contains(.numericPad),
            let charactersIgnoringModifiers = event.charactersIgnoringModifiers, charactersIgnoringModifiers.characters.count == 1,
            let char = charactersIgnoringModifiers.characters.first
            else {
                super.keyDown(with: event)
                return
        }
        let newSelectedButton = selectedButton
        switch char {
        case Character(NSUpArrowFunctionKey)!:
            if newSelectedButton - 1 >= 0 {
                selectedButton = newSelectedButton - 1
            }
        case Character(NSDownArrowFunctionKey)!:
            if newSelectedButton + 1 < radioButtonText.count {
                selectedButton = newSelectedButton + 1
            }
        default: break
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        let textAttributes = [ NSAttributedStringKey.font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
                               NSAttributedStringKey.foregroundColor: NSColor.black ]
        
        let radioButtonCount = radioButtonText.count
        for idx in 0..<radioButtonCount {
            // Draw the radio circle.
            let radioCircleRect = radioCircleDrawingRectForButton(button: idx)
            var radioCircleImage: NSImage
            
            let imageName = idx == selectedButton ? "CustomRadioButtonSelected" : "CustomRadioButtonUnselected"
            radioCircleImage = NSImage(named: NSImage.Name(rawValue: imageName))!

            radioCircleImage.draw(in: radioCircleRect, from: NSRect.zero, operation: NSCompositingOperation.sourceOver, fraction: 1.0)
            
            // Draw the radio text.
            let textRect = textDrawingRectForButton(button: idx)
            let buttonText = radioButtonText[idx]
            buttonText.draw(in: textRect, withAttributes: textAttributes)
            
            // Draw the focus ring if we are the first responder.
            if window?.firstResponder == self && idx == selectedButton {
                let currentContext = NSGraphicsContext.current?.cgContext
                currentContext?.saveGState()
                NSFocusRingPlacement.only.set()
                let ovalPath = NSBezierPath(ovalIn: radioCircleRect)
                ovalPath.fill()
                currentContext?.restoreGState()
            }
        }
    }

}

// MARK: -

extension CustomRadioButtonsView {
    
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

extension CustomRadioButtonsView {
    
    // MARK: Accessibility
    
    override func accessibilityApplicationFocusedUIElement() -> Any? {
        return accessibilityChildren()?[selectedButton]
    }
    
    override func accessibilityChildren() -> [Any]? {
        // Ensure activation point and value are up to date whenever the children are returned.
        let count = radioButtonText.count
        for button in 0..<count {
            let radioButton = children[button]
            
            // Update its bounds.
            var bounds = rectForButton(button: button)
            bounds = NSAccessibilityFrameInView(self, bounds)
            radioButton.setAccessibilityFrame(bounds)
            
            // Update it's activation and center points.
            let activationBounds = radioCircleHitTestRectForButton(button: button)
            let activationBoundsCenterPoint = NSPoint(x: activationBounds.midX, y: activationBounds.midY)
            radioButton.setAccessibilityActivationPoint(NSAccessibilityPointInView(self, activationBoundsCenterPoint))
            radioButton.setAccessibilityValue((button == selectedButton) ? NSNumber(value: true) : NSNumber(value: false))
        }
        return children
    }
    
}

