/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ResizingTextField` class is a subclass of the `NSTextField` class that maintains its `intrinsicContentSize` based on the size of its text.
*/

import Cocoa

class ResizingTextField: NSTextField {
    override func textDidChange(notification: NSNotification) {
        super.textDidChange(notification)
        
        invalidateIntrinsicContentSize()
    }
    
    override var intrinsicContentSize: NSSize {
        // Change the auto layout constraint width to be the drawn size of the text.
        let maximumSize = NSMakeSize(CGFloat.max, frame.height)
        
        // Find the size that the string occupies when displayed with the given font.
        let boundingSize = (stringValue as NSString).boundingRectWithSize(maximumSize, options: nil, attributes: [
            NSFontAttributeName: font!]
        )

        let roundedWidth = CGFloat(boundingSize.width + 10)

        return NSSize(width: roundedWidth, height: frame.height)
    }
}
