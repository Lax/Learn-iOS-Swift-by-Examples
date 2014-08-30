/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                An NSTableRowView subclass that draws a specific background color. The table view creates these row views automatically because the NSTableViewRowViewKey key is set on one of the ListViewController object's rows in the storyboard.
            
 */

#import "AAPLTableRowView.h"

@implementation AAPLTableRowView

- (void)drawSelectionInRect:(NSRect)dirtyRect {
    [super drawSelectionInRect:dirtyRect];

    NSColor *selectionColor = [NSColor colorWithRed:0.76 green:0.82 blue:0.92 alpha:1];
    [selectionColor setFill];
    
    NSRectFill(dirtyRect);
}

@end
