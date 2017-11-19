/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example demonstrating the preferred method of making an accessible,
 custom button by subclassing NSButton and implementing the NSAccessibilityButton protocol.
*/

import Cocoa

// Note that NSButton already conforms to protocol "NSAccessibilityButton".
class CustomButton: NSButton {

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
        image = NSImage(named: NSImage.Name(rawValue: ButtonImages.buttonUp))
        alternateImage = NSImage(named: NSImage.Name(rawValue: ButtonImages.buttonDown))
        
        // Track the mouse for enter and exit for proper highlighting.
        let trackingArea = NSTrackingArea(rect: bounds,
                                          options: [NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited],
                                          owner: self,
                                          userInfo: nil)
        addTrackingArea(trackingArea)
    }
    
    // MARK: - Mouse events
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        image = NSImage(named: NSImage.Name(rawValue: ButtonImages.buttonHighlight))
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        image = NSImage(named: NSImage.Name(rawValue: ButtonImages.buttonUp))
    }
    
}

// MARK: - NSAccessibilityButton

extension CustomButton {
    
    /// - Tag: accessibilityLabel
    override func accessibilityLabel() -> String? {
        return NSLocalizedString("Play", comment: "accessibility label of the Play button")
    }
    
    override func accessibilityHelp() -> String {
        return NSLocalizedString("Increase press count.", comment: "accessibility help of the Play button")
    }
    
    // MARK: NSAccessibility
    
    override func accessibilityPerformPress() -> Bool {
        // User did control-option-space keyboard shortcut.
        performClick(nil)
        return true
    }
    
}

