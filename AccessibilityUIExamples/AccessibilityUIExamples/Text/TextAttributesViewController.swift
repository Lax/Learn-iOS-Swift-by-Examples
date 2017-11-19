/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller demonstrating accessibility to various custom text attributes.
 
 How to use:
 With VoiceOver Cursor anywhere in the range of the vegetable list, type control-option-t,
 and VoiceOver should speak the attribute information (including the annotations), and including the list style.
*/

import Cocoa

class LinesView: NSView {
    
    // MARK: - Properties
    
    var eggPlantAnnotationRect = NSRect()
    var broccoliAnnotationRect = NSRect()
    var buyButtonRect = NSRect()
    
    var eggPlantAnnotationTextRect = NSRect()
    var broccoliAnnotationTextRect = NSRect()
    var buyButtonTextRect = NSRect()
    
    // MARK: - Drawing
    
    fileprivate func addLineFromPoint(point1: NSPoint, point2: NSPoint) {
        let line = NSBezierPath()
        line.move(to: point1)
        line.line(to: point2)
        line.lineWidth = 2
        NSColor.green.setStroke()
        line.stroke()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        var edgeOfText = NSPoint(x: eggPlantAnnotationTextRect.maxX, y: eggPlantAnnotationTextRect.maxY)
        addLineFromPoint(point1: edgeOfText, point2: eggPlantAnnotationRect.origin)
        
        edgeOfText = NSPoint(x: broccoliAnnotationTextRect.maxX, y: broccoliAnnotationTextRect.maxY)
        addLineFromPoint(point1: edgeOfText, point2: broccoliAnnotationRect.origin)
        
        edgeOfText = NSPoint(x: buyButtonTextRect.maxX, y: buyButtonTextRect.origin.y + buyButtonTextRect.size.height)
        var newOrigin = buyButtonRect.origin
        newOrigin.y += buyButtonRect.size.height / 2
        addLineFromPoint(point1: edgeOfText, point2: newOrigin)
    }
    
    // MARK: - Accessibility
    
    override func isAccessibilityElement() -> Bool {
        return false
    }
}

// MARK: -

@available(OSX 10.13, *)
class TextAttributesViewController: NSViewController {
    
    // MARK: - Properties
    
    @IBOutlet var attributedTextView: TextAttributesTextView!
    @IBOutlet var linesView: LinesView!
    @IBOutlet var eggPlantAnnotation: NSTextField!
    @IBOutlet var broccoliAnnotation: NSTextField!
    @IBOutlet var buyButton: NSButton!
    
    static let fontFamilyName = "Chalkboard"
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Add the attribute elements to the text view
        attributedTextView.eggPlantAnnotation = eggPlantAnnotation
        attributedTextView.broccoliAnnotation = broccoliAnnotation
        attributedTextView.buyButton = buyButton
        
        // Add the title text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.center
        
        let font: NSFont =
            NSFontManager.shared.font(withFamily: TextAttributesViewController.fontFamilyName,
                                      traits: NSFontTraitMask.boldFontMask,
                                      weight: 0,
                                      size: 16)!
        let titleAttributes =
            [NSAttributedStringKey.paragraphStyle: paragraphStyle, NSAttributedStringKey.font: font] as [NSAttributedStringKey : Any]
        
        let menu = NSAttributedString(string: NSLocalizedString("Dinner Menu\n\n", comment: "Dinner menu title"), attributes: titleAttributes)
        appendString(string: menu, textView: attributedTextView)
        
        // Add the content text.
        let font2: NSFont = NSFontManager.shared.font(withFamily: TextAttributesViewController.fontFamilyName,
                                         traits: NSFontTraitMask.unboldFontMask,
                                         weight: 0,
                                         size: 12)!
        let bodyAttributes = [NSAttributedStringKey.paragraphStyle: paragraphStyle,
                              NSAttributedStringKey.font: font2]
        let bodyString =
            NSAttributedString(string: NSLocalizedString("Mini Eggplant Tacos\n\nPasta Primavera with:\ncarrots\nzucchini\nbroccoli\n\nApple Pie",
                                                         comment: "Dinner menu content"),
                               attributes: bodyAttributes)
        appendString(string: bodyString, textView: attributedTextView)
        
        // Add the rects for the annotations.
        linesView.eggPlantAnnotationRect = eggPlantAnnotation.frame
        linesView.broccoliAnnotationRect = broccoliAnnotation.frame
        linesView.buyButtonRect = buyButton.frame
        
        // Add the rects for the text corresponding to the annotations.
        linesView.eggPlantAnnotationTextRect =
            frameForString(string: NSLocalizedString("Mini Eggplant Tacos", comment: "substring of dinner menu content"), index: 8)
        linesView.broccoliAnnotationTextRect =
            frameForString(string: NSLocalizedString("broccoli", comment: "substring of dinner menu content"), index: 7)
        linesView.buyButtonTextRect =
            frameForString(string: NSLocalizedString("Apple", comment: "substring of dinner menu content"), index: 1)
    }
    
    // MARK: - Utilities
    
    fileprivate func appendString(string: NSAttributedString, textView: NSTextView) {
        let insertionPosition = textView.string.characters.count
        textView.insertText(string, replacementRange: NSRange(location: insertionPosition, length: 0))
    }
    
    fileprivate func frameForString(string: String, index: Int) -> NSRect {
        let vocabWord1Range = attributedTextView.textStorage?.string.range(of: string)
        let realRange = NSRange(vocabWord1Range!, in: string)
        let stringAtIndexRange = NSRange(location: realRange.location + index, length: 1)
        let glyphRange = attributedTextView.layoutManager?.glyphRange(forCharacterRange: stringAtIndexRange, actualCharacterRange: nil)
        let rectInTextContainer = attributedTextView.layoutManager?.boundingRect(forGlyphRange: glyphRange!, in: attributedTextView.textContainer!)
        let rectInView = NSRect(x: (rectInTextContainer?.origin.x)! + attributedTextView.textContainerOrigin.x,
                                y: attributedTextView.textContainerOrigin.y + (rectInTextContainer?.origin.y)! + (rectInTextContainer?.size.height)!,
                                width: (rectInTextContainer?.size.width)!,
                                height: (rectInTextContainer?.size.height)!)
        return attributedTextView.convert(rectInView, to: linesView)
    }
    
    // MARK: - Actions
    
    @IBAction func buyApplePie(_ sender: Any) {
        print("Buy Apple Pie")
    }
}

