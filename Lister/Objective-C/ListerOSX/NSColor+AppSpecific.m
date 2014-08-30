/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Adds a category to NSColor to provide predefined incomplete and complete item text color.
            
*/

@import Cocoa;

@implementation NSColor (AAPLAppSpecific)

+ (NSColor *)aapl_completeItemTextColor {
    static NSColor *completeItemTextColor;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        completeItemTextColor = [NSColor colorWithRed:0.70 green:0.70 blue:0.70 alpha:1];
    });
    
    return completeItemTextColor;
}

+ (NSColor *)aapl_incompleteItemTextColor {
    return [NSColor blackColor];
}

@end
