/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Custom text view with custom text attributes.
*/

import Cocoa

@available(OSX 10.13, *)
class TextAttributesTextView: NSTextView {
    var eggPlantAnnotation: NSTextField!
    var broccoliAnnotation: NSTextField!
    var buyButton: NSButton!
    
    fileprivate var accessibilityAttributedString = NSAttributedString()
    
    fileprivate func setupAccessibilityString() {
        // Mark up the string with attributes.
        
        // Add the header style.
        let entireRange = NSRange(location: 0, length: string.characters.count)
        if let stringWithAttributes = super.accessibilityAttributedString(for: entireRange) as? NSMutableAttributedString {
            var attributes =
                [NSAttributedStringKey.accessibilityCustomText:
                    NSLocalizedString("header", comment: "header style name")] as [NSAttributedStringKey : Any]
            var attributeRange = NSIntersectionRange(entireRange, accessibilityRange(forLine: 0))
            stringWithAttributes.addAttributes(attributes, range: attributeRange)
            
            // Add the first comment annotation (using annotation string "Egg Plant Again?"), with the full string.
            var textAttributes = [
                NSAccessibilityAnnotationAttributeKey.label: eggPlantAnnotation.stringValue,
                NSAccessibilityAnnotationAttributeKey.location: NSNumber(value: NSAccessibilityAnnotationPosition.fullRange.rawValue)
                ] as [NSAccessibilityAnnotationAttributeKey : Any]
            attributes = [NSAttributedStringKey.accessibilityAnnotationTextAttribute: [textAttributes]]
            
            attributeRange = NSIntersectionRange(entireRange, accessibilityRange(forLine: 2))
            stringWithAttributes.addAttributes(attributes, range: attributeRange)
            
            // Add the list attributes.
            var listItemPrefix = NSAttributedString(string: NSLocalizedString("1.\t", comment: "Index of item in list"))
            var listItemDict = [
                NSAttributedStringKey.accessibilityListItemIndex: NSNumber(value: 0),
                NSAttributedStringKey.accessibilityListItemLevel: NSNumber(value: 0),
                NSAttributedStringKey.accessibilityListItemPrefix: listItemPrefix
                ] as [NSAttributedStringKey : Any]
            attributeRange = NSIntersectionRange(entireRange, accessibilityRange(forLine: 5))
            stringWithAttributes.addAttributes(listItemDict, range: attributeRange)
            
            listItemPrefix = NSAttributedString(string: NSLocalizedString("2.\t", comment: "Index of item in list"))
            listItemDict = [
                    NSAttributedStringKey.accessibilityListItemIndex: NSNumber(value: 1),
                    NSAttributedStringKey.accessibilityListItemLevel: NSNumber(value: 0),
                    NSAttributedStringKey.accessibilityListItemPrefix: listItemPrefix ]
                as [NSAttributedStringKey : Any]
            attributeRange = NSIntersectionRange(entireRange, accessibilityRange(forLine: 6))
            stringWithAttributes.addAttributes(listItemDict, range: attributeRange)
            
            listItemPrefix = NSAttributedString(string: NSLocalizedString("3.\t", comment: "Index of item in list"))
            listItemDict = [
                    NSAttributedStringKey.accessibilityListItemIndex: NSNumber(value: 2),
                    NSAttributedStringKey.accessibilityListItemLevel: NSNumber(value: 0),
                    NSAttributedStringKey.accessibilityListItemPrefix: listItemPrefix ]
                as [NSAttributedStringKey : Any]
            attributeRange = NSIntersectionRange(entireRange, accessibilityRange(forLine: 7))
            stringWithAttributes.addAttributes(listItemDict, range: attributeRange)
            
            // Add the second comment annotation (using annotation string "I'll pick some up after work), but with a partial string.
            textAttributes = [
                NSAccessibilityAnnotationAttributeKey.label: broccoliAnnotation.stringValue,
                NSAccessibilityAnnotationAttributeKey.location: NSNumber(value: NSAccessibilityAnnotationPosition.end.rawValue)
                ] as [NSAccessibilityAnnotationAttributeKey : Any]
            attributes = [NSAttributedStringKey.accessibilityAnnotationTextAttribute: [textAttributes]]
            
            listItemDict = [
                    NSAttributedStringKey.accessibilityListItemIndex: NSNumber(value: 2),
                    NSAttributedStringKey.accessibilityListItemLevel: NSNumber(value: 0),
                    NSAttributedStringKey.accessibilityListItemPrefix: listItemPrefix,
                    NSAttributedStringKey.accessibilityAnnotationTextAttribute: textAttributes
                    ]
                as [NSAttributedStringKey : Any]
            var annotationRange = NSRange(location: NSMaxRange(accessibilityRange(forLine: 7)) - 2, length: 1)
            attributeRange = NSIntersectionRange(entireRange, annotationRange)
            stringWithAttributes.addAttributes(listItemDict, range: attributeRange)
            
            // Add the button annotation.
            annotationRange = NSRange(location: accessibilityRange(forLine: 9).location, length: 1)
            textAttributes = [
                NSAccessibilityAnnotationAttributeKey.element: buyButton.cell as Any,
                NSAccessibilityAnnotationAttributeKey.location: NSNumber(value: NSAccessibilityAnnotationPosition.start.rawValue)
                ] as [NSAccessibilityAnnotationAttributeKey : Any]
            attributes = [NSAttributedStringKey.accessibilityAnnotationTextAttribute: [textAttributes]]
            attributeRange = NSIntersectionRange(entireRange, annotationRange)
            stringWithAttributes.addAttributes(attributes, range: attributeRange)
            
            accessibilityAttributedString = stringWithAttributes
        }
    }
    
    // MARK: - Accessibility
    
    override func accessibilityAttributedString(for range: NSRange) -> NSAttributedString? {
        if accessibilityAttributedString.length == 0 {
            setupAccessibilityString()
        }
        return accessibilityAttributedString.attributedSubstring(from: range)
    }
}
