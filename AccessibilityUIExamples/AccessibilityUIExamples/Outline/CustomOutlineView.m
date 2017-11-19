/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Category for adoption on NSAccessibilityOutline.
*/

#import "AccessibilityUIExamples-Swift.h"

@interface CustomOutlineView (Accessibility) <NSAccessibilityOutline>
@end

@implementation CustomOutlineView (Accessibility)

- (NSArray *)accessibilityRows
{
    NSMutableArray *accessibilityRows = [[NSMutableArray alloc] init];
    NSArray *visibleNodes = [self visibleNodes];
    
    for (OutlineViewNode *node in visibleNodes) {
        NSAccessibilityElement *element = [self accessibilityElementForNodeWithNode:node];
        [accessibilityRows addObject:element];
    }
    
    return accessibilityRows;
}

- (NSArray *)accessibilitySelectedRows {
    NSArray *accessibilityRows = [self accessibilityRows];
    return @[accessibilityRows[self.selectedRow]];
}

- (void)setAccessibilitySelectedRows:(NSArray *)selectedRows {
    if (selectedRows.count == 1) {
        NSArray *accessibilityRows = [self accessibilityRows];
        NSInteger selectedRow = [accessibilityRows indexOfObject:selectedRows.firstObject];
        if (selectedRow != NSNotFound) {
            self.selectedRow = selectedRow;
        }
    }
}

@end
