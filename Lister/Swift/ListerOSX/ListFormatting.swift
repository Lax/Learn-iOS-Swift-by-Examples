/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The AAPLListFormatting class has two purposes: one for transforming ListItem objects into a string representation, and one for transforming a string representation of a list into a ListItem[]. It is used for copying and pasting ListItem objects into and out of the app via NSPasteboard.
            
*/

import Foundation

class ListFormatting {
    class func listItemsFromString(string: String) -> ListItem[] {
        var listItems = ListItem[]()

        let enumerationOptions: NSStringEnumerationOptions = .BySentences | .ByLines
        let range = Range(start: string.startIndex, end: string.endIndex)

        let characterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()

        string.enumerateSubstringsInRange(range, options: enumerationOptions) { substring, _, _, _ in
            let trimmedString = substring.stringByTrimmingCharactersInSet(characterSet)

            if !trimmedString.isEmpty {
                listItems += ListItem(text: trimmedString)
            }
        }

        return listItems
    }

    // Concatenate all item's `text` property together.
    class func stringFromListItems(items: ListItem[]) -> String {
        return items.reduce("") { (string, item) in
            "\(string)\(item.text)\n"
        }
    }
}