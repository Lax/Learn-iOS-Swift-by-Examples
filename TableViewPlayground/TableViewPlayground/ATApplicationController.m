/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The main demo application controller. This class is the delegate for the main NSApp instance. This class manages the windows that are open, and allows the user to create a new one with the 'Available Sample Windows' table view. Bindings are used in the 'Available Sample Windows' table for the content. The TableView is bound to the tableContents, which is an array of NSDictionary objects that contain the information to disply.
 */

#import "ATApplicationController.h"

#import "ATMainWindowController.h"
#import "ATComplexTableViewController.h"
#import "ATComplexOutlineController.h"
#import "ATBasicTableViewWindowController.h"

#pragma mark -

@interface ATApplicationController ()

@property (strong) NSMutableArray *windowControllers;
@property (strong) IBOutlet ATMainWindowController *mainWindowController;

@end

/* Notes on how this demo window was created:
 
 In ATBasicTableViewWindow.xib in IB:
 The nib has the "File's Owner" Class Identity set to ATBasicTableViewWindowController (this class).
 The NSTableView in the nib has the 'delegate' and 'dataSource' outlets set to the "File's Owner" (this class).
 The first NSTableColumn in the NSTableView has the 'identifier' set to "MainCell".
 The second NSTableColumn in the NSTableView has the 'identifier' set to "SizeCell".
 The NSTableView has two reuse identifier assocations: "MainCell" and "SizeCell" are both associated with the nib ATBasicTableViewCells.xib.
 The "File's Owner" tableView outlet was set to the nib in the window.
 
 In ATBasicTableViewCells.xib in IB:
 The nib has the "File's Owner" Class Identity set to ATBasicTableViewWindowController (this class).
 Two cells were added to the nib.
 The identifier for the first is set to "MainCell", and the second "SizeCell".
 Each NSTableCellView already had the 'textField' outlet properly set to the NSTextField in the cell by IB when the NSTableCellView wsa created.
 */

#pragma mark -

@implementation ATApplicationController

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Create our three windows on startup.
    [self newWindowWithControllerClass:[ATBasicTableViewWindowController class]];
    [self newWindowWithControllerClass:[ATComplexTableViewController class]];
    [self newWindowWithControllerClass:[ATComplexOutlineController class]];
}

- (void)newWindowWithControllerClass:(Class)c {
    NSWindowController *controller = [[c alloc] init];
    if (_windowControllers == nil) {
        _windowControllers = [NSMutableArray array];
    }
    [self.windowControllers addObject:controller];
    [controller showWindow:self];
}

- (void)awakeFromNib {
    [super awakeFromNib];

    // Show our main window that creates additional windows.
    [self.mainWindowController showWindow:self];
    
    // Observe all windows closing so we can remove them from our array.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowClosed:) name:NSWindowWillCloseNotification object:nil];
}

- (void)windowClosed:(NSNotification *)note {
    NSWindow *window = note.object;
    for (NSWindowController *winController in self.windowControllers) {
        if (winController.window == window) {
            [self.windowControllers removeObject:winController];
            break;
        }
    }
}

@end
