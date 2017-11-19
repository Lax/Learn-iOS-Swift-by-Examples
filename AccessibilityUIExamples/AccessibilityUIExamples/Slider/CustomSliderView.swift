/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example demonstrating adding accessibility to an NSView subclass that behaves like a slider by implementing the NSAccessibilitySlider protocol.
*/

import Cocoa

/*
 IMPORTANT: This is not a template for developing a custom control.
 This sample is intended to demonstrate how to add accessibility to
 existing custom controls that are not implemented using the preferred methods.
 For information on how to create custom controls please visit http://developer.apple.com
*/

class CustomSliderView: NSView, NSAccessibilitySlider {
    
    // MARK: - Internals
    
    fileprivate struct LayoutInfo {
        static let SliderHandleWidth = CGFloat(12.0)
        static let SliderHandleHeight = SliderHandleWidth
        static let SliderMinValue = CGFloat(-50.0)
        static let SliderMaxValue = CGFloat(50.0)
        static let SliderStepSize = CGFloat(5.0)
        static let SliderBorderLineWidth = CGFloat(2.0)
    }
    
    var vertical = false
    var minValue = CGFloat(0.0)
    var maxValue = CGFloat(0.0)
    var value = CGFloat(0.0)
    var stepSize = CGFloat(0.0)
    
    // MARK: - View Lifecycle
    
    required override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        vertical = frame.size.width < frame.size.height
        minValue = LayoutInfo.SliderMinValue
        maxValue = LayoutInfo.SliderMaxValue
        stepSize = LayoutInfo.SliderStepSize
        value = 0.0
    }
    
    // MARK: - Value Management
    
    fileprivate func setValue(newValue: CGFloat) {
        var valueToUse = newValue
        if valueToUse < CGFloat(minValue) {
            valueToUse = minValue
        }
        if valueToUse > maxValue {
            valueToUse = maxValue
        }
        value = valueToUse
        needsDisplay = true
    }
    
    fileprivate func decrement() {
        if value > LayoutInfo.SliderMinValue {
            value -= stepSize
            needsDisplay = true
        }
    }
    
    fileprivate func increment() {
        if value < LayoutInfo.SliderMaxValue {
            value += stepSize
            needsDisplay = true
        }
    }
    
    fileprivate func handleRange() -> CGFloat {
        var range = CGFloat(0.0)
        
        if vertical {
            range = bounds.size.height - LayoutInfo.SliderHandleHeight
        } else {
            range = bounds.size.width - LayoutInfo.SliderHandleWidth
        }
        
        return range
    }
    
    fileprivate func valueRange() -> CGFloat {
        return maxValue - minValue
    }
    
    fileprivate func percentValue() -> CGFloat {
        return (value - minValue) / valueRange()
    }
    
    fileprivate func handleRect() -> NSRect {
        var handleRect = NSRect.zero
        
        if vertical {
            handleRect = NSRect(x: 0, y: handleRange() * percentValue(), width: bounds.size.width, height: LayoutInfo.SliderHandleHeight)
        } else {
            handleRect = NSRect(x: handleRange() * percentValue(), y: 0, width: LayoutInfo.SliderHandleWidth, height: bounds.size.height)
        }
        
        return handleRect
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
        switch char {
        case Character(NSDownArrowFunctionKey)!, Character(NSLeftArrowFunctionKey)!:
            decrement()
        case Character(NSUpArrowFunctionKey)!, Character(NSRightArrowFunctionKey)!:
            increment()
        default: break
        }
    }
    
    // MARK: - Mouse Events
    
    override func mouseDown(with event: NSEvent) {
        let mouseDownPoint = convert(event.locationInWindow, from: nil)
        if handleRect().contains(mouseDownPoint) {
            // User clicked inside the slider.
            let unitsPerPoint = valueRange() / handleRange()
            let mouseDownValue = value

            var stop = false
            var currentEvent = event
            repeat {
                let mousePoint = convert(currentEvent.locationInWindow, from: nil)

                switch currentEvent.type {
                case NSEvent.EventType.leftMouseDown, NSEvent.EventType.leftMouseDragged:
                    let draggedDistance = vertical ? mousePoint.y - mouseDownPoint.y : mousePoint.x - mouseDownPoint.x
                    let potentialValue = mouseDownValue + unitsPerPoint * draggedDistance
                    
                    // Make sure the slider's potential doesn't go out of bounds.
                    if potentialValue < LayoutInfo.SliderMaxValue &&
                        potentialValue > LayoutInfo.SliderMinValue {
                        value = mouseDownValue + unitsPerPoint * draggedDistance
                    }
                    
                    // Continue to get the next event.
                    currentEvent =
                        (window?.nextEvent(matching: [NSEvent.EventTypeMask.leftMouseUp, NSEvent.EventTypeMask.leftMouseDragged],
                                           until: NSDate.distantFuture,
                                           inMode: RunLoopMode.eventTrackingRunLoopMode,
                                           dequeue: true))!
                default:
                    // User stopped tracking the slider.
                    stop = true
                    break
                }
                display()
            }
            while !stop
        }
    }
    
    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        
        NSColor.white.setFill()
        dirtyRect.fill()

        // Draw the slider outline.
        let outline = NSBezierPath(rect: bounds)
        NSColor.black.setFill()
        outline.lineWidth = LayoutInfo.SliderBorderLineWidth
        outline.stroke()
        
        // Draw the slider handle.
        let handle = NSBezierPath(rect: handleRect())
        handle.fill()
        
        // Draw the focus ring if we are the first responder.
        if window?.firstResponder == self {
            NSFocusRingPlacement.only.set()
            handle.fill()
        }
    }
    
}

// MARK: - First Responder

extension CustomSliderView {
    
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

// MARK: - NSAccessibilitySlider

extension CustomSliderView {
    
    override func accessibilityValue() -> Any? {
        return value
    }
    
    override func accessibilityLabel() -> String? {
        var label = ""
        if vertical {
            label = NSLocalizedString("Y Value", comment:"")
        } else {
            label = NSLocalizedString("X Value", comment:"")
        }
        return label
    }
    
    override func accessibilityPerformIncrement() -> Bool {
        increment()
        return true
    }
    
    override func accessibilityPerformDecrement() -> Bool {
        decrement()
        return true
    }
    
}
