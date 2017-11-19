/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example demonstrating adding accessibility to a view that serves to layout UIs by implementing the NSAccessibilityLayoutArea protocol.
*/

import Cocoa

/*
 IMPORTANT: This is not a template for developing a custom control.
 This sample is intended to demonstrate how to add accessibility to
 existing custom controls that are not implemented using the preferred methods.
 For information on how to create custom controls please visit http://developer.apple.com
*/

// Used to iterate over the HandlePosition values.
protocol HandleCollection: Hashable {}
extension HandleCollection {
    static func cases() -> AnySequence<Self> {
        typealias Myself = Self
        return AnySequence { () -> AnyIterator<Myself> in
            var rawValue = 0
            return AnyIterator {
                let current: Self = withUnsafePointer(to: &rawValue) { $0.withMemoryRebound(to: Myself.self, capacity: 1) { $0.pointee } }
                guard current.hashValue == rawValue else { return nil }
                rawValue += 1
                return current
            }
        }
    }
}

class CustomLayoutAreaView: NSView, NSAccessibilityLayoutArea {

    // MARK: - Internals
    
    struct LayoutInfo {
        static let LayoutItemHandleSize = CGFloat(8.0)
        static let LayoutItemMinSize = CGFloat(LayoutItemHandleSize * 3.0)
        static let LayoutItemMoveDelta = CGFloat(10.0)
        static let LayoutItemSize = CGFloat(50.0)
    }
    
    enum HandlePosition: HandleCollection {
        case unknown
        case north
        case northEast
        case east
        case southEast
        case south
        case southWest
        case west
        case northWest
    }
    
    var layoutItems = [LayoutItem]()
    var layoutItemsNeedOrdering = false
    
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
        let rectangleA = LayoutItem()
        rectangleA.setAccessibilityParent(self)
        rectangleA.bounds = NSRect(x: 0, y: 0, width: LayoutInfo.LayoutItemSize, height: LayoutInfo.LayoutItemSize)
        rectangleA.setAccessibilityLabel(NSLocalizedString("Rectangle A",
                                                           comment: "accessibility layout for the first layout item"))
        layoutItems.append(rectangleA)
        
        let rectangleB = LayoutItem()
        rectangleB.setAccessibilityParent(self)
        rectangleB.bounds = NSRect(x: 75, y: 75, width: LayoutInfo.LayoutItemSize, height: LayoutInfo.LayoutItemSize)
        
        rectangleB.setAccessibilityLabel(NSLocalizedString("Rectangle B",
                                                           comment: "accessibility label for the second layout item"))
        layoutItems.append(rectangleB)
    }
    
    // MARK: - Layout Item Management
    
    var selectedLayoutItemIndex: Int = -1 {
        didSet {
            if (selectedLayoutItemIndex >= layoutItems.count) || (selectedLayoutItemIndex < 0) {
                selectedLayoutItemIndex = -1
            } else {
                bringItemToTop(itemIndex: selectedLayoutItemIndex)
            }
            NSAccessibilityPostNotification(self, NSAccessibilityNotificationName.focusedUIElementChanged)
            needsDisplay = true
        }
    }
    
    var selectedLayoutItem: LayoutItem? {
        didSet {
            guard selectedLayoutItem != nil else { return }
            
            if let itemIndex = layoutItems.index(of: selectedLayoutItem!) {
                let newItemIndex = (itemIndex != NSNotFound) ? itemIndex : -1
                selectedLayoutItemIndex = newItemIndex
            }
        }
    }
    
    fileprivate func layoutItemsInZOrder() -> [LayoutItem] {
        _ = layoutItems.sorted(by: { $0.zOrder > $1.zOrder })
        return layoutItems
    }
 
    fileprivate func bringItemToTop(itemIndex: Int) {
        if itemIndex >= 0 && itemIndex < layoutItems.count {
            var zOrder = 0
            for layoutItem in layoutItemsInZOrder() {
                layoutItem.zOrder = zOrder
                zOrder += 1
            }
        }
    }

    // MARK: - Keyboard Events
    
    fileprivate func handleArrowKeys(with event: NSEvent) {
        // We allow up/down arrow keys to change the current selection, left/right arrow keys to expand/collapse.
        guard event.modifierFlags.contains(.numericPad),
            let charactersIgnoringModifiers = event.charactersIgnoringModifiers, charactersIgnoringModifiers.characters.count == 1,
            let char = charactersIgnoringModifiers.characters.first
            else {
                super.keyDown(with: event)
                return
        }
        
        let layoutItem = layoutItems[selectedLayoutItemIndex]
        var bounds = layoutItem.bounds
        
        switch char {
        case Character(NSDownArrowFunctionKey)!:
            bounds.origin.y -= LayoutInfo.LayoutItemMoveDelta
        case Character(NSUpArrowFunctionKey)!:
            bounds.origin.y += LayoutInfo.LayoutItemMoveDelta
        case Character(NSLeftArrowFunctionKey)!:
            bounds.origin.x -= LayoutInfo.LayoutItemMoveDelta
        case Character(NSRightArrowFunctionKey)!:
            bounds.origin.x += LayoutInfo.LayoutItemMoveDelta
        default: break
        }
        
        if !(bounds == layoutItem.bounds) {
            layoutItem.bounds = bounds
        }

        needsDisplay = true
    }
    
    override func keyDown(with event: NSEvent) {
        guard let charactersIgnoringModifiers = event.charactersIgnoringModifiers, charactersIgnoringModifiers.characters.count == 1,
              let char = charactersIgnoringModifiers.characters.first
        else {
            super.keyDown(with: event)
            return
        }
        switch char {
        case Character(NSTabCharacter)!:
            if selectedLayoutItemIndex < (NSInteger)(layoutItems.count - 1) {
                selectedLayoutItemIndex += 1
            }
        case Character(NSBackTabCharacter)!: // Shift-tab
            if selectedLayoutItemIndex > 0 {
                selectedLayoutItemIndex -= 1
            }
        default:
            handleArrowKeys(with: event)
            break
        }
        needsDisplay = true
    }
    
    // MARK: - Mouse Events
    
    fileprivate func hitTestForLayoutItemAtPoint(point: NSPoint) -> LayoutItem? {
        // Look for any layout item under the mouse click.
        for layoutItem in layoutItemsInZOrder() {
            if layoutItem.bounds.contains(point) {
                // Found a layout item the mouse clicked on.
                return layoutItem
            }
        }
        return nil
    }
    
    fileprivate func hitTestForHandleAtPoint(point: NSPoint) -> HandlePosition {
        var hitTestHandle: HandlePosition = .unknown
    
        if selectedLayoutItemIndex >= 0 {
            let cases = Array(HandlePosition.cases())
            for position in cases {
                let handleRect = handleRectForItemIndex(itemIndex: selectedLayoutItemIndex,
                                                        position: position)
                if handleRect.contains(point) {
                    hitTestHandle = position
                    break
                }
            }
        }
        
        return hitTestHandle
    }
    
    override func mouseDown(with event: NSEvent) {
        let mouseDownPoint = convert(event.locationInWindow, from: nil)
        
        var currentSelectedlayoutItem = selectedLayoutItem
        let selectedHandlePosition = hitTestForHandleAtPoint(point: mouseDownPoint)
        if selectedHandlePosition == .unknown {
            currentSelectedlayoutItem = hitTestForLayoutItemAtPoint(point: mouseDownPoint)
            selectedLayoutItem = currentSelectedlayoutItem
        }
        
        var deltaX = CGFloat(0)
        var deltaY = CGFloat(0)
        let bounds = selectedLayoutItem?.bounds

        var currentEvent = event
        let eventMask: NSEvent.EventTypeMask = [NSEvent.EventTypeMask.leftMouseUp, NSEvent.EventTypeMask.leftMouseDragged]
        let untilDate = NSDate.distantFuture

        var stop = false
        repeat {
            var mousePoint = convert(currentEvent.locationInWindow, from: nil)
            
            switch currentEvent.type {
            case NSEvent.EventType.leftMouseDown, NSEvent.EventType.leftMouseDragged:
                // User dragged a layout item.
                mousePoint = convert(currentEvent.locationInWindow, from: nil)
                deltaX = mousePoint.x - mouseDownPoint.x
                deltaY = mousePoint.y - mouseDownPoint.y
                
                selectedLayoutItem?.bounds = rectForLayoutItem(rect: bounds!, handle: selectedHandlePosition, deltaX: deltaX, deltaY: deltaY)
                
                // As the user keeps dragging the mouse get the next event.
                currentEvent =
                    (window?.nextEvent(matching: eventMask, until: untilDate, inMode: RunLoopMode.eventTrackingRunLoopMode, dequeue: true))!
            default:
                // User stopped tracking the layout item.
                stop = true
                break
            }
            display()
        }
        while !stop
    }
    
    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        if window?.firstResponder != self {
            selectedLayoutItemIndex = -1
        }
        
        // Draw the layout area's background and border.
        let outline = NSBezierPath(rect: bounds)
        NSColor.white.set()
        outline.lineWidth = 2.0
        outline.fill()
        NSColor.lightGray.set()
        outline.stroke()
        
        let interimArray = NSArray(array: layoutItemsInZOrder())
        let enumerator = interimArray.reverseObjectEnumerator()
        let items = enumerator.allObjects
        for case let layoutItem as LayoutItem in items {
            let itemPath = NSBezierPath(rect: layoutItem.bounds)
            NSColor.blue.set()
            itemPath.fill()
            NSColor.black.set()
            itemPath.stroke()
        }
        
        // Draw all the layout item handles.
        let iterIdx = selectedLayoutItemIndex
        if iterIdx >= 0 {
            let handles = Array(HandlePosition.cases())
            
            for position in handles {
                let handleRect =
                    handleRectForItemIndex(itemIndex: selectedLayoutItemIndex, position: position)
                let handlePath = NSBezierPath(rect: handleRect)
                NSColor.gray.set()
                handlePath.fill()
                NSColor.black.set()
            }
        }
    }
}

// MARK: -

extension CustomLayoutAreaView {
    
    // MARK: First Responder
    
    // Set to allow keyDown, moveLeft, moveRight to be called.
    override var acceptsFirstResponder: Bool { return true }
    
    override func becomeFirstResponder() -> Bool {
        let didBecomeFirstResponder = super.becomeFirstResponder()
        if didBecomeFirstResponder {
            setKeyboardFocusRingNeedsDisplay(bounds)
            
            // If user is tabbing through the key loop and that's how this element became first responder,
            // select the first or last layout item depending on the direction of motion through the key loop.
            let event = NSApp.currentEvent
            if event?.type == NSEvent.EventType.keyDown {
                guard let charactersIgnoringModifiers = event?.charactersIgnoringModifiers, charactersIgnoringModifiers.characters.count == 1,
                    let char = charactersIgnoringModifiers.characters.first else { return true }
                switch char {
                case Character(NSBackTabCharacter)!: // Shift-tab
                    if selectedLayoutItemIndex > 0 {
                        selectedLayoutItemIndex -= 1
                    }
                default: break
                }
            }
        }
        return didBecomeFirstResponder
    }
    
    override func resignFirstResponder() -> Bool {
        let didResignFirstResponder = super.resignFirstResponder()
        if didResignFirstResponder {
            setKeyboardFocusRingNeedsDisplay(bounds)
            selectedLayoutItemIndex = -1
            needsDisplay = true
        }
        return didResignFirstResponder
    }
}

// MARK: -

extension CustomLayoutAreaView {
    
    // MARK: NSAccessibilityLayoutArea
    
    override var accessibilityFocusedUIElement: Any {
        if let accessibilityFocusedUIElement = selectedLayoutItem {
            return accessibilityFocusedUIElement
        } else {
            return super.accessibilityFocusedUIElement!
        }
    }
    
    override func accessibilityLabel() -> String {
        return NSLocalizedString("Rectangles", comment: "accessibility label for the layout area")
    }
    
    override func accessibilityChildren() -> [Any]? {
        return layoutItems
    }
    
    override func accessibilitySelectedChildren() -> [Any]? {
        if let selectedItem = selectedLayoutItem {
            let accessibilitySelectedChildren: [LayoutItem] = [selectedItem]
            return accessibilitySelectedChildren
        }
        return super.accessibilitySelectedChildren()
    }
}

