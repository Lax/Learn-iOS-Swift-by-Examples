/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLListFormatting class has two purposes: one for transforming AAPLListItem objects into a string representation, and one for transforming a string representation of a list into an array of \c AAPLListItem objects. It is used for copying and pasting \c AAPLListItem objects into and out of the app via \c NSPasteboard.
*/

@import Foundation;

@class AAPLListItem;

@interface AAPLListFormatting : NSObject

/// Construct an \c AAPLListItem array from a string.
+ (NSArray *)listItemsFromString:(NSString *)string;

/// Concatenate all item's \c text property together.
+ (NSString *)stringFromListItems:(NSArray *)items;

@end
