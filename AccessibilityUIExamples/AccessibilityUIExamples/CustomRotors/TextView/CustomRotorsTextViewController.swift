/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example demonstrating setup of accessibility rotors to search for various text attributes on an text view.
*/

// To test this feature:
// 1) Change voice over focus to the text view.
// 2) Type cmd-option-u
// 3) Refer to the rotor that contains: Misspellings, Vocabulary and Alice's Thoughts
// 4) You can left arrow or right arrow to navigate between these rotors.

import Cocoa

@available(OSX 10.13, *)
class CustomRotorsTextViewController: NSViewController,
                                        CustomRotorsTextViewDelegate,
                                        NSAccessibilityCustomRotorItemSearchDelegate {
    
    // Rotor titles.
    let vocabularyRotorTitle = "Vocabulary"
    let highlightRotorTitle = "Alice's Thoughts"
    
    let storyTitle = "Alice's Adventures In Wonderland"
    
    let storySnippet = "Alice's Adventures In Wonderland\nBy Lewis Carroll\n\nAlice was beginning to get very tired of sitting by her sister on the bank, and of having nothing to do: once or twice she had peeped into the book her sister was reading, but it had no pictures or conversetions in it, and what is the use of a book, thought Alice without pictures or conversation?\n\nSo she was considering in her own mind (as well as she could, for the hot day made her feel very sleepy and stupid), whether the pleasure of making a daisy-chain would be worth the trouble of getting up and picking the daisies, when suddenly a White Rabbit with pink eyes ran close by her.\n\nThere was nothing so VERY remarkable in that; nor did Alice think it so VERY much out of the way to hear the Rabbit say to itself, Oh dear! Oh dear! I shall be late! (when she thought it over afterwards, it occurred to her that she ought to have wondered at this, but at the time it all seemed quite natural); but when the Rabbit actually TOOK A WATCH OUT OF ITS WAISTCOAT-POCKET, and looked at it, and then hurried on, Alice started to her feet, for it flashed across her mind that she had never before seen a rabbit with either a waistcoat-pocket, or a watch to take out of it, and burning with curiosity, she ran across the field after it, and fertunately was just in time to see it pop down a large rabbit-hole under the hedge.\n\nIn another moment down went Alice after it, never once considering how in the world she was to get out again.\n\nThe rabbit-hole went straight on like a tunnel for some way, and then dipped suddenly down, so suddenly that Alice had not a moment to think about stopping herself before she found herself falling down a very deep well.\n\nEither the well was very deep, or she fell very slowly, for she had plenty of time as she went down to look about her and to wonder what was going to hapen next. First, she tried to look down and make out what she was coming to, but it was too dark to see anything; then she looked at the sides of the well, and noticed that they were filled with cupboards and book-shelves; here and there she saw maps and pictures hung upon pegs. She took down a jar from one of the shelves as she passed; it was labelled 'ORANGE MARMALADE', but to her great disappointment it was empty: she did not like to drop the jar for fear of killing somebody, so managed to put it into one of the cupboards as she fell past it.\n\n'Well!' thought Alice to herself, after such a fall as this, I shall think nothing of tumbling down stairs! How brave they'll all think me at home! Why, I wouldn't say anything about it, even if I fell off the top of the house! (Which was very likely true.)\n\nDown, down, down. Would the fall NEVER come to an end! I wonder how many miles I've fallen by this time? she said aloud. I must be getting somewhere near the centre of the earth. Let me see: that would be four thousand miles down, I think— (for, you see, Alice had learnt several things of this sort in her lessons in the schoolroom, and though this was not a VERY good opportunity for showing off her knowledge, as there was no one to lisen to her, still it was good practice to say it over) —yes, that's about the right distance—but then I wonder what Latitude or Longitude I've got to? (Alice had no idea what Latitude was, or Longitude either, but thought they were nice grand words to say.)\n\n"
    
    let vocabWord1 = "pleasure"
    let vocabWord2 = "curiosity"
    let vocabWord3 = "disappointment"
    let vocabWord4 = "opportunity"
    let vocabWord5 = "knowledge"
    
    let highlightedNote1 = "and what is the use of a book"
    let highlightedNote2 = "without pictures or conversation?"
    let highlightedNote3 = "Oh dear! Oh dear! I shall be late!"
    let highlightedNote4 = "after such a fall as this, I shall think nothing of tumbling down stairs! How brave they'll all think me at home! Why, I wouldn't say anything about it, even if I fell off the top of the house!"
    let highlightedNote5 = "I wonder how many miles I've fallen by this time?"
    let highlightedNote6 = "I must be getting somewhere near the centre of the earth. Let me see: that would be four thousand miles down, I think—"
    let highlightedNote7 = "—yes, that's about the right distance—but then I wonder what Latitude or Longitude I've got to?"
    
    let misspelledWord1 = "conversetions"    // correct version = conversations
    let misspelledWord2 = "fertunately"      // correct version = fortunately
    let misspelledWord3 = "hapen"            // correct version = happen
    let misspelledWord4 = "lisen"            // correct version = listen
    
    // Search for "dream" will result in - "when suddently"
    // Search for "falling into the well" will result in - "In another moment"
    //
    // User must search for either of these strings:
    let searchKeyword1 = "dream"
    let searchKeyword2 = "falling into the well"
    // The search will result these content strings:
    let contentSearchEntry1 = "when suddenly"
    let contentSearchEntry2 = "In another moment"
    
    var vocabWords = [NSRange]()
    var highlightedNotes = [NSRange]()
    var misspelledWords = [NSRange]()
    
    @IBOutlet var textView: CustomRotorsTextView!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        insertTextViewString()
        textView.rotorDelegate = self
	}
    
    func buildVocabulary(textStorage: NSTextStorage) {
        let vocabWord1Range = textView.string.range(of: vocabWord1)
        let vocabWord2Range = textView.string.range(of: vocabWord2)
        let vocabWord3Range = textView.string.range(of: vocabWord3)
        let vocabWord4Range = textView.string.range(of: vocabWord4)
        let vocabWord5Range = textView.string.range(of: vocabWord5)
        
        vocabWords = [ NSRange(vocabWord1Range!, in: vocabWord1),
                       NSRange(vocabWord2Range!, in: vocabWord2),
                       NSRange(vocabWord3Range!, in: vocabWord3),
                       NSRange(vocabWord4Range!, in: vocabWord4),
                       NSRange(vocabWord5Range!, in: vocabWord5) ]
        
        // Apply the blue bold font vocabulary words.
        let vocabColor = NSColor.blue
        var attrRange = NSRange(vocabWord1Range!, in: misspelledWord4)
        textStorage.addAttribute(NSAttributedStringKey.foregroundColor, value: vocabColor, range: attrRange)
        textStorage.applyFontTraits(NSFontTraitMask(rawValue: NSFontTraitMask.RawValue(NSFontBoldTrait)), range: attrRange)
        
        attrRange = NSRange(vocabWord2Range!, in: vocabWord2)
        textStorage.addAttribute(NSAttributedStringKey.foregroundColor, value: vocabColor, range: attrRange)
        textStorage.applyFontTraits(NSFontTraitMask(rawValue: NSFontTraitMask.RawValue(NSFontBoldTrait)), range: attrRange)
        
        attrRange = NSRange(vocabWord3Range!, in: vocabWord3)
        textStorage.addAttribute(NSAttributedStringKey.foregroundColor, value: vocabColor, range: attrRange)
        textStorage.applyFontTraits(NSFontTraitMask(rawValue: NSFontTraitMask.RawValue(NSFontBoldTrait)), range: attrRange)
        
        attrRange = NSRange(vocabWord4Range!, in: vocabWord4)
        textStorage.addAttribute(NSAttributedStringKey.foregroundColor, value: vocabColor, range: attrRange)
        textStorage.applyFontTraits(NSFontTraitMask(rawValue: NSFontTraitMask.RawValue(NSFontBoldTrait)), range: attrRange)
        
        attrRange = NSRange(vocabWord5Range!, in: vocabWord5)
        textStorage.addAttribute(NSAttributedStringKey.foregroundColor, value: vocabColor, range: attrRange)
        textStorage.applyFontTraits(NSFontTraitMask(rawValue: NSFontTraitMask.RawValue(NSFontBoldTrait)), range: attrRange)
    }
    
    func buildHighlighted(textStorage: NSTextStorage) {
        let highlightedNote1Range = textView.string.range(of: highlightedNote1)
        let highlightedNote2Range = textView.string.range(of: highlightedNote2)
        let highlightedNote3Range = textView.string.range(of: highlightedNote3)
        let highlightedNote4Range = textView.string.range(of: highlightedNote4)
        let highlightedNote5Range = textView.string.range(of: highlightedNote5)
        let highlightedNote6Range = textView.string.range(of: highlightedNote6)
        let highlightedNote7Range = textView.string.range(of: highlightedNote7)
        
        highlightedNotes = [ NSRange(highlightedNote1Range!, in: highlightedNote1),
                             NSRange(highlightedNote2Range!, in: highlightedNote2),
                             NSRange(highlightedNote3Range!, in: highlightedNote3),
                             NSRange(highlightedNote4Range!, in: highlightedNote4),
                             NSRange(highlightedNote5Range!, in: highlightedNote5),
                             NSRange(highlightedNote6Range!, in: highlightedNote6),
                             NSRange(highlightedNote7Range!, in: highlightedNote7) ]
        
        // Apply the highlighted words.
        let highlightColor = NSColor.yellow
        var attrRange = NSRange(highlightedNote1Range!, in: highlightedNote1)
        textStorage.addAttribute(NSAttributedStringKey.backgroundColor, value: highlightColor, range: attrRange)
        
        attrRange = NSRange(highlightedNote2Range!, in: highlightedNote2)
        textStorage.addAttribute(NSAttributedStringKey.backgroundColor, value: highlightColor, range: attrRange)
        
        attrRange = NSRange(highlightedNote3Range!, in: highlightedNote3)
        textStorage.addAttribute(NSAttributedStringKey.backgroundColor, value: highlightColor, range: attrRange)
        
        attrRange = NSRange(highlightedNote4Range!, in: highlightedNote4)
        textStorage.addAttribute(NSAttributedStringKey.backgroundColor, value: highlightColor, range: attrRange)
        
        attrRange = NSRange(highlightedNote5Range!, in: highlightedNote5)
        textStorage.addAttribute(NSAttributedStringKey.backgroundColor, value: highlightColor, range: attrRange)
        
        attrRange = NSRange(highlightedNote6Range!, in: highlightedNote6)
        textStorage.addAttribute(NSAttributedStringKey.backgroundColor, value: highlightColor, range: attrRange)
        
        attrRange = NSRange(highlightedNote7Range!, in: highlightedNote7)
        textStorage.addAttribute(NSAttributedStringKey.backgroundColor, value: highlightColor, range: attrRange)
    }
    
    func buildMisspelled(textStorage: NSTextStorage) {
        let misspelledWord1Range = textView.string.range(of: misspelledWord1)
        let misspelledWord2Range = textView.string.range(of: misspelledWord2)
        let misspelledWord3Range = textView.string.range(of: misspelledWord3)
        let misspelledWord4Range = textView.string.range(of: misspelledWord4)
        
        misspelledWords = [ NSRange(misspelledWord1Range!, in: misspelledWord1),
                            NSRange(misspelledWord2Range!, in: misspelledWord2),
                            NSRange(misspelledWord3Range!, in: misspelledWord3),
                            NSRange(misspelledWord4Range!, in: misspelledWord4) ]
        
        // Apply the underline misspelled words.
        let underlineValue = NSNumber(value: 1)
        var attrRange = NSRange(misspelledWord1Range!, in: misspelledWord1)
        textStorage.addAttribute(NSAttributedStringKey.underlineStyle, value: underlineValue, range: attrRange)
        
        attrRange = NSRange(misspelledWord2Range!, in: misspelledWord2)
        textStorage.addAttribute(NSAttributedStringKey.underlineStyle, value: underlineValue, range: attrRange)
        
        attrRange = NSRange(misspelledWord3Range!, in: misspelledWord3)
        textStorage.addAttribute(NSAttributedStringKey.underlineStyle, value: underlineValue, range: attrRange)
        
        attrRange = NSRange(misspelledWord4Range!, in: misspelledWord4)
        textStorage.addAttribute(NSAttributedStringKey.underlineStyle, value: underlineValue, range: attrRange)
    }
    
    func insertTextViewString() {
        // Set the content.
        textView.string = storySnippet
        
        // Prepare to edit the text storage.
        let textStorage: NSTextStorage = textView.textStorage!
        textStorage.beginEditing()
        
        // Find the all ranges.
        buildVocabulary(textStorage: textStorage)
        buildHighlighted(textStorage: textStorage)
        buildMisspelled(textStorage: textStorage)
        
        // Grab the default font.
        let range = NSRange(location: 0, length: textView.string.characters.count)
        if let font = textStorage.attribute(NSAttributedStringKey.font, at: range.location, effectiveRange: nil) as? NSFont {
            // Apply the heading font.
            let titleRange = textView.string.range(of: storyTitle)
            
            let headingFont = NSFont(name: font.familyName!, size: font.pointSize + 10)
            textStorage.addAttribute(NSAttributedStringKey.font,
                                     value: headingFont as Any,
                                     range: NSRange(titleRange!, in: storyTitle))
        }
        
        textStorage.endEditing()
    }
    
}

// MARK: - NSAccessibilityCustomRotorItemSearchDelegate

@available(OSX 10.13, *)
extension CustomRotorsTextViewController {
    
    func textSearchResultForString(searchString: String, fromRange: NSRange, direction: NSAccessibilityCustomRotor.SearchDirection)
        -> NSAccessibilityCustomRotor.ItemResult? {
            var searchResult: NSAccessibilityCustomRotor.ItemResult?
            
            var searchEntry = String()
            if searchString == searchKeyword1 {
                searchEntry = contentSearchEntry1
            } else if searchString == searchKeyword2 {
                searchEntry = contentSearchEntry2
            }
            
            if !searchEntry.characters.isEmpty {
                var searchFound = false
                let contentString = textView.textStorage?.string
                
                let resultRange = contentString?.range(of: searchEntry,
                                                       options: NSString.CompareOptions.literal,
                                                       range: (contentString?.startIndex)!..<(contentString?.endIndex)!,
                                                       locale: nil)
                let realRange = NSRange(resultRange!, in: contentString!)
                
                if direction == NSAccessibilityCustomRotor.SearchDirection.previous {
                    searchFound = (realRange.location) < fromRange.location
                } else if direction == NSAccessibilityCustomRotor.SearchDirection.next {
                    searchFound = (realRange.location) >= NSMaxRange(fromRange)
                }
                if searchFound {
                    searchResult = NSAccessibilityCustomRotor.ItemResult(targetElement: textView as NSAccessibilityElementProtocol)
                    searchResult?.targetRange = realRange
                }
            }
            return searchResult
    }

    public func rotor(_ rotor: NSAccessibilityCustomRotor,
                      resultFor searchParameters: NSAccessibilityCustomRotor.SearchParameters) -> NSAccessibilityCustomRotor.ItemResult? {
        var searchResult: NSAccessibilityCustomRotor.ItemResult?
        
        let currentItemResult = searchParameters.currentItem
        let direction = searchParameters.searchDirection
        let filterText = searchParameters.filterString
        var currentRange = currentItemResult?.targetRange
        let rotorName = rotor.label
        
        if rotor.type == .any {
            return textSearchResultForString(searchString: filterText, fromRange: currentRange!, direction: direction)
        }
        
        var filteredChildren = [NSRange]()
        if rotorName == vocabularyRotorTitle {
            filteredChildren = vocabWords
        } else if rotorName == highlightRotorTitle {
            filteredChildren = highlightedNotes
        } else if rotor.type == .misspelledWord {
            filteredChildren = misspelledWords
        }
        
        // If filter text is available, but not a range, use the start range.
        if !filterText.characters.isEmpty && currentRange?.location == NSNotFound {
            currentRange = NSRange(location: 0, length: 0)
        }
        
        var targetRangeValue: NSRange?
        let contentString = textView.textStorage?.string
        let currentTextIndex = currentRange?.location
        if currentTextIndex == NSNotFound {
            // Find the start or end element.
            if direction == NSAccessibilityCustomRotor.SearchDirection.next {
                targetRangeValue = filteredChildren.first
            } else if direction == NSAccessibilityCustomRotor.SearchDirection.previous {
                targetRangeValue = filteredChildren.last
            }
        } else {
            if direction == NSAccessibilityCustomRotor.SearchDirection.previous {
                for i in (0...filteredChildren.count).reversed() {
                    let range = Range(filteredChildren[i], in: contentString!)
                    let subString = contentString![range!]
                
                    let matches = subString.localizedCaseInsensitiveCompare(filterText)
                    let index = filteredChildren[i].location
                    
                    let matchesFilterText = (filterText.characters.isEmpty || matches == .orderedSame)
                    if index < currentTextIndex! && matchesFilterText {
                        targetRangeValue = filteredChildren[i]
                        break
                    }
                }
            } else if direction == NSAccessibilityCustomRotor.SearchDirection.next {
                for i in 0..<filteredChildren.count {
                    let range = Range(filteredChildren[i], in: contentString!)
                    let subString = contentString![range!]
                    
                    let matches = subString.localizedCaseInsensitiveCompare(filterText)
                    let index = filteredChildren[i].location
                    
                    let matchesFilterText = (filterText.characters.isEmpty || matches == .orderedSame)
                    if index > currentTextIndex! && matchesFilterText {
                        targetRangeValue = filteredChildren[i]
                        break
                    }
                }
            }
        }
        
        if targetRangeValue != nil {
            let textRange = targetRangeValue
            searchResult = NSAccessibilityCustomRotor.ItemResult(targetElement: textView as NSAccessibilityElementProtocol)
            searchResult?.targetRange = textRange!
        }
        return searchResult
    }
}

// MARK: - CustomRotorsTextViewDelegate

@available(OSX 10.13, *)
extension CustomRotorsTextViewController {
    func createCustomRotors() -> [NSAccessibilityCustomRotor] {
        // Create the vocabulary rotor.
        let vocabularyRotor =
            NSAccessibilityCustomRotor(label: vocabularyRotorTitle, itemSearchDelegate: self as NSAccessibilityCustomRotorItemSearchDelegate)
        
        // Create the special text highlight rotor.
        let highlightRotor =
            NSAccessibilityCustomRotor(label: highlightRotorTitle, itemSearchDelegate: self as NSAccessibilityCustomRotorItemSearchDelegate)
        
        // Create the misspelled rotor.
        let misspelledRotor =
            NSAccessibilityCustomRotor(rotorType: .misspelledWord, itemSearchDelegate: self as NSAccessibilityCustomRotorItemSearchDelegate)
        
        // Create the text search rotor.
        let textSearchRotor =
            NSAccessibilityCustomRotor(rotorType: .any, itemSearchDelegate: self as NSAccessibilityCustomRotorItemSearchDelegate)
        
        return [vocabularyRotor, highlightRotor, misspelledRotor, textSearchRotor]
    }

}
