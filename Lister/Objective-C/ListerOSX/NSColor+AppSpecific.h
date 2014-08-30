/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Adds a category to NSColor to provide predefined incomplete and complete item text color.
            
*/

@import Cocoa;

@interface NSColor (AAPLAppSpecific)

+ (NSColor *)aapl_completeItemTextColor;
+ (NSColor *)aapl_incompleteItemTextColor;

@end