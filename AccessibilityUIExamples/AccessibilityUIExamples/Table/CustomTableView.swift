/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example demonstrating adding accessibility to an NSView subclass that behaves
 like a table by implementing the NSAccessibilityTable protocol and using NSAccessibilityElement.
*/

import Cocoa

/*
IMPORTANT: This is not a template for developing a custom table.
This sample is intended to demonstrate how to add accessibility to
existing custom controls that are not implemented using the preferred methods.
For information on how to create custom controls please visit http://developer.apple.com
*/

class CustomTableView: NSView {

    // MARK: - Internals

    @objc static let TableRowCount = 6
    @objc static let TableColumnCount = 4
    static let TableOutlineWidth = CGFloat(4.0)
    static let TableGridWidth = CGFloat(1.0)
    
    @objc var tableData = [Any]()
    @objc var ourAccessibilityRows = [NSAccessibilityElement]()
    
    fileprivate var mouseDownRow = 0
    
    @objc var selectedRow: Int = 0 {
        didSet {
            let numRows = CustomTableView.TableRowCount
            
            // Protect from of bounds selection.
            if selectedRow >= numRows {
                selectedRow = numRows - 1
            } else if selectedRow < 0 {
                selectedRow = 0
            }
            needsDisplay = true
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
        buildTable()
        selectedRow = 1
    }
    
    // MARK: - Content
    
    fileprivate func buildTable () {
        var rows = [Any]()
        
        for row in 0..<CustomTableView.TableRowCount {
            var cols = [String]()
            for col in 0..<CustomTableView.TableColumnCount {
                if row == 0 && col == 0 {
                    cols.append(NSLocalizedString("Table",
                                                  comment: "text for the top left corner cell of the table"))
                } else if row == 0 {
                    let title =
                        String.localizedStringWithFormat(
                            NSLocalizedString("ColumnFormatter",
                                              comment:"text for the table column cells"), col)
                    cols.append(title)
                } else if col == 0 {
                    let title =
                        String.localizedStringWithFormat(
                            NSLocalizedString("RowFormatter",
                                              comment:"text for the table row cells"), row)
                    cols.append(title)
                } else {
                    let title =
                        String.localizedStringWithFormat(
                            NSLocalizedString("CellFormatter",
                                              comment:"text for a table cell"), (row * (CustomTableView.TableColumnCount - 1)) + col)
                    cols.append(title)
                }
            }
            rows.append(cols)
        }
        tableData = rows
    }
    
    // Area Measurements
    
    @objc
    func rect(row: Int) -> NSRect {
        let rectBounds = bounds
        return NSRect(x: 0,
                      y: CGFloat((CustomTableView.TableRowCount - row - 1)) * (rectBounds.size.height / CGFloat(CustomTableView.TableRowCount)),
                      width: rectBounds.size.width,
                      height: rectBounds.size.height / CGFloat(CustomTableView.TableRowCount))
    }
    
    fileprivate func rect(row: Int, column: Int) -> NSRect {
        let rectBounds = bounds
        return NSRect(x: CGFloat(column) * (rectBounds.size.width / CGFloat(CustomTableView.TableColumnCount)),
                      y: CGFloat((CustomTableView.TableRowCount - row - 1)) * (rectBounds.size.height / CGFloat(CustomTableView.TableRowCount)),
                      width: (rectBounds.size.width / CGFloat(CustomTableView.TableColumnCount)),
                      height: rectBounds.size.height / CGFloat(CustomTableView.TableRowCount))
    }
    
    @objc
    func rectForCellInRowCoords(row: Int, column: Int) -> NSRect {
        let rowRect = rect(row: row)
        let cellRect = rect(row: row, column: column)
        
        return NSRect(x: cellRect.origin.x - rowRect.origin.x,
                      y: cellRect.origin.y - rowRect.origin.y,
                      width: cellRect.size.width,
                      height: cellRect.size.height)
    }
    
    fileprivate func row(point: NSPoint) -> Int {
        let row = CustomTableView.TableRowCount - Int(point.y / (bounds.size.height / CGFloat(CustomTableView.TableRowCount))) - 1
        return row
    }

    // MARK: - Mouse Events
    
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        mouseDownRow = row(point: point)
    }
    
    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let mouseUpRow = row(point: point)
        if mouseDownRow == mouseUpRow {
            selectedRow = mouseUpRow
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
        switch char {
        case Character(NSDownArrowFunctionKey)!:
            selectedRow += 1
        case Character(NSUpArrowFunctionKey)!:
            selectedRow -= 1
        default: break
        }
    }
    
    // MARK: - Drawing
    
    fileprivate func drawGridPaths(topLeft: NSPoint, topRight: NSPoint, bottomLeft: NSPoint) {
        // Define the table grid path.
        NSColor.lightGray.set()
        
        let grid = NSBezierPath()
        
        // Draw the horizontal grid lines.
        for row in 0..<CustomTableView.TableRowCount {
            var lineStart = topLeft
            var lineEnd = topRight
            lineStart.y = (CGFloat(row) * (bounds.size.height / CGFloat(CustomTableView.TableRowCount)))
            lineEnd.y = lineStart.y
            grid.move(to: lineStart)
            grid.line(to: lineEnd)
        }
        
        // Draw the vertical grid lines.
        for col in 0..<CustomTableView.TableColumnCount {
            var lineStart = topLeft
            var lineEnd = bottomLeft
            lineStart.x = (CGFloat(col) * (bounds.size.width / CGFloat(CustomTableView.TableColumnCount)))
            lineEnd.x = lineStart.x
            grid.move(to: lineStart)
            grid.line(to: lineEnd)
        }
        grid.lineWidth = CustomTableView.TableGridWidth
        grid.stroke()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        // Draw the outline background.
        NSColor.white.set()
        bounds.fill()
        
        guard !tableData.isEmpty else { return }
        
        // Draw the selected row highlights.
        if selectedRow >= 0 {
            for col in 0..<CustomTableView.TableColumnCount {
                // Choose the right color based on our first responder status.
                let color = window?.firstResponder == self ? NSColor.alternateSelectedControlColor : NSColor.secondarySelectedControlColor
                color.set()
                
                let rowRect = rect(row: selectedRow, column: col)
                rowRect.fill()
            }
        }
        
        // Draw the table's border.
        let outline = NSBezierPath(rect: bounds)
        NSColor.white.set()
        outline.lineWidth = 2.0
        NSColor.black.set()
        outline.stroke()

        // Draw the table grid, first define the corners of the table.
        let topLeft = NSPoint(x: bounds.minX, y: bounds.maxY)
        let topRight = NSPoint(x: bounds.maxX, y: bounds.maxY)
        let bottomLeft = NSPoint(x: bounds.minX, y: bounds.minY)
        drawGridPaths(topLeft: topLeft, topRight: topRight, bottomLeft: bottomLeft)
        
        // Draw the cell text.
        let style = NSMutableParagraphStyle()
        style.alignment = NSTextAlignment.center
        
        let textAttributes = [
            NSAttributedStringKey.paragraphStyle: style,
            NSAttributedStringKey.font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
        ] as [NSAttributedStringKey : Any]
        let boldTextAttributes = [
            NSAttributedStringKey.paragraphStyle: style,
            NSAttributedStringKey.font: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        ] as [NSAttributedStringKey : Any]

        for row in 0..<CustomTableView.TableRowCount {
            if let rowData = tableData[row] as? [String] {
                for col in 0..<CustomTableView.TableColumnCount {
                    let cellText = rowData[col]
                    
                    var cellRect = rect(row: row, column: col)
                    cellRect.origin.y = ceil(cellRect.origin.y - 5)
                    
                    // Draw the text of header column and row cells in bold.
                    if row == 0 || col == 0 {
                        cellText.draw(in: cellRect, withAttributes: boldTextAttributes)
                    } else {
                        cellText.draw(in: cellRect, withAttributes: textAttributes)
                    }
                }
            }
        }
    }
    
}

// MARK: -

extension CustomTableView {
    
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

extension CustomTableView {
    
    // MARK: NSAccessibility
    
    override func accessibilityLabel() -> String? {
        return NSLocalizedString("Basic Table", comment: "accessibility label for a basic table")
    }

}

