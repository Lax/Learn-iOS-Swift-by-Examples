/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A subclass of NSTextField that maintains its intrinsicContentSize property based on the size of its text.
            
*/

import Cocoa

class ResizingTextField: NSTextField {
    override func textDidChange(notification: NSNotification) {
        super.textDidChange(notification)
        
        invalidateIntrinsicContentSize()
    }
    
    override var intrinsicContentSize: NSSize {
        // Change the auto layout constraint width to be the drawn size of the text.
        let maximumSize = NSMakeSize(CGFLOAT_MAX, NSHeight(frame))
        
        // Need to cast stringValue to an NSString in order to call boundingRectWithSize(_:options:attributes:).
        let string = stringValue as NSString
        let boundingSize = string.boundingRectWithSize(maximumSize, options: nil, attributes: [NSFontAttributeName: font])

        let roundedWidth = CGFloat(Int(NSWidth(boundingSize)) + 10)

        return NSSize(width: roundedWidth, height: NSHeight(frame))
    }
}
