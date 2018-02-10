/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A controller used by the ATColorTableController to edit the color property.
 */

#import "ATColorTableController.h"
#import "ATTableCellView.h"
#import "ATColorView.h"

@interface ATColorTableController () <NSTableViewDelegate, NSTableViewDataSource, NSPopoverDelegate>

@property (weak) IBOutlet NSTableView *tableColorList;

@property (strong) NSColorList *colorList;
@property (strong) NSArray *colorNames;
@property (strong) NSPopover *popover;

@end


#pragma mark -

@implementation ATColorTableController

@dynamic selectedColor, selectedColorName;

+ (ATColorTableController *)sharedColorTableController {
    static ATColorTableController *gSharedColorTableController = nil;
    if (gSharedColorTableController == nil) {
        gSharedColorTableController = [[[self class] alloc] initWithNibName:@"ATColorTable" bundle:[NSBundle bundleForClass:[self class]]];
    }
    return gSharedColorTableController;
}

- (void)loadView {
    [super loadView];
    
    _colorList = [NSColorList colorListNamed:@"Crayons"];
    _colorNames = self.colorList.allKeys;
    self.tableColorList.intercellSpacing = NSMakeSize(3, 3);
    self.tableColorList.target = self;
    self.tableColorList.action = @selector(tableViewAction:);
}

- (NSColor *)selectedColor {
    NSString *name = self.selectedColorName;
    if (name != nil) {
        return [self.colorList colorWithKey:name];
    } else {
        return nil;
    }
}

- (NSString *)selectedColorName {
    if (self.tableColorList.selectedRow != -1) {
        return self.colorNames[self.tableColorList.selectedRow];
    } else {
        return nil;
    }
}

- (void)_selectColor:(NSColor *)color {
    // Search for that color in our list.
    NSInteger row = 0;
    for (NSString *name in self.colorNames) {
        NSColor *colorInList = [self.colorList colorWithKey:name];
        if ([color isEqual:colorInList]) {
            break;
        }
        row++;
    }    

    // This is done in an animated fashion
    if (row != -1) {
        [self.tableColorList scrollRowToVisible:row];
        [[self.tableColorList animator] selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    } else {
        [self.tableColorList scrollRowToVisible:0];
        [[self.tableColorList animator] selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    }
}

- (void)makePopoverIfNeeded {
    if (self.popover == nil) {
        // Create and setup our window.
        _popover = [[NSPopover alloc] init];
        
        // The popover retains us and we retain the popover. We drop the popover whenever it is closed to avoid a cycle.
        self.popover.contentViewController = self;
        self.popover.behavior = NSPopoverBehaviorTransient;
        self.popover.delegate = self;
    }
}

- (void)editColor:(NSColor *)color withPositioningView:(NSView *)positioningView {
    [self makePopoverIfNeeded];
    [self _selectColor:color];
    [self.popover showRelativeToRect:positioningView.bounds ofView:positioningView preferredEdge:NSMinYEdge];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.colorNames.count;
}

- (id)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *name = self.colorNames[row];
    NSColor *color = [self.colorList colorWithKey:name];
    
    // In IB, the TableColumn's identifier is set to "Automatic".
    // The ATTableCellView's is also set to "Automatic". IB then keeps the two in sync,
    // and we don't have to worry about setting the identifier.
    //
    ATTableCellView *result = [tableView makeViewWithIdentifier:tableColumn.identifier owner:nil];
    result.colorView.backgroundColor = color;
    result.colorView.drawBorder = YES;
    result.subTitleTextField.stringValue = name;
    return result;
}

- (void)tableViewAction:(id)sender {
    [self.popover close];
    if ([self.delegate respondsToSelector:@selector(colorTableController:didChooseColor:named:)]) {
        [self.delegate colorTableController:self didChooseColor:self.selectedColor named:self.selectedColorName];
    }
}

- (void)popoverDidClose:(NSNotification *)notification {
    // Free the popover to avoid a cycle.
    // We could also just break the contentViewController property, and reset it when we show the popover.
    _popover = nil;
}

@end
