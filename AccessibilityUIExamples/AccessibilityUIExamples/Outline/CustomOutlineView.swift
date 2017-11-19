/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller demonstrating an accessible, custom NSView subclass that behaves like a button.
*/

import Cocoa

/*
IMPORTANT: This is not a template for developing a custom outline view.
This sample is intended to demonstrate how to add accessibility to
existing custom controls that are not implemented using the preferred methods.
For information on how to create custom controls please visit http://developer.apple.com
 */

class CustomOutlineView: NSView {

    // MARK: - Internals
    
    fileprivate struct LayoutInfo {
        static let OutlineRowHeight = CGFloat(18.0)
        static let OutlineBorderLineWidth = CGFloat(2.0)
        static let OutlineIndentationSize = CGFloat(18.0)
    }
    
    fileprivate var rootNode = OutlineViewNode()
    fileprivate var mouseDownRow = 0
    fileprivate var mouseDownInDisclosureTriangle = false
    fileprivate var accessibilityRowElements = NSMutableDictionary()

    @objc var selectedRow: Int = 0 {
        didSet {
            let numVisibleRows = visibleNodes().count
            
            // Protect from of bounds selection.
            if selectedRow >= numVisibleRows {
                selectedRow = numVisibleRows - 1
            } else if selectedRow < 0 {
                selectedRow = 0
            }
            NSAccessibilityPostNotification(self, NSAccessibilityNotificationName.selectedRowsChanged)
        }
    }
    
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
        buildTree()
    }
    
    // MARK: - Content
    
    fileprivate func buildTree() {
        rootNode = OutlineViewNode.node(name: "")
        rootNode.expanded = true
        
        let nobleGas = rootNode.addChildNode(name: NSLocalizedString("Noble Gas", comment:""))
        nobleGas.expanded = true
        _ = nobleGas.addChildNode(name: NSLocalizedString("Neon", comment: ""))
        _ = nobleGas.addChildNode(name: NSLocalizedString("Helium", comment: ""))
        
        let semiMetal = rootNode.addChildNode(name: NSLocalizedString("Semi Metal", comment:""))
        semiMetal.expanded = true
        let boron = semiMetal.addChildNode(name: NSLocalizedString("Boron", comment: ""))
        let silicon = semiMetal.addChildNode(name: NSLocalizedString("Silicon", comment: ""))

        _ = boron.addChildNode(name: NumberFormatter.localizedString(from: NSNumber(value: 10.811), number: NumberFormatter.Style.decimal))
        _ = silicon.addChildNode(name: NumberFormatter.localizedString(from: NSNumber(value: 28.086), number: NumberFormatter.Style.decimal))
        
        accessibilityRowElements = NSMutableDictionary()
        selectedRow = 1
    }
    
    fileprivate func selectedNode() -> OutlineViewNode {
        return nodeAtRow(row: selectedRow)!
    }
    
    fileprivate func nodeAtRow(row: Int) -> OutlineViewNode? {
        if row >= 0 && row < visibleNodes().count {
            return visibleNodes()[row]
        }
        return nil
    }
    
    fileprivate func rowCount() -> Int {
        return visibleNodes().count
    }
    
    fileprivate func rowForPoint(point: NSPoint) -> Int {
        return Int(bounds.size.height - point.y - LayoutInfo.OutlineBorderLineWidth) / Int(LayoutInfo.OutlineRowHeight)
    }
    
    fileprivate func rowForNode(node: OutlineViewNode) -> Int {
        return visibleNodes().index(of: node)!
    }
    
    @objc
    func visibleNodes() -> [OutlineViewNode] {
        var visibleNodesToUse = [OutlineViewNode]()
        visibleNodesToUse.append(rootNode)
        
        var idx = 0
        while !visibleNodesToUse.isEmpty {
        var insertIndex = idx + 1
            
            if insertIndex > visibleNodesToUse.count {
                break
            }
            
            let node = visibleNodesToUse[idx]
            if (node as OutlineViewNode).expanded {
                for child in node.children {
                    if insertIndex < visibleNodesToUse.count {
                        visibleNodesToUse.insert(child, at: insertIndex)
                    } else {
                        visibleNodesToUse.append(child)
                    }
                    insertIndex += 1
                }
            }
            idx += 1
        }
        
        visibleNodesToUse.remove(at: 0)
        return visibleNodesToUse
    }
    
    // Area Measurements
    
    fileprivate func rectForRow(row: Int) -> NSRect {
        let rectBounds = bounds
        return NSRect(x: rectBounds.origin.x + LayoutInfo.OutlineBorderLineWidth,
                      y: rectBounds.size.height - LayoutInfo.OutlineRowHeight * CGFloat(row + 1) - (LayoutInfo.OutlineBorderLineWidth),
                      width: rectBounds.size.width - 2 * LayoutInfo.OutlineBorderLineWidth,
                      height: LayoutInfo.OutlineRowHeight)
    }

    fileprivate func textRectForRow(row: Int) -> NSRect {
        var textRect = NSRect.zero
        if let node = nodeAtRow(row: row) {
            let rowRect = rectForRow(row: row)
            textRect = NSRect(x: rowRect.origin.x + CGFloat(node.depth) * LayoutInfo.OutlineIndentationSize,
                              y: rowRect.origin.y,
                              width: rowRect.size.width,
                              height: rowRect.size.height)
        }
        return textRect
    }
    
    fileprivate func disclosureTriangleRectForRow(row: Int) -> NSRect {
        let textRect = textRectForRow(row: row)
        return NSRect(x: textRect.origin.x - LayoutInfo.OutlineIndentationSize + (LayoutInfo.OutlineBorderLineWidth * 1.5),
                      y: textRect.origin.y - LayoutInfo.OutlineBorderLineWidth,
                      width: LayoutInfo.OutlineIndentationSize,
                      height: textRect.size.height)
    }
    
    fileprivate func rect(row: Int) -> NSRect {
        let rowBounds = bounds
        return NSRect(x: rowBounds.origin.x + LayoutInfo.OutlineBorderLineWidth,
                      y: rowBounds.size.height - LayoutInfo.OutlineRowHeight * CGFloat(row + 1) - (LayoutInfo.OutlineBorderLineWidth),
                      width: rowBounds.size.width - 2 * LayoutInfo.OutlineBorderLineWidth,
                      height: LayoutInfo.OutlineRowHeight)
    }
    
    // MARK: - Expansion
    
    fileprivate func setExpandedStatus(expanded: Bool, node: OutlineViewNode) {
        if !node.children.isEmpty {
            node.expanded = expanded
            selectedRow = rowForNode(node: node)
            
            // Post a notification to let accessibility clients know a row has expanded or collapsed.
            // With a screen reader, for example, this could be announced as "row 1 expanded" or "row 2 collapsed"
            if node.expanded {
                NSAccessibilityPostNotification(accessibilityElementForNode(node: node), NSAccessibilityNotificationName.rowExpanded)
            } else {
                NSAccessibilityPostNotification(accessibilityElementForNode(node: node), NSAccessibilityNotificationName.rowCollapsed)
            }
            // Post a notification to let accessibility clients know the row count has changed.
            // With a screen reader, for example, this could be announced as "2 rows added".
            NSAccessibilityPostNotification(self, NSAccessibilityNotificationName.rowCountChanged)
        }
    }
    
    func setExpandedStatus(expanded: Bool, rowIndex: Int) {
        let node = nodeAtRow(row: rowIndex)
        if node?.expanded != expanded {
            setExpandedStatus(expanded: expanded, node: node!)
        }
    }
    
    override func keyDown(with event: NSEvent) {
        // We allow up/down arrow keys to change the current selection, left/right arrow keys to expand/collapse.
        guard event.modifierFlags.contains(.numericPad),
            let charactersIgnoringModifiers = event.charactersIgnoringModifiers, charactersIgnoringModifiers.characters.count == 1,
            let char = charactersIgnoringModifiers.characters.first
            else {
                super.keyDown(with: event)
                return
        }
                
        switch char {
        case Character(NSDownArrowFunctionKey)!:
            selectedRow += 1
        case Character(NSUpArrowFunctionKey)!:
            selectedRow -= 1
        case Character(NSLeftArrowFunctionKey)!, Character(NSRightArrowFunctionKey)!:
            toggleExpandedStatusForNode(node: selectedNode())
        default: break
        }
        needsDisplay = true
    }
    
    // MARK: - Drawing
    
    override func draw(_ dirtyRect: NSRect) {
        // Draw the outline background.
        NSColor.white.set()
        bounds.fill()
        
        // Draw the outline's background and border.
        let outline = NSBezierPath(rect: bounds)
        NSColor.white.set()
        outline.lineWidth = 2.0
        outline.fill()
        NSColor.lightGray.set()
        outline.stroke()
        
        // Draw the selected row.
        if selectedRow >= 0 {
            // Decide the fill color based on first responder status.
            let fillColor = window?.firstResponder == self ? NSColor.alternateSelectedControlColor : NSColor.secondarySelectedControlColor
            fillColor.set()
            let rowRect = rectForRow(row: selectedRow)
            rowRect.fill()
        }
        
        // Draw each row item.
        for rowidx in 0..<visibleNodes().count {
            // Draw the row text.
            let node = visibleNodes()[rowidx]
            let textRect = textRectForRow(row: rowidx)
            
            // Choose the right color based on first responder status and the selected row.
            let textColor = (window?.firstResponder == self && selectedRow == rowidx) ? NSColor.white : NSColor.black
            
            let textAttributes = [ NSAttributedStringKey.font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
                                   NSAttributedStringKey.foregroundColor: textColor ]
            node.name.draw(in: textRect, withAttributes:textAttributes)
            
            // Draw the row disclosure triangle.
            if !node.children.isEmpty {
                let disclosureRect = disclosureTriangleRectForRow(row: rowidx)
                let disclosureText = node.expanded ? "▼" : "►"
                disclosureText.draw(in: disclosureRect, withAttributes:nil)
            }
        }
    }

    // MARK: - Events
    
    // Used by accessibilityPerformPress or mouseUp functions to change the expanded state of each outline item.
    fileprivate func toggleExpandedStatusForNode(node: OutlineViewNode) {
        setExpandedStatus(expanded: !node.expanded, node: node)
    }
    
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        mouseDownRow = rowForPoint(point: point)
        let disclosureTriangleRect = disclosureTriangleRectForRow(row: mouseDownRow)
        mouseDownInDisclosureTriangle = disclosureTriangleRect.contains(point)
    }
    
    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let mouseUpRow = rowForPoint(point: point)
        if mouseDownRow == mouseUpRow {
            let disclosureTriangleRect = disclosureTriangleRectForRow(row: mouseUpRow)
            let isMouseUpInDisclosureTriangle = disclosureTriangleRect.contains(point)
            
            if mouseDownInDisclosureTriangle && isMouseUpInDisclosureTriangle {
                let selectedNode = nodeAtRow(row: mouseUpRow)
                toggleExpandedStatusForNode(node: selectedNode!)
            } else {
                selectedRow = mouseUpRow
            }
            needsDisplay = true
        }
    }
    
}

// MARK: -

extension CustomOutlineView {
    
    // MARK: First Responder

    // Set to allow keyDown to be called.
    override var acceptsFirstResponder: Bool { return true }
    
    override func becomeFirstResponder() -> Bool {
        let didBecomeFirstResponder = super.becomeFirstResponder()
        if didBecomeFirstResponder {
            setKeyboardFocusRingNeedsDisplay(bounds)
        }
        needsDisplay = true
        return didBecomeFirstResponder
    }
    
    override func resignFirstResponder() -> Bool {
        let didResignFirstResponder = super.resignFirstResponder()
        if didResignFirstResponder {
            setKeyboardFocusRingNeedsDisplay(bounds)
        }
        needsDisplay = true
        return didResignFirstResponder
    }
}

// MARK: -

extension CustomOutlineView {
    
    // MARK: Accessibility Utilities
    
    @objc
    func accessibilityElementForNode(node: OutlineViewNode) -> NSAccessibilityElement {
        var rowElement = CustomOutlineViewAccessibilityRowElement()
        
        if let rowElementTarget = accessibilityRowElements[node] {
            guard let rowElementCheck = rowElementTarget as? CustomOutlineViewAccessibilityRowElement else { return rowElement }
            rowElement = rowElementCheck
        } else {
            rowElement = CustomOutlineViewAccessibilityRowElement()
            rowElement.setAccessibilityParent(self)
            accessibilityRowElements[node] = rowElement
        }
        
        let row = rowForNode(node: node)
        let rowRect = rect(row: row)
        let disclosureTriangleRect = disclosureTriangleRectForRow(row: row)
        let disclosureTriangleCenterPoint = NSPoint(x: disclosureTriangleRect.midX, y: disclosureTriangleRect.midY)
        
        rowElement.setAccessibilityLabel(node.name)
        rowElement.setAccessibilityFrameInParentSpace(rowRect)
        rowElement.setAccessibilityIndex(row)
        rowElement.setAccessibilityDisclosed(node.expanded)
        rowElement.setAccessibilityDisclosureLevel(node.depth)
        rowElement.disclosureTriangleCenterPoint = disclosureTriangleCenterPoint
        rowElement.canDisclose = !node.children.isEmpty
                
        return rowElement
    }

    // MARK: NSAccessibility

    override func accessibilityLabel() -> String? {
        return NSLocalizedString("chemical property", comment: "accessibility label for the outline")
    }

    override func accessibilityPerformPress() -> Bool {
        // User did control-option-space keyboard shortcut.
        toggleExpandedStatusForNode(node: selectedNode())
        needsDisplay = true
        return true
    }

}

