/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The basic controller for the demo app. An instance exists inside the MainMenu.xib file.
 */

#import "ATComplexTableViewController.h"
#import "ATColorView.h"
#import "ATTableCellView.h"
#import "ATObjectTableRowView.h"
#import "ATDesktopEntity.h"
#import "ATColorTableController.h"

@interface ATComplexTableViewController () <NSTableViewDelegate, NSTableViewDataSource, ATColorTableControllerDelegate, NSSplitViewDelegate>

@property (weak) IBOutlet NSImageView *imageViewMain;
@property (weak) IBOutlet ATColorView *colorViewMain;

@property (strong) NSMutableArray *observedVisibleItems;
@property (strong) NSTimer *animationDoneTimer;
@property (strong) NSWindow *windowForAnimation;

@property (weak) IBOutlet NSSplitView *mainSplitView;
@property (weak) IBOutlet NSTableView *tableViewMain;

@property (strong) IBOutlet NSImageView *imageViewForTransition;

@property (strong) NSMutableArray *tableContents;
@property (assign) BOOL useSmallRowHeight;
@property (assign) NSInteger rowForEditingColor;

@property (weak) IBOutlet NSTextField *txtFldFromRow;
@property (weak) IBOutlet NSTextField *txtFldToRow;
@property (weak) IBOutlet NSTextField *txtFldRowToEdit;

@end


#pragma mark -

@implementation ATComplexTableViewController

- (void)dealloc {
    // Stop any observations that we may have.
    for (ATDesktopEntity *imageEntity in self.observedVisibleItems) {
        if ([imageEntity isKindOfClass:[ATDesktopImageEntity class]]) {
            [imageEntity removeObserver:self forKeyPath:ATEntityPropertyNamedThumbnailImage];
        }
    }
}

- (NSString *)windowNibName {
    return @"ATComplexTableViewWindow";
}

- (void)windowDidLoad {
    [super windowDidLoad];
        
    // Setup our content to be the contents of the Desktop Pictures folder.
    NSURL *picturesURL =
        [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSLocalDomainMask].lastObject;
    picturesURL = [picturesURL URLByAppendingPathComponent:@"Desktop Pictures"];
    ATDesktopFolderEntity *primaryFolder = [[ATDesktopFolderEntity alloc] initWithFileURL:picturesURL];
    
    // Create a flat array of ATDesktopFolderEntity and ATDesktopImageEntity objects to display.
    _tableContents = [NSMutableArray array];
    
    // We first do a pass over the children and add all the images under the "Desktop Pictures" category.
    [self.tableContents addObject:primaryFolder];
    for (ATDesktopEntity *entity in primaryFolder.children) {
        if ([entity isKindOfClass:[ATDesktopImageEntity class]]) {
            [self.tableContents addObject:entity];
        }
    }

    // Then do another pass through and add all the folders - including their children.
    // A recursive loop could be used too, but we want to only go one level deep.
    //
    for (ATDesktopEntity *entity in primaryFolder.children) {
        if ([entity isKindOfClass:[ATDesktopFolderEntity class]]) {
            [self.tableContents addObject:entity];
            ATDesktopFolderEntity *subFolder = (ATDesktopFolderEntity *)entity;
            for (ATDesktopEntity *subFolderChildEntity in subFolder.children) {
                if ([subFolderChildEntity isKindOfClass:[ATDesktopImageEntity class]]) {
                    [self.tableContents addObject:subFolderChildEntity];
                }
            }
        }
    }
    
    self.colorViewMain.drawBorder = YES;
    self.colorViewMain.backgroundColor = [NSColor whiteColor];
    
    // Initialize the main image view to our current desktop background.
    NSImage *initialImage = [[NSImage alloc] initByReferencingURL:[[NSWorkspace sharedWorkspace] desktopImageURLForScreen:[NSScreen mainScreen]]];
    self.imageViewMain.image = initialImage;
    self.tableViewMain.doubleAction = @selector(tblvwDoubleClick:);
    self.tableViewMain.target = self;
    [self.tableViewMain reloadData];
    
    // Allow drags to go everywhere.
    [self.tableViewMain setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
}

- (ATDesktopEntity *)entityForRow:(NSInteger)row {
    return (ATDesktopEntity *)self.tableContents[row];
}

- (ATDesktopImageEntity *)imageEntityForRow:(NSInteger)row {
    id result = row != -1 ? self.tableContents[row] : nil;
    if ([result isKindOfClass:[ATDesktopImageEntity class]]) {
        return result;
    }
    return nil;
}

- (void)reloadRowForEntity:(id)object {
    NSInteger row = [self.tableContents indexOfObject:object];
    if (row != NSNotFound) {
        ATDesktopImageEntity *entity = [self imageEntityForRow:row];
        ATTableCellView *cellView = [self.tableViewMain viewAtColumn:0 row:row makeIfNecessary:NO];
        if (cellView) {
            // Fade the imageView in, and fade the progress indicator out.
            [NSAnimationContext beginGrouping];
            [NSAnimationContext currentContext].duration = 0.8;
            cellView.imageView.alphaValue = 0;
            cellView.imageView.image = entity.thumbnailImage;
            cellView.imageView.hidden = NO;
            cellView.imageView.animator.alphaValue = 1.0;
            cellView.progessIndicator.hidden = YES;
            [NSAnimationContext endGrouping];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:ATEntityPropertyNamedThumbnailImage]) {
        // Find the row and reload it.
        // Note that KVO notifications may be sent from a background thread (in this case, we know they will be)
        // We should only update the UI on the main thread, and in addition,
        // we use NSRunLoopCommonModes to make sure the UI updates when a modal window is up.
        //
        [self performSelectorOnMainThread:@selector(reloadRowForEntity:)
                               withObject:object
                            waitUntilDone:NO
                                    modes:@[NSRunLoopCommonModes]];
    }
}


#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.tableContents.count;
}

- (id <NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
    // Support for us being a dragging source.
    return [self entityForRow:row];
}


#pragma mark - NSTableViewDelegate

- (void)tableView:(NSTableView *)tableView didRemoveRowView:(ATObjectTableRowView *)rowView forRow:(NSInteger)row {
    // Stop observing visible things.
    ATDesktopImageEntity *imageEntity = rowView.objectValue;
    NSInteger index = imageEntity ? [self.observedVisibleItems indexOfObject:imageEntity] : NSNotFound;
    if (index != NSNotFound) {
        [imageEntity removeObserver:self forKeyPath:ATEntityPropertyNamedThumbnailImage];
        [self.observedVisibleItems removeObjectAtIndex:index];
    }    
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    // Make the row view keep track of our main model object.
    ATObjectTableRowView *result = [[ATObjectTableRowView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
    result.objectValue = [self entityForRow:row];
    return result;    
}

// We want to make "group rows" for the folders.
- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row {
    if ([[self entityForRow:row] isKindOfClass:[ATDesktopFolderEntity class]]) {
        return YES;
    } else {
        return NO;
    }
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    ATDesktopEntity *entity = [self entityForRow:row];
    if ([entity isKindOfClass:[ATDesktopFolderEntity class]]) {
        NSTextField *textField = [tableView makeViewWithIdentifier:@"TextCell" owner:self];
        textField.stringValue = entity.title;
        return textField;
    } else {
        ATTableCellView *cellView = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
        ATDesktopImageEntity *imageEntity = (ATDesktopImageEntity *)entity;
        cellView.textField.stringValue = entity.title;
        cellView.subTitleTextField.stringValue = imageEntity.fillColorName;
        cellView.colorView.backgroundColor = imageEntity.fillColor;
        cellView.colorView.drawBorder = YES;

        // Use KVO to observe for changes of the thumbnail image.
        if (self.observedVisibleItems == nil) {
            _observedVisibleItems = [NSMutableArray new];
        }
        if (![self.observedVisibleItems containsObject:entity]) {
            [imageEntity addObserver:self forKeyPath:ATEntityPropertyNamedThumbnailImage options:0 context:nil];
            [imageEntity loadImage];
            [self.observedVisibleItems addObject:imageEntity];
        }
        
        // Hide/show progress based on the thumbnail image being loaded or not.
        if (imageEntity.thumbnailImage == nil) {
            cellView.progessIndicator.hidden = NO;
            [cellView.progessIndicator startAnimation:nil];
            cellView.imageView.hidden = YES;
        } else {
            cellView.imageView.image = imageEntity.thumbnailImage;
        }
        
        // Size/hide things based on the row size.
        [cellView layoutViewsForSmallSize:self.useSmallRowHeight animated:NO];
        return cellView;
    }
}    

// We make the "group rows" have the standard height, while all other image rows have a larger height.
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    if ([[self entityForRow:row] isKindOfClass:[ATDesktopFolderEntity class]]) {
        return tableView.rowHeight;
    } else {
        return self.useSmallRowHeight ? 30.0 : 75.0;
    }
}

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
    // We don't want to change the selection if the user clicked in the fill color area.
    NSInteger row = tableView.clickedRow;
    if (row != -1 && ![self tableView:tableView isGroupRow:row]) {
        ATTableCellView *cellView = [self.tableViewMain viewAtColumn:0 row:row makeIfNecessary:NO];
        if (cellView) {
            // Use hit testing to see if is a color view; if so, don't let it change the selection.
            NSPoint windowPoint = NSApp.currentEvent.locationInWindow;
            NSPoint point = [cellView.superview convertPoint:windowPoint fromView:nil];
            NSView *view = [cellView hitTest:point];
            if ([view isKindOfClass:[ATColorView class]]) {
                // Don't allow the selection change.
                return tableView.selectedRowIndexes;
            }
        }
    }
    return proposedSelectionIndexes;
}

#pragma mark - Table Animation

- (void)animationDoneTimerFired:(NSTimer *)timer {
    _animationDoneTimer = nil;
    
    // Set the normal one to have the final image and alpha value.
    // Set the image and update us before ordering out the animation window.
    self.imageViewMain.image = self.imageViewForTransition.image;
    self.imageViewMain.alphaValue = 1.0;
    
    // This displays right now, and prevents flicker if the animation window orders out before our display happened.
    [self.imageViewMain.window displayIfNeeded];
    
    // Hide the animation window.
    [self.windowForAnimation orderOut:nil];
}

- (void)ensureAnimationWindowCreated {
    if (self.windowForAnimation == nil) {
        NSRect contentRect = self.imageViewForTransition.frame;
        contentRect.origin = NSZeroPoint;
        self.imageViewForTransition.frame = contentRect;
        _windowForAnimation = [[NSWindow alloc] initWithContentRect:contentRect styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
        self.windowForAnimation.releasedWhenClosed = NO;
        self.windowForAnimation.opaque = NO;
        self.windowForAnimation.backgroundColor = [NSColor clearColor];
        
        // For ease of use, we setup the imageViewForTransition in the nib and add it as a subview.
        [self.windowForAnimation.contentView addSubview:self.imageViewForTransition];
    }
}

- (NSRect)screenImageRectForRow:(NSInteger)row {
    NSRect result = NSZeroRect;
    // We always want to try to get a view back to do the animation from that rect.
    ATTableCellView *cellView = [self.tableViewMain viewAtColumn:0 row:row makeIfNecessary:YES];
    if (cellView) {
        result = [cellView.imageView convertRect:cellView.imageView.bounds toView:nil];
        NSRect convertedRect = [cellView.window convertRectToScreen:NSMakeRect(result.origin.x, result.origin.y, 0.0, 0.0)];
        result.origin = NSMakePoint(convertedRect.origin.x, convertedRect.origin.y);
    }
    return result;
}

- (NSRect)finalScreenImageRect {
    // We are animating to right over the image view's frame. Convert to the right screen coordinates and animate the window there.
    NSRect finalImageFrame = [self.imageViewMain.superview convertRect:self.imageViewMain.frame toView:nil];
    NSRect convertedRect = [self.window convertRectToScreen:NSMakeRect(finalImageFrame.origin.x, finalImageFrame.origin.y, 0.0, 0.0)];
    finalImageFrame.origin = NSMakePoint(convertedRect.origin.x, convertedRect.origin.y);
    
    return finalImageFrame;
}

- (void)stopExistingTimerIfNeeded {
    // We want to stop any previous animations.
    if (self.animationDoneTimer != nil) {
        [self.animationDoneTimer invalidate];
        _animationDoneTimer = nil;
    }    
}

- (void)animateImageFromRow:(NSInteger)row {
    [self stopExistingTimerIfNeeded];

    // We create a window to do the animation.
    // The purpose of using a window is to allow an animation to happen from a non-layer backed view to over a layer-backed view.
    // We easily could use a sibling view if everything was layer backed, or non-layer backed.
    [self ensureAnimationWindowCreated];
    
    // Grab our model object for this row
    ATDesktopImageEntity *entity = [self imageEntityForRow:row];
    
    // Set some initial state
    NSRect startingWindowFrame = [self screenImageRectForRow:row];
    [self.windowForAnimation setFrame:startingWindowFrame display:NO];
    self.imageViewForTransition.image = entity.thumbnailImage;
    self.imageViewMain.alphaValue = 1.0;
    
    // Bring the window above our existing window.
    [self.windowForAnimation orderFront:nil];

    // We want to sync all the animations together. We use a grouping to do that.
    [NSAnimationContext beginGrouping]; 
    {
        NSTimeInterval animationDuration = 0.4;
        // Do a slow animation if the shift key is down
        if (([NSEvent modifierFlags] & NSEventModifierFlagShift) != 0) {
            animationDuration *= 4;
        }
        
        [NSAnimationContext currentContext].duration = animationDuration;
        
        NSRect finalImageFrame = [self finalScreenImageRect];
        [[self.windowForAnimation animator] setFrame:finalImageFrame display:YES];

        // Alpha/opacity animations only work for layer-backed views.
        [self.imageViewMain animator].alphaValue = 0.25;
        
        // Also, animate the background color. This is done with the layer. See ATColorView.h/.m
        [self.colorViewMain animator].backgroundColor = entity.fillColor;
        
        // At the end of the animation we want to do some cleanup.
        // We keep track of the timer so we can stop the operation if we need to.
        _animationDoneTimer =
            [NSTimer scheduledTimerWithTimeInterval:animationDuration
                                             target:self
                                           selector:@selector(animationDoneTimerFired:)
                                           userInfo:nil
                                            repeats:NO];
    }    
    [NSAnimationContext endGrouping];
}


#pragma mark - NSSplitViewDelegate

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    return 200;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
    // Make sure the view on the right has at least 200 px wide
    CGFloat splitViewWidth = splitView.bounds.size.width;
    return splitViewWidth - 200;
}


#pragma mark - ATColorTableControllerDelegate

- (void)colorTableController:(ATColorTableController *)controller didChooseColor:(NSColor *)color named:(NSString *)colorName {
    if (self.rowForEditingColor != -1) {
        // Update our model.
        ATDesktopImageEntity *entity = [self imageEntityForRow:self.rowForEditingColor];
        entity.fillColorName = colorName;
        entity.fillColor = color;    

        // Update the view; we could reload things, but this is faster.
        ATTableCellView *cellView = [self.tableViewMain viewAtColumn:0 row:self.rowForEditingColor makeIfNecessary:NO];
        cellView.colorView.backgroundColor = color;
        cellView.subTitleTextField.stringValue = colorName;
    } else {
        // With no row we are just setting the background color.
        self.colorViewMain.backgroundColor = color;
    }
}


#pragma mark - Actions

- (IBAction)btnSetAsDesktopWallpaperClick:(id)sender {
    NSInteger selectedRow = self.tableViewMain.selectedRow;
    if (selectedRow != -1) {
        ATDesktopEntity *entity = self.tableContents[selectedRow];
        if ([entity isKindOfClass:[ATDesktopImageEntity class]]) {
            ATDesktopImageEntity *desktopImageEntity = (ATDesktopImageEntity *)entity;
            NSError *error;
            NSURL *imageURL = desktopImageEntity.fileURL;
            NSColor *fillColor = desktopImageEntity.fillColor;
            
            NSDictionary *options =
                @{NSWorkspaceDesktopImageFillColorKey: fillColor,
                  NSWorkspaceDesktopImageAllowClippingKey: @NO,
                  NSWorkspaceDesktopImageScalingKey: @(NSImageScaleProportionallyUpOrDown)};
            BOOL result = [[NSWorkspace sharedWorkspace] setDesktopImageURL:imageURL
                                                                  forScreen:[NSScreen screens].lastObject
                                                                    options:options
                                                                      error:&error];
            if (!result) {
                [NSApp presentError:error];
            }
        }
    }
}

- (void)editColorOnRow:(NSInteger)row {
    _rowForEditingColor = row;
    ATTableCellView *cellView = [self.tableViewMain viewAtColumn:0 row:row makeIfNecessary:NO];
    
    NSColor *color = cellView.colorView.backgroundColor;
    [ATColorTableController sharedColorTableController].delegate = self;
    [[ATColorTableController sharedColorTableController] editColor:color withPositioningView:cellView.colorView];
}

- (IBAction)cellColorViewClicked:(id)sender {
    // Find out what row it was in and edit that color with the popup
    NSInteger row = [self.tableViewMain rowForView:sender];
    if (row != -1) {
        [self editColorOnRow:row];
    }
}

- (IBAction)textTitleChanged:(id)sender {
    NSInteger row = [self.tableViewMain rowForView:sender];
    if (row != -1) {
        ATDesktopImageEntity *entity = [self imageEntityForRow:row];
        entity.title = [sender stringValue];
    }
}

- (IBAction)colorTitleChanged:(id)sender {
    NSInteger row = [self.tableViewMain rowForView:sender];
    if (row != -1) {
        ATDesktopImageEntity *entity = [self imageEntityForRow:row];
        entity.fillColorName = [sender stringValue];
    }
}

- (void)selectRowStartingAtRow:(NSInteger)row {
    if (self.tableViewMain.selectedRow == -1) {
        if (row == -1) {
            row = 0;
        }

        // Select the same or next row (if possible) but skip group rows
        while (row < self.tableViewMain.numberOfRows) {
            if (![self tableView:self.tableViewMain isGroupRow:row]) {
                [self.tableViewMain selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
                return;
            }
            row++;
        }
        row = self.tableViewMain.numberOfRows - 1;
        while (row >= 0) {
            if (![self tableView:self.tableViewMain isGroupRow:row]) {
                [self.tableViewMain selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
                return;
            }
            row--;
        }
    }
}

- (IBAction)btnRemoveRowClick:(id)sender {
    NSInteger row = [self.tableViewMain rowForView:sender];
    if (row != -1) {
        [self.tableContents removeObjectAtIndex:row];
        [self.tableViewMain removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row] withAnimation:NSTableViewAnimationEffectFade];
        [self selectRowStartingAtRow:row];
    }
}

- (IBAction)btnRemoveAllSelectedRowsClick:(id)sender {
    [self.tableContents removeObjectsAtIndexes:self.tableViewMain.selectedRowIndexes];
    [self.tableViewMain removeRowsAtIndexes:self.tableViewMain.selectedRowIndexes withAnimation:NSTableViewAnimationEffectFade];
}

- (IBAction)btnInsertNewRow:(id)sender {
    NSURL *url = [[NSWorkspace sharedWorkspace] desktopImageURLForScreen:[NSScreen mainScreen]];
    ATDesktopImageEntity *entity = [[ATDesktopImageEntity alloc] initWithFileURL:url];
    entity.fillColor = self.colorViewMain.backgroundColor;
    entity.fillColorName = @"Untitled Color";
    NSInteger index = self.tableViewMain.selectedRow;
    if (index == -1) {
        if (self.tableViewMain.numberOfRows == 0) {
            index = 0;
        } else {
            index = 1;
        }
    }
    
    [self.tableContents insertObject:entity atIndex:index];
    [self.tableViewMain beginUpdates];
    [self.tableViewMain insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationEffectFade];
    [self.tableViewMain scrollRowToVisible:index];
    [self.tableViewMain endUpdates];
}

- (IBAction)mainColorViewClicked:(id)sender {
    _rowForEditingColor = -1;
    
    NSColor *color = self.colorViewMain.backgroundColor;
    [ATColorTableController sharedColorTableController].delegate = self;
    [[ATColorTableController sharedColorTableController] editColor:color withPositioningView:self.colorViewMain];
}

// This is called when the the NSImageView changes.
- (IBAction)cellBtnAnimateImageClick:(id)sender {
    NSInteger selectedRow = [self.tableViewMain rowForView:sender];
    if (selectedRow != -1) {
        [self.tableViewMain scrollRowToVisible:selectedRow];
        
        // Only animate if the thumbnail image is loaded.
        ATDesktopImageEntity *entity = self.tableContents[selectedRow];
        if (entity.thumbnailImage != nil) {
            [self animateImageFromRow:selectedRow];
        }
    } else {
        self.imageViewMain.image = nil;
    }
}

- (IBAction)chkbxHorizontalGridLineClicked:(id)sender {
    if (((NSButton *)sender).state == 0) {
        self.tableViewMain.gridStyleMask = NSTableViewGridNone;
    } else {
        self.tableViewMain.gridStyleMask = NSTableViewSolidHorizontalGridLineMask;
    }
}

- (IBAction)chkbxUseSmallRowHeightClicked:(id)sender {
    _useSmallRowHeight = ((NSButton *)sender).state == 1;
    // Reload the height for all non group rows.
    NSMutableIndexSet *indexesToNoteHeightChanges = [NSMutableIndexSet indexSet];
    for (NSUInteger row = 0; row < self.tableContents.count; row++) {
        if (![[self entityForRow:row] isKindOfClass:[ATDesktopFolderEntity class]]) {
            [indexesToNoteHeightChanges addIndex:row];
        }
    }
    // We also want to synchronize our own animations with the height change.
    // We do this by creating our own animation grouping.
    [NSAnimationContext beginGrouping];
    [NSAnimationContext currentContext].duration = 1.5;
    
    // Update all the current visible views animated in sync with the row heights.
    [self.tableViewMain enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
        for (NSUInteger i = 0; i < self.tableViewMain.tableColumns.count; i++) {
            NSView *view = [self.tableViewMain viewAtColumn:i row:row makeIfNecessary:NO];
            if (view && [view isKindOfClass:[ATTableCellView class]]) {
                [(ATTableCellView *)view layoutViewsForSmallSize:self.useSmallRowHeight animated:YES];
            }
        }
    }];
    
    [self.tableViewMain noteHeightOfRowsWithIndexesChanged:indexesToNoteHeightChanges];
    
    [NSAnimationContext endGrouping];
}

- (IBAction)chkbxFloatGroupRowsClicked:(id)sender {
    BOOL checked = ((NSButton *)sender).state == 1;
    self.tableViewMain.floatsGroupRows = checked;
}

- (IBAction)btnBeginUpdatesClicked:(id)sender {
    [self.tableViewMain beginUpdates];
}

- (IBAction)btnEndUpdatesClicked:(id)sender {
    [self.tableViewMain endUpdates];
}

- (IBAction)btnMoveRowClick:(id)sender {
    NSInteger fromRow = self.txtFldFromRow.integerValue;
    NSInteger toRow = self.txtFldToRow.integerValue;
    
    [self.tableViewMain beginUpdates];

    [self.tableViewMain moveRowAtIndex:fromRow toIndex:toRow];
    
    id object = self.tableContents[fromRow];
    [self.tableContents removeObjectAtIndex:fromRow];
    [self.tableContents insertObject:object atIndex:toRow];
        
    [self.tableViewMain endUpdates];
}

- (IBAction)tblvwDoubleClick:(id)sender {
    NSInteger row = self.tableViewMain.selectedRow;
    if (row != -1) {
        ATDesktopEntity *entity = [self entityForRow:row];
        [[NSWorkspace sharedWorkspace] selectFile:entity.fileURL.path inFileViewerRootedAtPath:@""];
    }
}

- (IBAction)btnManuallyBeginEditingClick:(id)sender {
    NSInteger row = self.txtFldRowToEdit.integerValue;
    [self.tableViewMain editColumn:0 row:row withEvent:nil select:YES];
}

- (NSIndexSet *)indexesToProcessForContextMenu {
    NSIndexSet *selectedIndexes = self.tableViewMain.selectedRowIndexes;
    // If the clicked row was in the selectedIndexes, then we process all selectedIndexes.
    // Otherwise, we process just the clickedRow.
    //
    if (self.tableViewMain.clickedRow != -1 && ![selectedIndexes containsIndex:self.tableViewMain.clickedRow]) {
        selectedIndexes = [NSIndexSet indexSetWithIndex:self.tableViewMain.clickedRow];
    }
    return selectedIndexes;    
}

- (IBAction)mnuRevealInFinderSelected:(id)sender {
    NSIndexSet *selectedIndexes = [self indexesToProcessForContextMenu];
    [selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop) {
        ATDesktopEntity *entity = [self entityForRow:row];
        [[NSWorkspace sharedWorkspace] selectFile:entity.fileURL.path inFileViewerRootedAtPath:@""];
    }];
}

- (IBAction)btnRevealInFinderSelected:(id)sender {
    NSInteger row = [self.tableViewMain rowForView:sender];
    ATDesktopEntity *entity = [self entityForRow:row];
    [[NSWorkspace sharedWorkspace] selectFile:entity.fileURL.path inFileViewerRootedAtPath:@""];
}

- (IBAction)mnuRemoveRowSelected:(id)sender {
    NSIndexSet *indexes = [self indexesToProcessForContextMenu];
    [self.tableViewMain beginUpdates];
    [self.tableContents removeObjectsAtIndexes:indexes];
    [self.tableViewMain removeRowsAtIndexes:indexes withAnimation:NSTableViewAnimationEffectFade];
    [self.tableViewMain endUpdates];
}

- (IBAction)btnChangeSelectionAnimated:(id)sender {
    if (self.tableViewMain.selectedRow != -1) {
        [[self.tableViewMain animator] selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    } else {
        [[self.tableViewMain animator] selectRowIndexes:[NSIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
    }
}

@end
