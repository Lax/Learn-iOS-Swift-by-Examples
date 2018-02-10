/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 ATSampleWindowRowView implementation. This class is used because the NIB has an ATSampleWindowRowView placed in it with a special key of NSTableViewRowViewKey. NSTableView first looks for a view with that key for the row view, if the delegate method tableView:rowViewForRow: is not used.
 */

#import "ATSampleWindowRowView.h"

@implementation ATSampleWindowRowView

- (void)drawSelectionInRect:(NSRect)dirtyRect {
    NSColor *primaryColor = [[NSColor alternateSelectedControlColor] colorWithAlphaComponent:0.5];
    NSColor *secondarySelectedControlColor = [[NSColor secondarySelectedControlColor] colorWithAlphaComponent:0.5];
    
    // Implement our own custom alpha drawing.
    switch (self.selectionHighlightStyle) {
        case NSTableViewSelectionHighlightStyleRegular: {
            if (self.selected) {
                if (self.emphasized) {
                    [primaryColor set];
                } else {
                    [secondarySelectedControlColor set];
                }
                NSRect bounds = self.bounds;
                const NSRect *rects = NULL;
                NSInteger count = 0;
                [self getRectsBeingDrawn:&rects count:&count];
                for (NSInteger i = 0; i < count; i++) {
                    NSRect rect = NSIntersectionRect(bounds, rects[i]);
                    NSRectFillUsingOperation(rect, NSCompositingOperationSourceOver);
                }
            }
            break;
        }
        default: {
            // Do super's drawing.
            [super drawSelectionInRect:dirtyRect];
            break;
        }
    }
}

- (void)drawSeparatorInRect:(NSRect)dirtyRect {
    // Draw the grid.
    NSRect sepRect = self.bounds;
    sepRect.origin.y = NSMaxY(sepRect) - 1;
    sepRect.size.height = 1;
    sepRect = NSIntersectionRect(sepRect, dirtyRect);
    if (!NSIsEmptyRect(sepRect)) {
        [[NSColor gridColor] set];
        NSRectFill(sepRect);
    }
}

@end
