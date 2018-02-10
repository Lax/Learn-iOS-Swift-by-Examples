/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates the most basic dataSource/delegate implementation of a View Based NSTableView.
 */

#import "ATBasicTableViewWindowController.h"

@interface ATBasicTableViewWindowController () <NSTableViewDelegate, NSTableViewDataSource>

// An array of dictionaries that contain the contents to display
@property (strong) NSMutableArray *tableContents;
@property (weak) IBOutlet NSTableView *tableView;

@end

/* Notes on how this demo window was created:

    In ATBasicTableViewWindow.xib in IB: 
    The nib has the "File's Owner" Class Identity set to ATBasicTableViewWindowController (this class).
    The NSTableView in the nib has the 'delegate' and 'dataSource' outlets set to the "File's Owner" (this class).
    The first NSTableColumn in the NSTableView has the 'identifier' set to "MainCell".
    The second NSTableColumn in the NSTableView has the 'identifier' set to "SizeCell". 
    The NSTableView has two reuse identifier assocations: "MainCell" and "SizeCell" are both associated with the nib ATBasicTableViewCells.xib.
    The "File's Owner" _tableView outlet was set to the nib in the window.
 
    In ATBasicTableViewCells.xib in IB:
    The nib has the "File's Owner" Class Identity set to ATBasicTableViewWindowController (this class).
    Two cells were added to the nib.
    The identifier for the first is set to "MainCell", and the second "SizeCell". 
    Each NSTableCellView already had the 'textField' outlet properly set to the NSTextField in the cell by IB when the NSTableCellView was created.
 */

@implementation ATBasicTableViewWindowController

- (NSString *)windowNibName {
    return @"ATBasicTableViewWindow";
}

- (void)windowDidLoad {
    [super windowDidLoad];
        
    NSArray *tableData = @[@"NSQuickLookTemplate",
                           @"NSBluetoothTemplate",
                           @"NSIChatTheaterTemplate",
                           @"NSSlideshowTemplate",
                           @"NSActionTemplate",
                           @"NSSmartBadgeTemplate",
                           @"NSIconViewTemplate",
                           @"NSListViewTemplate",
                           @"NSColumnViewTemplate",
                           @"NSFlowViewTemplate",
                           @"NSPathTemplate",
                           @"NSInvalidDataFreestandingTemplate",
                           @"NSLockLockedTemplate",
                           @"NSLockUnlockedTemplate",
                           @"NSGoRightTemplate",
                           @"NSGoLeftTemplate",
                           @"NSRightFacingTriangleTemplate",
                           @"NSLeftFacingTriangleTemplate",
                           @"NSAddTemplate",
                           @"NSRemoveTemplate",
                           @"NSRevealFreestandingTemplate",
                           @"NSFollowLinkFreestandingTemplate",
                           @"NSEnterFullScreenTemplate",
                           @"NSExitFullScreenTemplate",
                           @"NSStopProgressTemplate",
                           @"NSStopProgressFreestandingTemplate",
                           @"NSRefreshTemplate",
                           @"NSRefreshFreestandingTemplate",
                           @"NSBonjour",
                           @"NSComputer",
                           @"NSFolderBurnable",
                           @"NSFolderSmart",
                           @"NSFolder",
                           @"NSNetwork",
                           @"NSMobileMe",
                           @"NSMultipleDocuments",
                           @"NSUserAccounts",
                           @"NSPreferencesGeneral",
                           @"NSAdvanced",
                           @"NSInfo",
                           @"NSFontPanel",
                           @"NSColorPanel",
                           @"NSUser",
                           @"NSUserGroup",
                           @"NSEveryone",  
                           @"NSUserGuest",
                           @"NSMenuOnStateTemplate",
                           @"NSMenuMixedStateTemplate",
                           @"NSApplicationIcon",
                           @"NSTrashEmpty",
                           @"NSTrashFull",
                           @"NSHomeTemplate",
                           @"NSBookmarksTemplate",
                           @"NSCaution",
                           @"NSStatusAvailable",
                           @"NSStatusPartiallyAvailable",
                           @"NSStatusUnavailable",
                           @"NSStatusNone"];
    
    // Load up our sample data.
    _tableContents = [NSMutableArray array];
    
    // Our model consists of an array of dictionaries with Name/Image key pairs.
    for (NSString *templateImageItem in tableData) {
        NSImage *image = [NSImage imageNamed:templateImageItem];
        
        NSDictionary *dictionary = @{@"Name": templateImageItem, @"Image": image};
        [self.tableContents addObject:dictionary];
    }
    
    [self.tableView reloadData];
}

// The only essential/required tableview dataSource method.
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.tableContents.count;
}

// This method is optional if you use bindings to provide the data.
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    // Group our "model" object, which is a dictionary.
    NSDictionary *dictionary = self.tableContents[row];
    
    // In IB the tableColumn has the identifier set to the same string as the keys in our dictionary.
    NSString *identifier = tableColumn.identifier;
    
    if ([identifier isEqualToString:@"MainCell"]) {
        // We pass us as the owner so we can setup target/actions into this main controller object.
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:identifier owner:self];
        // Then setup properties on the cellView based on the column.
        cellView.textField.stringValue = dictionary[@"Name"];
        cellView.imageView.objectValue = dictionary[@"Image"];
        return cellView;
    } else if ([identifier isEqualToString:@"SizeCell"]) {
        NSTextField *textField = [tableView makeViewWithIdentifier:identifier owner:self];
        NSImage *image = dictionary[@"Image"];
        NSSize size = image ? image.size : NSZeroSize;
        NSString *sizeString = [NSString stringWithFormat:@"%.0fx%.0f", size.width, size.height];
        textField.objectValue = sizeString;
        return textField;
    } else {
        NSAssert1(NO, @"Unhandled table column identifier %@", identifier);
    }
    return nil;
}

@end
