/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example demonstrating adding accessibility to an NSView subclass that draws columns of text
 using CoreText by implementing the NSAccessibilityNavigableStaticText protocol.
*/

import Cocoa
import CoreText

/*
 IMPORTANT: This is not a template for developing a custom control.
 This sample is intended to demonstrate how to add accessibility to
 existing custom controls that are not implemented using the preferred methods.
 For information on how to create custom controls please visit http://developer.apple.com
*/

class CoreTextColumnView: NSView {

    // MARK: - Internals
    
    fileprivate var framesetter: CTFramesetter?
    @nonobjc var textFrames = [CTFrame]()
    
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
        attributedString = NSMutableAttributedString(string: NSLocalizedString("LongSampleText", comment: "Long sample text"))
        attributedString.setAlignment(NSTextAlignment.justified, range: NSRange(location: 0, length: attributedString.length))
        
        framesetter = CTFramesetterCreateWithAttributedString(attributedString)
    
        resetColumns()
    }
    
    var attributedString: NSMutableAttributedString! {
        didSet {
            // Re-draw the view if the input string changes.
            needsDisplay = true
        }
    }
    
    // MARK: - Layout
    
    fileprivate struct Columns {
        static let ColumnCountMin = 1
        static let ColumnCountMax = 2
    }
    
    fileprivate var columnCount: Int = Columns.ColumnCountMax {
        didSet {
            resetColumns()
            needsDisplay = true
        }
    }
    
    fileprivate var columnRects: [CGRect] {
        var columnRects = [CGRect]()
        
        // Start by setting the first column to cover the entire view.
        let columnWidth = bounds.width / CGFloat(columnCount)
        
        // Divide the columns equally across the frame's width.
        let (slice, remainder) = bounds.divided(atDistance: columnWidth, from: .minXEdge)
        columnRects.append(slice)
        columnRects.append(remainder)
        
        // Inset all columns by a few pixels of margin.
        for column in 0..<columnCount {
            columnRects[column] = columnRects[column].insetBy(dx: 10.0, dy: 10.0)
        }
        
        return columnRects
    }
  
    fileprivate func resetColumns() {
        var startIndex = 0
        var localFrames = [CTFrame]()

        for column in 0..<columnCount {
            // Create frame with rect path.
            let path = CGMutablePath()
            let transform = CGAffineTransform(translationX: 0, y: 0)
            path.addRect(columnRects[column], transform: transform)
            let frame: CTFrame = CTFramesetterCreateFrame(framesetter!, CFRangeMake(startIndex, 0), path, nil)
            localFrames.append(frame)
 
            // Start the next frame at the first character not visible in this frame.
            let frameRange = CTFrameGetVisibleStringRange(frame)
            startIndex += frameRange.length
        }
        
        // Update our array of frames.
        textFrames = localFrames
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        // First draw the background.
        let cgContext = NSGraphicsContext.current?.cgContext
        
        let path = CGMutablePath()
        path.addRect(dirtyRect)
        cgContext?.addPath(path)
        NSColor.white.setFill()
        cgContext?.drawPath(using: .fillStroke)
        
        for column in 0..<textFrames.count {
            let frame = textFrames[column]
            CTFrameDraw(frame, cgContext!)
        }
    }
    
    // MARK: - Actions
    
    fileprivate func changeLayout () {
        if columnCount == Columns.ColumnCountMax {
            columnCount = Columns.ColumnCountMin
        } else {
            columnCount += 1
        }
    }
    
    // MARK: - Events
    
    override var acceptsFirstResponder: Bool { return true }
    
    override func mouseDown(with event: NSEvent) {
        changeLayout()
    }
    
}

// MARK: - Accessibility Utilities

extension CoreTextColumnView {
    
    fileprivate func resultBounds(range: NSRange, startLineIdx: Int, endLineIdx: Int, startLineColumnIdx: Int, endLineColumnIdx: Int) -> NSRect {
        var returnValue = NSRect.zero
    
        if startLineIdx != NSNotFound {
            // Combine bounds rects for each line.
            for currentColumn in startLineColumnIdx...endLineColumnIdx {
                let startLine = currentColumn == startLineColumnIdx ? startLineIdx : 0
                var endLine = 0
                
                if currentColumn == endLineColumnIdx {
                    endLine = endLineIdx
                } else {
                    if currentColumn == textFrames.count {
                        // We are out of bounds in the number of frames, so end accomulating the returnValue.
                        break
                    }
                    let lines = CTFrameGetLines(textFrames[currentColumn])
                    let lineCount = CFArrayGetCount(lines)
                    endLine = lineCount - 1
                }
                
                for currentLine in startLine...endLine {
                    let lineBoundsForRange = accessibleBounds(for: range, columnIdx: currentColumn, lineIdx: currentLine)
                    
                    returnValue = NSUnionRect(returnValue, lineBoundsForRange)
                }
            }
        }
        
        return returnValue
    }
    
    fileprivate func accessibleBounds(for range: NSRange) -> NSRect {
        // Find lines at start and end of range.
        var startLineColumnIdx = NSNotFound
        var endLineColumnIdx = NSNotFound
        var startLineIdx = NSNotFound
        var endLineIdx = NSNotFound
        var characterIndexSought = range.location
        
        for columnIndex in 0..<textFrames.count {
            let currentFrame = textFrames[columnIndex]
            if let lines = CTFrameGetLines(currentFrame) as? [CTLine] {
                for lineIndex in 0..<lines.count {
                    let currentLine = lines[lineIndex]
                    
                    let lineRange = CTLineGetStringRange(currentLine)
                    
                    let characterInLineRange = characterIndexSought - lineRange.location < lineRange.length
                    if characterInLineRange {
                        if startLineIdx == NSNotFound {
                            // Found the first line.
                            startLineColumnIdx = columnIndex
                            startLineIdx = lineIndex
                            
                            let lastCharInLine = lineRange.location + lineRange.length
                            if lastCharInLine >= NSMaxRange(range) {
                                // The entire range is contained in this line. We're done.
                                endLineColumnIdx = columnIndex
                                endLineIdx = lineIndex
                                break
                            } else {
                                // Continue search for end line since range extends beyond this one.
                                characterIndexSought = NSMaxRange(range)
                            }
                        } else {
                            endLineColumnIdx = columnIndex
                            endLineIdx = lineIndex
                            break
                        }
                    }
                }
            }
            
            if startLineIdx != NSNotFound && endLineIdx != NSNotFound {
                break
            }
        }
        
        return resultBounds(range : range,
                            startLineIdx : startLineIdx, endLineIdx : endLineIdx,
                            startLineColumnIdx : startLineColumnIdx, endLineColumnIdx : endLineColumnIdx)
    }

    fileprivate func accessibleBounds(for range: NSRange, columnIdx: Int, lineIdx: Int) -> NSRect {
        var resultRect = NSRect.zero
        
        let frame = textFrames[columnIdx]
        guard let lines = CTFrameGetLines(frame) as? [CTLine] else { return resultRect }
        let line = lines[lineIdx]
        
        // Looking for bounds of range that fall within this line.
        let lineRange = CTLineGetStringRange(line)
        
        let rangeWithinLine = NSIntersectionRange(range, NSRange(location: lineRange.location, length: lineRange.length))
        
        // Find origin of line relative to frame.
        var lineOrigins = [CGPoint] (repeating: .zero, count: 1)
        let lineFrame = textFrames[columnIdx]
        CTFrameGetLineOrigins(lineFrame, CFRange (location: lineIdx, length: 1), &lineOrigins)
        let lineOrigin = lineOrigins[0]
        
        // Find horizontal pixel offsets of range within line.
        let rangeXOffset = CTLineGetOffsetForStringIndex(line, rangeWithinLine.location, nil)
        
        // Calculate line height.
        var ascent = CGFloat(0.0)
        var descent = CGFloat(0.0)
        var leading = CGFloat(0.0)
        CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
        let lineHeight = ascent + descent + leading
        
        // Calculate range width.
        let leftMargin = CTLineGetOffsetForStringIndex(line, rangeWithinLine.location, nil)
        let rightMargin = CTLineGetOffsetForStringIndex(line, NSMaxRange(rangeWithinLine), nil)
        let rangeWidth = rightMargin - leftMargin
        
        // Put it all together.
        let frameOrigin = columnRects[columnIdx].origin
        let xPos = frameOrigin.x + lineOrigin.x + rangeXOffset
        let yPos = frameOrigin.y + lineOrigin.y
        let rangeRect = NSRect(x: xPos, y: yPos, width: rangeWidth, height: lineHeight)
        let windowRect = convert(rangeRect, to: nil)
        resultRect = (window?.convertToScreen(windowRect))!
        
        return resultRect
    }

    fileprivate func attributedString(for range: NSRange) -> NSAttributedString {
        var value = NSAttributedString()
        
        if NSMaxRange(range) <= (attributedString?.length)! {
            value = attributedString.attributedSubstring(from: range)
        }
        
        return value
    }

    fileprivate func string(for range: NSRange) -> String {
        return attributedString(for: range).string
    }

    fileprivate func range(for line: Int) -> NSRange {
        var rangeForLine = NSRange(location: NSNotFound, length: 0)
        var absoluteLineNumber = 0
        
        for columnIndex in 0..<textFrames.count {
            let currentFrame = textFrames[columnIndex]
            guard let lines = CTFrameGetLines(currentFrame) as? [CTLine] else { return rangeForLine }
            
            let lineCount = lines.count
            
            // Skip to next frame.
            if absoluteLineNumber + lineCount <= line {
                absoluteLineNumber += 1
                continue
            } else {
                // Line lives within this frame if the text is long enough.
                let relativeIndex = line - absoluteLineNumber
                if relativeIndex < lineCount {
                    let currentLine = lines[relativeIndex]
                    
                    let lineRange = CTLineGetStringRange(currentLine)
                    rangeForLine = NSRange(location: lineRange.location, length: lineRange.length)
                }
                break
            }
        }
        return rangeForLine
    }

    fileprivate func line(for index: Int) -> Int {
        var lineForIndex = NSNotFound
        var absoluteLineNumber = 0  // Current line, across columns.
        
        for columnIndex in 0..<textFrames.count {
            let currentFrame = textFrames[columnIndex]
            if let lines = CTFrameGetLines(currentFrame) as? [CTLine] {
                for lineIndex in 0..<lines.count {
                    let currentLine = lines[lineIndex]
                    let lineRange = CTLineGetStringRange(currentLine)
                    let characterInLineRange = index - lineRange.location < lineRange.length
                    if characterInLineRange {
                        lineForIndex = absoluteLineNumber
                        break
                    }
                    absoluteLineNumber += 1
                }
            }
            
            if lineForIndex != NSNotFound {
                break
            }
        }
        
        return lineForIndex != NSNotFound ? absoluteLineNumber : NSNotFound
    }

}

// MARK: -

extension CoreTextColumnView {
    
    // MARK: NSAccessibilityStaticText
    
    override func accessibilityVisibleCharacterRange() -> NSRange {
        // Range known to begin at zero. Cannot union with NSNotFound.
        var visibleRange = NSRange()
        for columnIndex in 0..<textFrames.count {
            let frame = textFrames[columnIndex]
            let frameRange = CTFrameGetVisibleStringRange(frame)
            visibleRange = NSUnionRange(visibleRange, NSRange(location: frameRange.location, length: frameRange.length))
        }
        
        return visibleRange
    }
    
    // MARK: NSAccessibilityNavigableStaticText
    
    override func accessibilityValue() -> Any? {
        return attributedString.string
    }
    
    override func accessibilityString(for range: NSRange) -> String? {
        return string(for: range)
    }
    
    override func accessibilityLine(for index: Int) -> Int {
        return line(for: index)
    }
    
    override func accessibilityRange(forLine lineNumber: Int) -> NSRange {
        return range(for: lineNumber)
    }
    
    // Frame is in screen coordinates. See NSAccessibilityFrameInView()
    override func accessibilityFrame(for range: NSRange) -> NSRect {
        return accessibleBounds(for: range)
    }
    
    // MARK: NSAccessibility
    
    override func accessibilityPerformPress() -> Bool {
        // User did control-option-space keyboard shortcut.
        changeLayout()
        return true
    }
}
