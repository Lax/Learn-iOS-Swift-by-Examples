/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A subclass of NSTextField that maintains its intrinsicContentSize property based on the size of its text.
            
 */

#import "AAPLResizingTextField.h"

@implementation AAPLResizingTextField

- (void)textDidChange:(NSNotification *)notification {
    [super textDidChange:notification];
    
    [self invalidateIntrinsicContentSize];
}

- (NSSize)intrinsicContentSize {
    NSSize maximumSize = NSMakeSize(CGFLOAT_MAX, NSHeight(self.frame));

    NSRect boundingSize = [self.stringValue boundingRectWithSize:maximumSize options:0 attributes:@{ NSFontAttributeName: self.font }];

    CGFloat roundedWidth = (CGFloat)((NSInteger)NSWidth(boundingSize) + 10);

    return NSMakeSize(roundedWidth, NSHeight(self.frame));
}

@end
