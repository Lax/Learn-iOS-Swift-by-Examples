/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The AAPLListFormatting class has two purposes: one for transforming ListItem objects into a string representation, and one for transforming a string representation of a list into an array of AAPLListItem objects. It is used for copying and pasting AAPLListItem objects into and out of the app via NSPasteboard.
            
*/

@import Foundation;

@class AAPLListItem;

@interface AAPLListFormatting : NSObject

+ (NSArray *)listItemsFromString:(NSString *)string;
+ (NSString *)stringFromListItems:(NSArray *)items;

@end
