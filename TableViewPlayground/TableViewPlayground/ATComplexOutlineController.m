/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The main controller for the "Complex Outline View" example window.
 */

#import "ATComplexOutlineController.h"
#import "ATTableCellView.h"
#import "ATColorView.h"
#import "ATDesktopEntity.h"

@interface ATComplexOutlineController ()

@property (strong) ATDesktopFolderEntity *rootContents;
@property (weak) IBOutlet NSOutlineView *outlineView;
@property (weak) IBOutlet NSPathControl *pathCtrlRootDirectory;
@property (strong) IBOutlet NSDateFormatter *sharedDateFormatter;

@property (strong) ATDesktopEntity *itemBeingDragged;

@end


#pragma mark -

@implementation ATComplexOutlineController

- (NSString *)windowNibName {
    return @"ATComplexOutlineWindow";
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Setup our content to be the contents of the Desktop Pictures folder.
    NSURL *picturesURL =
        [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSLocalDomainMask].lastObject;
    picturesURL = [picturesURL URLByAppendingPathComponent:@"Desktop Pictures"];
    _rootContents = [[ATDesktopFolderEntity alloc] initWithFileURL:picturesURL];
    
    [self.outlineView reloadData];
    [self.outlineView registerForDraggedTypes:@[(id)kUTTypeURL]];
    [self.outlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
}

#pragma mark - NSOutlineView

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil) {
        return self.rootContents.children.count;
    } else if ([item isKindOfClass:[ATDesktopFolderEntity class]]) {
        return ((ATDesktopFolderEntity *)item).children.count;
    } else {
        return 0;
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {
        return (self.rootContents.children)[index];
    } else {
        return (((ATDesktopFolderEntity *)item).children)[index];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [item isKindOfClass:[ATDesktopFolderEntity class]];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    // Every regular view uses bindings to the item. The "Date Cell" needs to have the date extracted from the fileURL
    if ([tableColumn.identifier isEqualToString:@"DateCell"]) {
        id dateValue;
        if ([[item fileURL] getResourceValue:&dateValue forKey:NSURLContentModificationDateKey error:nil]) {
            return dateValue;
        } else {
            return nil;
        }
    }
    return item;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return [item isKindOfClass:[ATDesktopFolderEntity class]];
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([item isKindOfClass:[ATDesktopFolderEntity class]]) {
        // Everything is setup in bindings
        return [outlineView makeViewWithIdentifier:@"GroupCell" owner:self];
    } else {
        NSView *result = [outlineView makeViewWithIdentifier:tableColumn.identifier owner:self];
        if ([result isKindOfClass:[ATTableCellView class]]) {
            ATTableCellView *cellView = (ATTableCellView *)result;
            // setup the color; we can't do this in bindings
            cellView.colorView.drawBorder = YES;
            cellView.colorView.backgroundColor = [item fillColor];
        }
        // Use a shared date formatter on the DateCell for better performance. Otherwise, it is encoded in every NSTextField
        if ([tableColumn.identifier isEqualToString:@"DateCell"]) {
            [(id)result setFormatter:self.sharedDateFormatter];
        }
        return result;
    }
    return nil;
}


#pragma mark - Drag and Drop

- (id <NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(id)item {
    return (id <NSPasteboardWriting>)item;
}

- (void)outlineView:(NSOutlineView *)outlineView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forItems:(NSArray *)draggedItems {
    _itemBeingDragged = nil;

    // If only one item is being dragged, mark it so we can reorder it with a special pboard indicator
    if (draggedItems.count == 1) {
        _itemBeingDragged = draggedItems.lastObject;
    }
}

- (NSDictionary *)_pasteboardReadingOptions {
    // Only file urls that contain images or folders
    NSMutableArray *fileTypes = [NSMutableArray arrayWithObject:(id)kUTTypeFolder];
    [fileTypes addObjectsFromArray:[NSImage imageTypes]];
    NSDictionary *options = @{NSPasteboardURLReadingFileURLsOnlyKey: @YES, NSPasteboardURLReadingContentsConformToTypesKey: fileTypes};
    return options;
}

/* When validating the contents of the pasteboard, it is best practice to use -canReadObjectForClasses:arrayWithObject:options: since it is possible for it to avoid reading and creating objects for every pasteboard item.
 */
- (BOOL)_containsAcceptableURLsFromPasteboard:(NSPasteboard *)draggingPasteboard {
    return [draggingPasteboard canReadObjectForClasses:@[[NSURL class]] options:[self _pasteboardReadingOptions]];
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
    // Only let dropping on the entire table or a folder
    if (item == nil || [item isKindOfClass:[ATDesktopFolderEntity class]]) {
        // If the sender is ourselves, then we accept it as a move or copy, depending on the modifier key
        if ([info draggingSource] == outlineView) {
            BOOL isCopy = [info draggingSourceOperationMask] == NSDragOperationCopy;
            if (isCopy) {
                info.animatesToDestination = YES;
                return NSDragOperationCopy;
            } else {
                if (self.itemBeingDragged) {
                    // We have a single item being dragged to move; validate if we can move it or not
                    // A move is only valid if the target isn't a child of the thing being dragged. We validate that now
                    id itemWalker = item;
                    while (itemWalker) {
                        if (itemWalker == self.itemBeingDragged) {
                            return NSDragOperationNone; // Can't do it!
                        }
                        itemWalker = [outlineView parentForItem:itemWalker];
                    }
                    return NSDragOperationMove;            
                } else {
                    // For multiple items, we do a copy and don't allow moving
                    info.animatesToDestination = YES;
                    return NSDragOperationCopy;
                }
            }        
        } else {
            // Only accept drops that have at least one URL on the pasteboard which contains an image or a folder
            if ([self _containsAcceptableURLsFromPasteboard:[info draggingPasteboard]]) {
                info.animatesToDestination = YES;
                return NSDragOperationCopy;
            }
        }
    }
    return NSDragOperationNone;
}

// Multiple item dragging support. Implementation of this method is required to change the drag images into what we want them to look like when over our view
- (void)outlineView:(NSOutlineView *)outlineView updateDraggingItemsForDrag:(id <NSDraggingInfo>)draggingInfo {
    if ([draggingInfo draggingSource] != outlineView) {
        // The source isn't us, so update the drag images
        // We will be doing an insertion; update the dragging items to have an appropriate image. We also iterate over generic pasteboard items, and set the imageComponentsProvider to nil so they will fade out.
        NSArray *classes = @[[ATDesktopEntity class], [NSPasteboardItem class]];
        
        // Create a copied temporary cell to draw to images
        NSTableColumn *tableColumn = self.outlineView.outlineTableColumn;
        
        // Create a new cell frame based on the basic attributes
        NSRect cellFrame = NSMakeRect(0, 0, tableColumn.width, outlineView.rowHeight);
        
        // Subtract out the intercellSpacing from the width only. The rowHeight is sans-spacing
        cellFrame.size.width -= outlineView.intercellSpacing.width;

        // Grab a basic view to use for creating sample images and data; we will reuse it for each dragged item
        ATTableCellView *tableCellView = [outlineView makeViewWithIdentifier:tableColumn.identifier owner:self];
        
        __block NSInteger validCount = 0;
        [draggingInfo enumerateDraggingItemsWithOptions:0 forView:self.outlineView classes:classes searchOptions:@{} usingBlock:^(NSDraggingItem *draggingItem, NSInteger index, BOOL *stop) {
            if ([draggingItem.item isKindOfClass:[ATDesktopEntity class]]) {
                ATDesktopEntity *entity = (ATDesktopEntity *)draggingItem.item;
                draggingItem.draggingFrame = cellFrame;
                draggingItem.imageComponentsProvider = ^(void) {
                    // Force the image to be generated right now, instead of lazily doing it
                    if ([entity isKindOfClass:[ATDesktopImageEntity class]]) {
                        ((ATDesktopImageEntity *)entity).image = [[NSImage alloc] initByReferencingURL:entity.fileURL];
                    }
                    // Setup the cell with this temporary data
                    tableCellView.objectValue = entity; // This is what bindings normally does for us. Our sub-views are bound to this value.
                    tableCellView.frame = cellFrame;
                    // Ask the cell view for the image components from that cell
                    return tableCellView.draggingImageComponents;
                };
                validCount++;
            } else {
                // Non-valid item (a generic NSPasteboardItem).
                // Make the drag images go away
                draggingItem.imageComponentsProvider = nil;
            }
        }];
        draggingInfo.numberOfValidItemsForDrop = validCount;
    }
}

- (void)_performInsertWithDragInfo:(id <NSDraggingInfo>)info parentItem:(ATDesktopFolderEntity *)destinationFolderEntity childIndex:(NSInteger)childIndex {
    // NSOutlineView's root is nil
    id outlineParentItem = destinationFolderEntity == self.rootContents ? nil : destinationFolderEntity;

    NSInteger outlineColumnIndex = [self.outlineView.tableColumns indexOfObject:self.outlineView.outlineTableColumn];
    
    // Enumerate all items dropped on us and create new model objects for them    
    NSArray *classes = @[[ATDesktopEntity class]];
    __block NSInteger insertionIndex = childIndex;
    
    [info enumerateDraggingItemsWithOptions:0 forView:self.outlineView classes:classes searchOptions:[self _pasteboardReadingOptions] usingBlock:^(NSDraggingItem *draggingItem, NSInteger index, BOOL *stop) {
        // the item is our new model object -- created by the classes via the pasteboard reading support
        ATDesktopEntity *entity = (ATDesktopEntity *)draggingItem.item;
        
        // Add it to the model
        [destinationFolderEntity.children insertObject:entity atIndex:insertionIndex];
        
        // Tell the outlineview of the change
        [self.outlineView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:insertionIndex] inParent:outlineParentItem withAnimation:NSTableViewAnimationEffectGap];
        
        // Update the final frame of the dragging item
        NSInteger row = [self.outlineView rowForItem:entity];
        draggingItem.draggingFrame = [self.outlineView frameOfCellAtColumn:outlineColumnIndex row:row];
        
        // Insert all children one after another
        insertionIndex++;
    }];    
}

- (void)_performDragReorderWithDragInfo:(id <NSDraggingInfo>)info parentItem:(ATDesktopFolderEntity *)destinationFolderEntity childIndex:(NSInteger)childIndex {
    ATDesktopFolderEntity *oldParent = [self.outlineView parentForItem:self.itemBeingDragged];
    if (oldParent == nil) oldParent = self.rootContents;
    NSInteger fromIndex = [oldParent.children indexOfObject:self.itemBeingDragged];
    [oldParent.children removeObjectAtIndex:fromIndex];
    if (oldParent == destinationFolderEntity) {
        // Consider the item being deleted before it is being inserted. 
        // This is because we are inserting *before* childIndex, and *not* after it (which is what the move API does).
        if (fromIndex < childIndex) {
            childIndex--;
        }
    }
    
    [destinationFolderEntity.children insertObject:self.itemBeingDragged atIndex:childIndex];
    
    // NSOutlineView doesn't have a way of setting the root item
    if (oldParent == self.rootContents) oldParent = nil;
    if (destinationFolderEntity == self.rootContents) destinationFolderEntity = nil;
    [self.outlineView moveItemAtIndex:fromIndex inParent:oldParent toIndex:childIndex inParent:destinationFolderEntity];
}    


- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(ATDesktopEntity *)item childIndex:(NSInteger)childIndex {
    ATDesktopFolderEntity *destinationFolderEntity = nil;
    if (item == nil) {
        destinationFolderEntity = self.rootContents;
    } else if ([item isKindOfClass:[ATDesktopFolderEntity class]]) {
        destinationFolderEntity = (ATDesktopFolderEntity *)item;
    } else {
        NSAssert(NO, @"Internal error: expecting a folder entity for dropping onto!");
    }

    // If it was a drop "on", then we add it at the start
    if (childIndex == NSOutlineViewDropOnItemIndex) {
        childIndex = 0;
    }
    
    [self.outlineView beginUpdates];
    // Are we copying the data or moving something?
    if (self.itemBeingDragged == nil || [info draggingSourceOperationMask] == NSDragOperationCopy) {
        // Yes, this is an insert from the pasteboard (even if it is a copy of itemBeingDragged)
        [self _performInsertWithDragInfo:info parentItem:destinationFolderEntity childIndex:childIndex];
    } else {
        [self _performDragReorderWithDragInfo:info parentItem:destinationFolderEntity childIndex:childIndex];
    }
    [self.outlineView endUpdates];
    
    _itemBeingDragged = nil;
    
    return YES;
}

- (void)_removeItemAtRow:(NSInteger)row {
    id item = [self.outlineView itemAtRow:row];
    ATDesktopFolderEntity *parent = (ATDesktopFolderEntity *)[self.outlineView parentForItem:item];
    if (parent == nil) {
        parent = self.rootContents;
    }
    NSInteger indexInParent = [parent.children indexOfObject:item];
    [parent.children removeObjectAtIndex:indexInParent];
    
    if (parent == self.rootContents) {
        parent = nil;
    }
    [self.outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:indexInParent]
                                  inParent:parent
                             withAnimation:NSTableViewAnimationEffectFade | NSTableViewAnimationSlideLeft];
}


#pragma mark - Actions

- (IBAction)pathCtrlValueChanged:(id)sender {
    NSURL *url = self.pathCtrlRootDirectory.objectValue;
    self.rootContents = [[ATDesktopFolderEntity alloc] initWithFileURL:url];
    [self.outlineView reloadData];
}

- (IBAction)btnDeleteRowClicked:(id)sender {
    NSInteger row = [self.outlineView rowForView:sender];
    if (row != -1) {
        // Take care of the case of the user clicking on a row that was in the middle of being deleted
        [self _removeItemAtRow:row];
    }
}

- (IBAction)btnDeletedSelectedRowsClicked:(id)sender {
    [self.outlineView beginUpdates];
    [self.outlineView.selectedRowIndexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger index, BOOL *stop) {
        [self _removeItemAtRow:index];        
    }];
    [self.outlineView endUpdates];
}


- (IBAction)btnInCellClicked:(id)sender {
    NSInteger row = [self.outlineView rowForView:sender];
    ATDesktopEntity *entity = [self.outlineView itemAtRow:row];
    [[NSWorkspace sharedWorkspace] selectFile:entity.fileURL.path inFileViewerRootedAtPath:@""];
}

- (IBAction)btnDemoMove:(id)sender {
    // Move the selected item down one
    NSInteger selectedRow = self.outlineView.selectedRow;
    if (selectedRow != -1) {
        id item = [self.outlineView itemAtRow:selectedRow]; // retain the item as we are removing it from our array
        // Grab the parent for this item
        ATDesktopFolderEntity *parent = [self.outlineView parentForItem:item];
        // The parent may be nil, so we use the root if it is
        if (parent == nil) {
            parent = self.rootContents;
        }
        // Find out where it currently is
        NSInteger indexInParent = [parent.children indexOfObject:item];
        // Then remove it
        [parent.children removeObjectAtIndex:indexInParent];
        
        // Move it one index further down, or back to the start, if it would already be at the end.
        NSUInteger targetIndexInParent = indexInParent + 1;
        if (targetIndexInParent > parent.children.count) {
            targetIndexInParent = 0; // back to the start
        }
        [parent.children insertObject:item atIndex:targetIndexInParent];
        
        // Tell outlineview about our change to our model; but of course, it uses 'nil' as the root item so we have to move back to nil if we were using the root as the parent.
        if (parent == self.rootContents) {
            parent = nil;
        }
        
        [self.outlineView moveItemAtIndex:indexInParent inParent:parent toIndex:targetIndexInParent inParent:parent];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = NSLocalizedString(@"Select something!", @"");
        alert.informativeText = NSLocalizedString(@"Select a row for an example of moving it down...", @"");
        [alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
        [alert runModal];
    }
}

- (IBAction)btnDemoBatchedMoves:(id)sender {
    // Swap all the children of the first two expandable items
    ATDesktopFolderEntity *firstParent = nil;
    ATDesktopFolderEntity *secondParent = nil;
    for (ATDesktopEntity *entity in _rootContents.children) {
        if ([entity isKindOfClass:[ATDesktopFolderEntity class]]) {
            ATDesktopFolderEntity *folderEntity = (ATDesktopFolderEntity *)entity;
            if (firstParent == nil) {
                firstParent = folderEntity;
            } else {
                secondParent = folderEntity;
                break;
            }
        }
    }
    if (firstParent && secondParent) {
        [self.outlineView beginUpdates];
        // Move all the first children to the second array
        for (NSUInteger i = 0; i < firstParent.children.count; i++) {
            [self.outlineView moveItemAtIndex:0 inParent:firstParent toIndex:i inParent:secondParent];
        }
        // Move all the children from the second to the first. We have to account for the fact that we just moved all the first items to this one.
        NSInteger childrenOffset = firstParent.children.count;
        for (NSUInteger i = 0; i < secondParent.children.count; i++) {
            [self.outlineView moveItemAtIndex:childrenOffset inParent:secondParent toIndex:i inParent:firstParent];
        }
        // Do the changes on our model, and tell the OV we are done
        NSMutableArray *firstParentChildren = firstParent.children;
        firstParent.children = secondParent.children;
        secondParent.children = firstParentChildren;
        [self.outlineView endUpdates];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = NSLocalizedString(@"Expand something!", @"");
        alert.informativeText = NSLocalizedString(@"Couldn't find two parents to do demo move with. Expand some items!", @"");
        [alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
        [alert runModal];
    }    
}

- (IBAction)chkbxFloatGroupRowsClicked:(id)sender {
    BOOL checked = ((NSButton *)sender).state == 1;
    self.outlineView.floatsGroupRows = checked;
}

- (IBAction)clrWellChanged:(id)sender {
    NSColor *color = [sender color];
    self.outlineView.backgroundColor = color;
}

@end

