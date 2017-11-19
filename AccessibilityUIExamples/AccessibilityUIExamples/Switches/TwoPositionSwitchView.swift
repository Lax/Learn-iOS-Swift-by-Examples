/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example demonstrating making an accessible, custom two-position switch.
*/

import Cocoa

/*
 IMPORTANT: This is not a template for developing a custom switch.
 This sample is intended to demonstrate how to add accessibility to
 existing custom controls that are not implemented using the preferred methods.
 For information on how to create custom controls please visit http://developer.apple.com
 */

class TwoPositionSwitchCell: NSSliderCell {
    
    enum TrackStates: Int {
        case knobClickedState = 0
        case trackClickedState
        case knobMovedState
        case knobNoState
    }
    
    var trackingState = 0
    
    // MARK: - Drawing
    
    override func knobRect(flipped: Bool) -> NSRect {
        let value = doubleValue
        let percent: Double = (maxValue <= minValue) ? 0.0 : (value - minValue) / (maxValue - minValue)
        
        let imageName = "SwitchHandle"
        let knobImage = NSImage(named: NSImage.Name(rawValue: imageName))!
        var knobRect = NSRect(x: 0, y: 0, width: knobImage.size.width, height: knobImage.size.height)

        let offset = floor(CGFloat(trackRect.width - knobRect.width) * CGFloat(percent))

        knobRect.origin = NSPoint(x: trackRect.origin.x + offset, y: 2.0)
    
        return knobRect.integral
    }

    override func drawKnob(_ knobRect: NSRect) {
        let isClickedOrMoved =
            trackingState == TrackStates.knobClickedState.rawValue ||
            trackingState == TrackStates.knobMovedState.rawValue
        let knobImage = NSImage(named: NSImage.Name(rawValue: isClickedOrMoved ? "SwitchHandleDown" : "SwitchHandle"))!
        knobImage.draw(at: knobRect.origin, from: NSRect.zero, operation: NSCompositingOperation.sourceOver, fraction: (isEnabled ? 1.0 : 0.5))
    }
    
    override func drawBar(inside rect: NSRect, flipped: Bool) {
        // avoid drawing the track
    }
    
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        guard let controlView = controlView as? NSControl else { return }
        
        // Draw the switch background.
        var imageName = "SwitchWell"
        let wellImage = NSImage(named: NSImage.Name(rawValue: imageName))!
        var trackPoint = cellFrame.origin
        trackPoint.y += 1.0

        if controlView.isEnabled {
            wellImage.draw(at: trackPoint, from: NSRect.zero, operation: NSCompositingOperation.copy, fraction: 1.0)
        } else {
            wellImage.draw(at: trackPoint, from: NSRect.zero, operation: NSCompositingOperation.plusLighter, fraction: 1.0)
            wellImage.draw(at: trackPoint, from: NSRect.zero, operation: NSCompositingOperation.sourceOver, fraction: 0.3)
        }
        
        // Draw the switch overlay.
        imageName = "SwitchOverlayMask"
        let maskImage = NSImage(named: NSImage.Name(rawValue: imageName))!
        trackPoint.y -= 1.0
        let focused = showsFirstResponder && focusRingType != NSFocusRingType.none
        if focused {
            maskImage.draw(at: trackPoint, from: NSRect.zero, operation: NSCompositingOperation.sourceOver, fraction: 1.0)
        }
        
        super.drawInterior(withFrame: cellFrame, in:controlView)
        
        if !focused {
            maskImage.draw(at: trackPoint, from: NSRect.zero, operation: NSCompositingOperation.sourceOver, fraction: 1.0)
        }
    }

    // MARK: - Tracking
    
    override func startTracking(at startPoint: NSPoint, in controlView: NSView) -> Bool {
        guard let ourControl = controlView as? TwoPositionSwitchView else { return false }
        guard !ourControl.isAnimating else { return false }
  
        // Don't track if mouseDown is not on the knob.
        let knobRect = self.knobRect(flipped: controlView.isFlipped)
        if knobRect.contains(startPoint) {
            trackingState = TrackStates.knobClickedState.rawValue
            return super.startTracking(at: startPoint, in: controlView)
        }
        
        trackingState = TrackStates.trackClickedState.rawValue
        return true
    }

    override func continueTracking(last lastPoint: NSPoint, current currentPoint: NSPoint, in controlView: NSView) -> Bool {
        if (trackingState == TrackStates.knobClickedState.rawValue) &&
            !(lastPoint == currentPoint) &&
            !(lastPoint == NSPoint()) {
            trackingState = TrackStates.knobMovedState.rawValue
        }
        return super.continueTracking(last: lastPoint, current: currentPoint, in: controlView)
    }
    
    override func stopTracking(last lastPoint: NSPoint, current stopPoint: NSPoint, in controlView: NSView, mouseIsUp flag: Bool) {
        super.stopTracking(last: lastPoint, current: stopPoint, in: controlView, mouseIsUp: flag)
        
        guard let ourControl = controlView as? TwoPositionSwitchView else { return }
        let startValue = ourControl.targetValue
        let value = doubleValue
        
        switch trackingState {
        case TrackStates.knobClickedState.rawValue, TrackStates.trackClickedState.rawValue:
            ourControl.setDoubleValue(value: (startValue == 0.0) ? 1.0 : 0.0, animate:true)
        case TrackStates.knobMovedState.rawValue:
            if abs(startValue - value) < 0.2 {
                ourControl.setDoubleValue(value: startValue, animate: true)
            } else {
                ourControl.setDoubleValue(value: (startValue == 0.0) ? 1.0 : 0.0, animate: true)
            }
        default: break
        }
        trackingState = TrackStates.knobNoState.rawValue
    }

}

// MARK: -

class TwoPositionSwitchView: NSSlider {

    // MARK: - Internals
    
    fileprivate var isAnimating: Bool {
        return targetValue != doubleValue
    }
    var targetValue: Double = 0

    // MARK: - View Lifecycle
    
    required override init(frame frameRect: NSRect) {
        let name = "SwitchOverlayMask"
        let maskImage = NSImage(named: NSImage.Name(rawValue: name))!
        let rect = NSRect(x: 0, y: 0, width: maskImage.size.width, height: maskImage.size.height)
        super.init(frame: rect)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    fileprivate func commonInit() {
        doubleValue = 0.0
        minValue = 0.0
        maxValue = 1.0
        isContinuous = false
    }
    
    override class var cellClass: AnyClass? {
        // We want our cell to be custom.
        get {
            return TwoPositionSwitchCell.self
        }
        set {
            fatalError("Setter should not be called.")
        }
    }
    
    // Used to customize the animation duration of the knob across the switch track.
    override static func defaultAnimation(forKey key: NSAnimatablePropertyKey) -> Any? {
        if key.rawValue == "doubleValue" {
            return defaultAnimation(forKey: NSAnimatablePropertyKey(rawValue: "frameOrigin"))
        } else {
            return super.defaultAnimation(forKey: key)
        }
    }

    override var isFlipped: Bool {
        return false
    }
    
    fileprivate func setState(value: Int) {
        setState(value: value, animate: true)
    }
    
    fileprivate func setState(value: Int, animate: Bool) {
        let value = (value == NSControl.StateValue.on.rawValue) ? 1.0 : 0.0
        
        if value != targetValue {
            setDoubleValue(value: value, animate: animate)
        }
    }
    
    fileprivate var state: NSInteger {
        let targetValue = self.targetValue
        if targetValue == 0.0 {
            return NSControl.StateValue.off.rawValue
        } else if targetValue == 1.0 {
            return NSControl.StateValue.on.rawValue
        } else {
            return NSControl.StateValue.mixed.rawValue
        }
    }
    
    // MARK: - Keyboard Events
    
    // Set to allow keyDown, moveLeft, moveRight, etc. to be called.
    override var acceptsFirstResponder: Bool { return true }
    
    override func moveRight(_ sender: Any?) {
        if isEnabled {
            setDoubleValue(value: 1.0, animate:true)
            sendAction(action, to:target)
        }
    }
    
    override func moveLeft(_ sender: Any?) {
        if isEnabled {
            setDoubleValue(value: 0.0, animate:true)
            sendAction(action, to:target)
        }
    }
    
    override func moveUp(_ sender: Any?) {
        moveRight(sender)
    }
    
    override func moveDown(_ sender: Any?) {
        moveLeft(sender)
    }
    
    override func pageUp(_ sender: Any?) {
        moveRight(sender)
    }
    
    override func pageDown(_ sender: Any?) {
        moveLeft(sender)
    }
    
    fileprivate func setDoubleValue(value: Double, animate: Bool) {
        targetValue = value
        if doubleValue != value {
            if animate {
                NSAnimationContext.current.duration = 0.15 * abs(value - doubleValue)
                animator().doubleValue = value
            } else {
                doubleValue = value
            }
        }
    }

}

// MARK: -

extension TwoPositionSwitchView {
    
    // MARK: NSAccessibilitySwitch
    
    override func accessibilityValue() -> Any? {
        return integerValue == 0 ?
            NSLocalizedString("off", comment: "accessibility value for the state of OFF for the switch") :
            NSLocalizedString("on", comment: "accessibility value for the state of ON for the switch")
    }
    
    override func accessibilityLabel() -> String? {
        return NSLocalizedString("Switch", comment: "accessibility label of the two position switch")
    }
    
    override func accessibilityPerformPress() -> Bool {
        // User did control-option-space keyboard shortcut.
        let isStateOff = state == NSControl.StateValue.off.rawValue
        setState(value: isStateOff ? NSControl.StateValue.on.rawValue : NSControl.StateValue.off.rawValue)
        return true
    }
    
}
