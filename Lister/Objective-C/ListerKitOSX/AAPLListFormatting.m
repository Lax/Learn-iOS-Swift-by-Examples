/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The AAPLListFormatting class has two purposes: one for transforming ListItem objects into a string representation, and one for transforming a string representation of a list into an array of AAPLListItem objects. It is used for copying and pasting AAPLListItem objects into and out of the app via NSPasteboard.
            
*/

#import "AAPLListFormatting.h"
#import "AAPLListItem.h"

@implementation AAPLListFormatting

+ (NSArray *)listItemsFromString:(NSString *)string {
    NSMutableArray *listItems = [NSMutableArray array];

    NSRange range = NSMakeRange(0, string.length);
    NSStringEnumerationOptions enumerationOptions = NSStringEnumerationBySentences | NSStringEnumerationByLines;

    NSCharacterSet *characterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    [string enumerateSubstringsInRange:range options:enumerationOptions usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        NSString *trimmedString = [substring stringByTrimmingCharactersInSet:characterSet];
        
        if (trimmedString.length > 0) {
            AAPLListItem *listItem = [[AAPLListItem alloc] initWithText:trimmedString];
            
            [listItems addObject:listItem];
        }
    }];
    
    return listItems;
}

/// Concatenate all item's \c text property together.
+ (NSString *)stringFromListItems:(NSArray *)listItems {
    NSArray *itemTextValues = [listItems valueForKey:@"text"];

    return [itemTextValues componentsJoinedByString:@"\n"];
}

@end
