/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example demonstrating making an accessible, custom three-position switch.
*/

import Cocoa

/*
 IMPORTANT: This is not a template for developing a custom switch.
 This sample is intended to demonstrate how to add accessibility to
 existing custom controls that are not implemented using the preferred methods.
 For information on how to create custom controls please visit http://developer.apple.com
*/

class ThreePositionSwitchView: NSControl {
    
    // MARK: - Internals
    
    enum SwitchPosition: Int {
        case left
        case center
        case right
    }
    
    fileprivate var backgroundColor = NSColor.red
    fileprivate var handleColor = NSColor.blue
    
    fileprivate var dragTrackingStartLocation = NSPoint(x: -1, y: -1)
    fileprivate var dragTrackingCurrentLocation = NSPoint()
    var position = 0
    
    fileprivate static let ThreePositionSwitchHandleWidth = CGFloat(52.0)
    
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
        isEnabled = true
    }
    
    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        backgroundColor.setFill()
        
        let drawRect = bounds.intersection(dirtyRect)
        drawRect.fill()
        
        // Draw the switch background.
        var imageRect = NSRect.zero
        var imageName = "SwitchWell"
        let wellImage = NSImage(named: NSImage.Name(rawValue: imageName))!
        imageRect.size = wellImage.size
        var trackPoint = bounds.origin
        trackPoint.y += 1.0
        wellImage.draw(at: trackPoint, from: imageRect, operation: NSCompositingOperation.copy, fraction: 1.0)
        
        // Draw the switch overlay.
        imageName = "SwitchOverlayMask"
        var maskImage = NSImage(named: NSImage.Name(rawValue: imageName))!
        trackPoint.y -= 1.0
        imageRect.size = maskImage.size
        maskImage.draw(at: trackPoint, from: imageRect, operation: NSCompositingOperation.sourceOver, fraction: 1.0)
        
        // Draw the switch handle.
        imageName = dragTrackingStartLocation.x < 0 && dragTrackingStartLocation.y < 0 ? "SwitchHandle" : "SwitchHandleDown"
        maskImage = NSImage(named: NSImage.Name(rawValue: imageName))!
        imageRect.size = maskImage.size
        var origin = handleRect().origin
        origin.x -= 3.5
        origin.y = (bounds.size.height - imageRect.size.height) / 2.0
        maskImage.draw(at: origin, from: imageRect, operation: NSCompositingOperation.sourceOver, fraction: 1.0)
    }

    fileprivate func handleRect() -> NSRect {
        var originX: CGFloat
        
        switch position {
        case SwitchPosition.center.rawValue:
            originX = CGFloat(bounds.size.width / 2.0) - (ThreePositionSwitchView.ThreePositionSwitchHandleWidth / 2.0)
        case SwitchPosition.right.rawValue:
            originX = CGFloat(bounds.size.width) - ThreePositionSwitchView.ThreePositionSwitchHandleWidth
        default:
            originX = 0
            break
        }
        
        // Offset by current drag distance.
        originX -= (dragTrackingStartLocation.x - dragTrackingCurrentLocation.x)
        
        // Clamp to view bounds.
        originX = CGFloat(min(max(0, originX), bounds.size.width - ThreePositionSwitchView.ThreePositionSwitchHandleWidth))
        
        return NSRect(x: originX, y: 0, width: ThreePositionSwitchView.ThreePositionSwitchHandleWidth, height: bounds.size.height)
    }
    
    // MARK: - Handle Movement
    
    fileprivate func snapHandleToClosestPosition() {
        let oneThirdWidth = bounds.size.width / 3.0
        
        var desiredPosition = 0
        
        let xPos = handleRect().midX
        if xPos < (bounds.origin.x + oneThirdWidth) {
            desiredPosition = SwitchPosition.left.rawValue
        } else if xPos > (bounds.origin.x + (oneThirdWidth * 2.0)) {
            desiredPosition = SwitchPosition.right.rawValue
        } else {
            desiredPosition = SwitchPosition.center.rawValue
        }
        
        if desiredPosition != position {
            position = desiredPosition
            
            // Call our action method in the owning view controller.
            NSApp.sendAction(action!, to: target, from: self)
        }
    }
    
    fileprivate func moveHandleToNextPositionRight(rightDirection: Bool, shouldWrap: Bool) {
        var nextPosition = 0
        
        switch position {
        case SwitchPosition.left.rawValue:
            if rightDirection {
                nextPosition = SwitchPosition.center.rawValue
            } else {
                nextPosition = shouldWrap ? SwitchPosition.right.rawValue : SwitchPosition.left.rawValue
            }
        case SwitchPosition.center.rawValue:
            nextPosition = rightDirection ? SwitchPosition.right.rawValue : SwitchPosition.left.rawValue
        case SwitchPosition.right.rawValue:
            if rightDirection {
                nextPosition = shouldWrap ? SwitchPosition.left.rawValue : SwitchPosition.right.rawValue
            } else {
                nextPosition = SwitchPosition.center.rawValue
            }
        default: break
        }
        
        if nextPosition != position {
            position = nextPosition
            
            // Call our action method in the owning view controller.
            NSApp.sendAction(action!, to: target, from: self)
            display()
        }
    }

    fileprivate func moveHandleToPreviousPositionWrapAround(shouldWrap: Bool) {
        moveHandleToNextPositionRight(rightDirection: false, shouldWrap: shouldWrap)
    }
    
    fileprivate func moveHandleToNextPositionWrapAround(shouldWrap: Bool) {
        moveHandleToNextPositionRight(rightDirection: true, shouldWrap: shouldWrap)
    }

    // MARK: - Mouse events

    fileprivate func handleMouseDrag(event: NSEvent) {
        var currentEvent = event
        let eventMask: NSEvent.EventTypeMask = [NSEvent.EventTypeMask.leftMouseUp, NSEvent.EventTypeMask.leftMouseDragged]
        let untilDate = NSDate.distantFuture

        var stop = false
        repeat {
            let mousePoint = convert(currentEvent.locationInWindow, from: nil)
            switch currentEvent.type {
            case NSEvent.EventType.leftMouseDown, NSEvent.EventType.leftMouseDragged:
                dragTrackingCurrentLocation = mousePoint
                currentEvent = (window?.nextEvent(matching: eventMask,
                                                  until: untilDate,
                                                  inMode: RunLoopMode.eventTrackingRunLoopMode,
                                                  dequeue: true))!
            default:
                stop = true
                break
            }
            display()
        }
        while !stop
        
        snapHandleToClosestPosition()
        
        // Reset our tracking states.
        dragTrackingCurrentLocation = NSPoint(x: -1, y: -1)
        dragTrackingStartLocation = NSPoint(x: -1, y: -1)
        
        display()
    }
    
    override func mouseDown(with event: NSEvent) {
        // If we are not enabled or can't become the first responder, don't do anything.
        guard isEnabled || (window?.makeFirstResponder(self))! else { return }
        
        // Determine the location, in our local coordinate system, where the user clicked.
        let location = convert(event.locationInWindow, from: nil)
        
        let pointInKnob = handleRect().contains(location)
        if pointInKnob {
            // When we receive a mouse down event, we reset the dragTrackingLocation.
            dragTrackingStartLocation = location
            handleMouseDrag(event: event)
        } else {
            // Treat clicks outside handle bounds as increment/decrement actions.
            let moveRight = location.x > handleRect().origin.x
            moveHandleToNextPositionRight(rightDirection: moveRight, shouldWrap: false)
        }
    }

    // MARK: - Keyboard Events
    
    // Allow keyDown, moveLeft, moveRight to be called.
    override var acceptsFirstResponder: Bool { return true }
    
    override func keyDown(with event: NSEvent) {
        if event.characters == " " {
            moveHandleToNextPositionWrapAround(shouldWrap: true)
        } else {
            // Arrow keys are associated with the numeric keypad.
            if event.modifierFlags.contains(.numericPad) {
                interpretKeyEvents([event])
            } else {
                super.keyDown(with: event)
            }
        }
    }
    
    override func moveLeft(_ sender: Any?) {
        moveHandleToPreviousPositionWrapAround(shouldWrap: false)
    }
    
    override func moveRight(_ sender: Any?) {
        moveHandleToNextPositionWrapAround(shouldWrap: false)
    }

}

// MARK: -

extension ThreePositionSwitchView {
    // MARK: Accessibility

    override func accessibilityValue() -> Any? {
        var returnValue = ""
        
        switch position {
        case SwitchPosition.center.rawValue:
            returnValue = NSLocalizedString("on", comment: "accessibility value for the state of ON for the switch")
        case SwitchPosition.right.rawValue:
            returnValue = NSLocalizedString("auto", comment: "accessibility value for the state of AUTO for the switch")
        default:
            returnValue = NSLocalizedString("off", comment: "accessibility value for the state of OFF for the switch")
        }
        
        return returnValue
    }
    
    override func accessibilityLabel() -> String? {
        return NSLocalizedString("Switch", comment: "accessibility label of the three position switch")
    }
    
    override func accessibilityHelp() -> String {
        return NSLocalizedString("A three position switch with off, on, and auto options.",
                                 comment: "accessibility help for the three position switch")
    }
    
    override func accessibilityPerformPress() -> Bool {
        // User did control-option-space keyboard shortcut.
        moveHandleToNextPositionWrapAround(shouldWrap: true)
        return true
    }
    
    // MARK: NSAccessibilitySwitch
    
    override func accessibilityPerformIncrement() -> Bool {
        moveHandleToNextPositionWrapAround(shouldWrap: false)
        return true
    }
    
    override func accessibilityPerformDecrement() -> Bool {
        moveHandleToPreviousPositionWrapAround(shouldWrap: false)
        return true
    }
    
}

