/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The main window controller for choosing different test windows to open.
 */

#import "ATMainWindowController.h"
#import "ATComplexTableViewController.h"
#import "ATComplexOutlineController.h"
#import "ATBasicTableViewWindowController.h"

// Keys used for bindings
#define ATKeyClass @"class"
#define ATKeyName @"name"
#define ATKeyShortDescription @"shortDescription"
#define ATKeyImagePreview @"imagePreview"

@interface ATMainWindowController () <NSTableViewDelegate, NSTableViewDataSource>

@property (strong) NSMutableArray *tableContents;

@end


#pragma mark -

@implementation ATMainWindowController

- (void)awakeFromNib {
    [super awakeFromNib];

    // Note that "tableContents" is the backing of our NSArrayController which populates our NSTableView content.
    
    _tableContents = [NSMutableArray array];
    [self willChangeValueForKey:@"_tableContents"];
    
    [self.tableContents addObject:@{ATKeyClass: [ATBasicTableViewWindowController class],
                                    ATKeyName: @"Basic Table View",
                                    ATKeyShortDescription: @"A Minimal View Based Implementation",
                                    ATKeyImagePreview: [NSImage imageNamed: @"ATBasicTableViewWindowPreview"]}];
    
    [self.tableContents addObject:@{ATKeyClass: [ATComplexTableViewController class],
                                    ATKeyName: @"Complex Table View",
                                    ATKeyShortDescription: @"A Complex Cell Example",
                                    ATKeyImagePreview: [NSImage imageNamed: @"ATComplexTableViewControllerPreview"]}];
    
    
    [self.tableContents addObject:@{ATKeyClass: [ATComplexOutlineController class],
                                    ATKeyName: @"Complex Outline View",
                                    ATKeyShortDescription: @"A Complex Bindings Example",
                                    ATKeyImagePreview: [NSImage imageNamed: @"ATComplexOutlineControllerPreview"]}];
    
    [self didChangeValueForKey:@"_tableContents"];
}

@end
