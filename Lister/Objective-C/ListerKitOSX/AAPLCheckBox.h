/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A layer-backed custom check box that is IBDesignable and IBInspectable.
            
 */

@import Cocoa;

IB_DESIGNABLE
@interface AAPLCheckBox : NSButton

@property IBInspectable NSColor *tintColor;

@property (nonatomic, getter=isChecked) IBInspectable BOOL checked;

@end
