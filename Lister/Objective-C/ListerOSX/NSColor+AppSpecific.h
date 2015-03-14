/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Adds a category to \c NSColor to provide predefined incomplete and complete item text color.
*/

@import Cocoa;

@interface NSColor (AAPLAppSpecific)

+ (NSColor *)aapl_completeItemTextColor;
+ (NSColor *)aapl_incompleteItemTextColor;

@end