/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  The view controller responsible for displaying the contents of a list document.
              
 */

#import "AAPLListViewController.h"
#import "AAPLAddItemViewController.h"
#import "AAPLColorPaletteView.h"
#import "AAPLListItemView.h"
#import "AAPLTableRowView.h"
@import ListerKitOSX;
@import NotificationCenter;

// View identifiers.
NSString *const AAPLListViewControllerListItemViewIdentifier = @"AAPLListViewControllerListItemViewIdentifier";
NSString *const AAPLListViewControllerNoListItemViewIdentifier = @"AAPLListViewControllerNoListItemViewIdentifier";

// List table view.
NSString *const AAPLListViewControllerDragType = @"AAPLListViewControllerDragType";
NSString *const AAPLListViewControllerPasteboardType = @"public.item.list";


@interface AAPLListViewController() <NSTableViewDelegate, AAPLListDocumentDelegate, AAPLColorPaletteViewDelegate, AAPLListItemViewDelegate>

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet AAPLColorPaletteView *colorPaletteView;

// Convenience
@property (readonly, nonatomic) AAPLList *list;

@end


@implementation AAPLListViewController

#pragma mark - Convenience

- (void)setDocument:(AAPLListDocument *)document {
    _document = document;
    
    document.delegate = self;
    
    [self reloadListUI];
}

- (AAPLList *)list {
    return [self.document list];
}

- (NSUndoManager *)undoManager {
    return [self.document undoManager];
}

#pragma mark - View Life Cycle

- (void)viewDidAppear {
    [super viewDidAppear];
    
    self.document.delegate = self;

    // Enable dragging for the list items of our specific type.
    [self.tableView registerForDraggedTypes:@[AAPLListViewControllerDragType, NSPasteboardTypeString]];
    [self.tableView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
}


#pragma mark - NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (!self.list) {
        return 0;
    }

    return self.list.empty ? 1 : self.list.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (self.list.isEmpty) {
        return [tableView makeViewWithIdentifier:AAPLListViewControllerNoListItemViewIdentifier owner:nil];
    }

    AAPLListItemView *listItemView = [tableView makeViewWithIdentifier:AAPLListViewControllerListItemViewIdentifier owner:nil];
    
    AAPLListItem *item = self.list[row];
    
    listItemView.completed = item.isComplete;

    listItemView.tintColor = AAPLColorFromListColor(self.list.color);

    listItemView.stringValue = item.text;
    
    listItemView.delegate = self;
    
    return listItemView;
}

// Only allow rows to be selectable if there are items in the list.
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return !self.list.empty;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
    // Don't allow moving/copying the empty list item.
    NSPasteboard *pasteboard = [info draggingPasteboard];
    
    NSDragOperation result = NSDragOperationNone;
    
    // Only allow drops above.
    if (dropOperation == NSTableViewDropAbove) {
        // If drag source is our own table view, it's a move.
        if (info.draggingSource == self.tableView) {
            NSArray *listItems = [self listItemsWithListerPasteboardType:pasteboard refreshesItemIdentities:NO];
            
            BOOL canMoveItem = listItems.count == 1 && [self.list canMoveItem:listItems.firstObject toIndex:row inclusive:YES];
            if (canMoveItem) {
                result = NSDragOperationMove;
            }
        }
        else {
            NSArray *items = [self listItemsWithStringPasteboardType:pasteboard];
            
            if (items && [self.list canInsertIncompleteItems:items atIndex:row]) {
                result = NSDragOperationCopy;
            }
        }
    }
    
    return result;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
    NSPasteboard *pasteboard = [info draggingPasteboard];
    
    if (info.draggingSource == self.tableView) {
        NSArray *items = [self listItemsWithListerPasteboardType:pasteboard refreshesItemIdentities:NO];

        NSAssert(items.count == 1, @"There must be exactly one moved item");
        
        [self moveItem:items.firstObject toIndex:row];
        
        return YES;
    }
    else {
        NSArray *items = [self listItemsWithStringPasteboardType:pasteboard];
        
        NSAssert(items, @"'items' must not be nil");
        
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, items.count)];
        [self insertItems:items withPreferredIndexes:indexes];
        
        return YES;
    }
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pasteboard {
    if (self.list.empty) {
        return NO;
    }
    
    NSArray *items = self.list[rowIndexes];

    [self writeItems:items toPasteboard:pasteboard];
    
    return YES;
}

#pragma mark - NSPasteboard Convenience

- (NSArray *)listItemsWithListerPasteboardType:(NSPasteboard *)pasteboard refreshesItemIdentities:(BOOL)refreshesItemIdentities {
    if ([pasteboard canReadItemWithDataConformingToTypes:@[AAPLListViewControllerPasteboardType]]) {
        NSMutableArray *allItems = [NSMutableArray array];
        
        for (NSPasteboardItem *pasteboardItem in pasteboard.pasteboardItems) {
            NSData *itemsData = [pasteboardItem dataForType:AAPLListViewControllerPasteboardType];
            
            NSArray *pasteboardsListItems = [NSKeyedUnarchiver unarchiveObjectWithData:itemsData];
            
            if (refreshesItemIdentities) {
                for (AAPLListItem *item in pasteboardsListItems) {
                    [item refreshIdentity];
                }
            }
            
            [allItems addObjectsFromArray:pasteboardsListItems];
        }
        
        return allItems;
    }
    
    return nil;
}

- (NSArray *)listItemsWithStringPasteboardType:(NSPasteboard *)pasteboard {
    if ([pasteboard canReadItemWithDataConformingToTypes:@[NSPasteboardTypeString]]) {
        NSMutableArray *allItems = [NSMutableArray array];
        
        for (NSPasteboardItem *pasteboardItem in pasteboard.pasteboardItems) {
            NSString *targetType = [pasteboardItem availableTypeFromArray:@[NSPasteboardTypeString]];
            
            NSString *pasteboardString = [pasteboardItem stringForType:targetType];
            
            NSArray *listItems = [AAPLListFormatting listItemsFromString:pasteboardString];
            [allItems addObjectsFromArray:listItems];
        }
        
        return allItems;
    }
    
    return nil;
}

- (void)writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard {
    [pasteboard declareTypes:@[AAPLListViewControllerDragType, NSPasteboardTypeString] owner:nil];
    
    // Save the items as data.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:items];
    [pasteboard setData:data forType:AAPLListViewControllerPasteboardType];
    
    // Save the items as a string.
    NSString *itemsString = [AAPLListFormatting stringFromListItems:items];
    [pasteboard setString:itemsString forType:NSPasteboardTypeString];
}

#pragma mark - Item Rearrangement

- (void)moveItem:(AAPLListItem *)item toIndex:(NSInteger)toIndex {
    AAPLListOperationInfo moveInfo = [self.list moveItem:item toIndex:toIndex];
    
    [self.tableView moveRowAtIndex:moveInfo.fromIndex toIndex:moveInfo.toIndex];
    
    typeof(self) windowController = [self.undoManager prepareWithInvocationTarget:self];
    [windowController moveItem:item toPriorIndex:moveInfo.fromIndex];
    
    [self updateWidget];
}

- (void)moveItem:(AAPLListItem *)item toPriorIndex:(NSInteger)priorIndex {
    NSInteger currentItemIndex = [self.list indexOfItem:item];
    
    NSInteger normalizedIndex = priorIndex;
    if (currentItemIndex < priorIndex) {
        normalizedIndex++;
    }
    
    [self moveItem:item toIndex:normalizedIndex];
}

- (void)deleteRowsAtIndexes:(NSIndexSet *)indexes {
    // Ignore empty index sets.
    if (indexes.count <= 0) {
        return;
    }
    
    NSArray *items = self.list[indexes];
    
    [self.list removeItems:items];
    
    [self.tableView beginUpdates];
    
    [self.tableView removeRowsAtIndexes:indexes withAnimation:NSTableViewAnimationSlideUp];
    
    if (self.list.empty) {
        // Show the empty row.
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
        [self.tableView insertRowsAtIndexes:indexSet withAnimation:NSTableViewAnimationSlideDown];
    }
    
    [self.tableView endUpdates];
    
    [[self.undoManager prepareWithInvocationTarget:self] insertItems:items withPreferredIndexes:indexes];
    
    [self updateWidget];
}

// If 'preferredIndexes' is nil, the items will be inserted at the most appropriate places based on the completion status of the item. Otherwise, the indexes will be used.
- (void)insertItems:(NSArray *)items withPreferredIndexes:(NSIndexSet *)preferredIndexes {
    BOOL listEmptyBeforeInsert = self.list.empty;
    
    NSIndexSet *insertedIndexes;
    
    if (preferredIndexes) {
        __block NSInteger itemsIndex = 0;
        [preferredIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            AAPLListItem *item = items[itemsIndex];
            
            [self.list insertItem:item atIndex:idx];

            itemsIndex++;
        }];
        
        insertedIndexes = preferredIndexes;
    }
    else {
        insertedIndexes = [self.list insertItems:items];
    }
    
    [self.tableView beginUpdates];
    if (listEmptyBeforeInsert) {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
        [self.tableView removeRowsAtIndexes:indexSet withAnimation:NSTableViewAnimationSlideUp];
    }
    [self.tableView insertRowsAtIndexes:insertedIndexes withAnimation:NSTableViewAnimationSlideDown];
    [self.tableView endUpdates];
    
    [[self.undoManager prepareWithInvocationTarget:self] deleteRowsAtIndexes:insertedIndexes];
    
    [self updateWidget];
}

- (void)toggleItem:(AAPLListItem *)item withPreferredDestinationIndex:(NSInteger)preferredDestinationIndex {
    [self.tableView beginUpdates];
    
    NSInteger itemIndex = [self.list indexOfItem:item];
    AAPLListItemView *listItemView = [self.tableView viewAtColumn:0 row:itemIndex makeIfNecessary:YES];
    
    AAPLListOperationInfo toggleInfo = [self.list toggleItem:item withPreferredDestinationIndex:preferredDestinationIndex];
    
    [self.tableView moveRowAtIndex:toggleInfo.fromIndex toIndex:toggleInfo.toIndex];
    
    listItemView.completed = item.isComplete;
    
    [self.tableView endUpdates];
    
    typeof(self) windowController = [self.undoManager prepareWithInvocationTarget:self];
    [windowController toggleItem:item withPreferredDestinationIndex:toggleInfo.fromIndex];
    
    [self updateWidget];
}

- (void)resetToList:(AAPLList *)list {
    [[self.undoManager prepareWithInvocationTarget:self] resetToList:[self.list copy]];
    
    self.document.list = list;
    
    self.colorPaletteView.selectedColor = self.list.color;
    [self.tableView reloadData];
    
    [self updateWidget];
}

- (void)updateAllItemsToCompletionState:(BOOL)completeStatus {
    [[self.undoManager prepareWithInvocationTarget:self] resetToList:[self.list copy]];
    
    [self.list updateAllItemsToCompletionState:completeStatus];
    [self.tableView reloadData];
}

- (void)updateItem:(AAPLListItem *)item withText:(NSString *)text {
    NSString *oldText = item.text;
    
    item.text = text;
    
    NSInteger indexOfItem = [self.list indexOfItem:item];
    
    [self.tableView beginUpdates];
    AAPLListItemView *listItemView = [self.tableView viewAtColumn:0 row:indexOfItem makeIfNecessary:YES];
    listItemView.stringValue = text;
    [self.tableView endUpdates];
    
    [[self.undoManager prepareWithInvocationTarget:self] updateItem:item withText:oldText];
}

#pragma mark - Reloading Convenience

- (void)reloadListUI {
    self.colorPaletteView.selectedColor = self.list.color;
    
    [self.tableView reloadData];
}

#pragma mark - Cut / Copy / Paste / Delete

- (void)cut:(id)sender {
    NSIndexSet *selectedRowIndexes = self.tableView.selectedRowIndexes;
    
    if (selectedRowIndexes.count > 0) {
        NSArray *items = self.list[selectedRowIndexes];
        
        [self writeItems:items toPasteboard:[NSPasteboard generalPasteboard]];
        
        [self deleteRowsAtIndexes:selectedRowIndexes];
    }
}

- (void)copy:(id)sender {
    NSIndexSet *selectedRowIndexes = self.tableView.selectedRowIndexes;
    
    if (selectedRowIndexes.count > 0) {
        NSArray *items = self.list[selectedRowIndexes];
        
        [self writeItems:items toPasteboard:[NSPasteboard generalPasteboard]];
    }
}

- (void)paste:(id)sender {
    // First check if the items were serialized as data, then check for text.
    NSArray *items = [self listItemsWithListerPasteboardType:[NSPasteboard generalPasteboard] refreshesItemIdentities:YES];

    if (!items) {
        items = [self listItemsWithStringPasteboardType:[NSPasteboard generalPasteboard]];
    }
    
    if (items.count > 0) {
        [self insertItems:items withPreferredIndexes:nil];
    }
}

- (void)keyDown:(NSEvent *)event {
    unichar character = [event.charactersIgnoringModifiers characterAtIndex:0];
    
    // Only handle delete keyboard event.
    if (character == NSDeleteCharacter) {
        [self deleteRowsAtIndexes:self.tableView.selectedRowIndexes];
    }
}

#pragma mark - IBActions

- (IBAction)completeAllItems:(id)sender {
    [self updateAllItemsToCompletionState:YES];
}

- (IBAction)incompleteAllItems:(id)sender {
    [self updateAllItemsToCompletionState:NO];
}

#pragma mark - AAPLListItemViewDelegate

- (void)listItemViewDidToggleCompletionState:(AAPLListItemView *)listItemView {
    NSInteger row = [self.tableView rowForView:listItemView];
    
    [self toggleItem:self.list[row] withPreferredDestinationIndex:NSNotFound];
}

- (void)listItemViewTextDidEndEditing:(AAPLListItemView *)listItemView {
    NSInteger row = [self.tableView rowForView:listItemView];
    
    if (row == -1) {
        return;
    }
    
    NSString *cleansedString = [listItemView.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (cleansedString.length > 0) {
        AAPLListItem *item = self.list[row];
        
        NSString *oldText = item.text;
        
        item.text = listItemView.stringValue;
        
        [[self.undoManager prepareWithInvocationTarget:self] updateItem:item withText:oldText];
        
        [self updateWidget];
    }
    else {
        NSIndexSet *indexSetToDelete = [NSIndexSet indexSetWithIndex:row];
        [self deleteRowsAtIndexes:indexSetToDelete];
    }
}

#pragma mark - AAPLAddItemViewControllerDelegate

- (void)addItemViewController:(AAPLAddItemViewController *)addItemViewController didCreateNewItemWithText:(NSString *)text {
    AAPLListItem *newItem = [[AAPLListItem alloc] initWithText:text];
    
    [self insertItems:@[newItem] withPreferredIndexes:nil];
}

#pragma mark - AAPLColorPaletteViewDelegate

- (void)colorPaletteViewDidChangeSelectedColor:(AAPLColorPaletteView *)colorPaletteView {
    [self setColorPaletteViewColor:colorPaletteView.selectedColor];
}

- (void)setColorPaletteViewColor:(AAPLListColor)listColor {
    [[self.undoManager prepareWithInvocationTarget:self] setColorPaletteViewColor:self.list.color];

    self.list.color = listColor;
    self.colorPaletteView.selectedColor = listColor;
    
    // Update the list item views with the newly selected color.
    // Only update the ListItemView subclasses since they only have a tint color.
    [self.tableView beginUpdates];
    [self.tableView enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
        NSTableCellView *cellView = [rowView viewAtColumn:0];
        
        if ([cellView isKindOfClass:[AAPLListItemView class]]) {
            AAPLListItemView *listItemView = (AAPLListItemView *)cellView;
            
            listItemView.tintColor = AAPLColorFromListColor(listColor);
        }
    }];
    [self.tableView endUpdates];
    
    [self updateWidget];
}

#pragma mark - AAPLListDocumentDelegate

- (void)listDocumentDidChangeContents:(AAPLListDocument *)document {
    [self reloadListUI];
}

#pragma mark - NCWidget Support

- (void)updateWidget {
    [[AAPLTodayListManager sharedTodayListManager] fetchTodayDocumentURLWithCompletionHandler:^(NSURL *todayDocumentURL) {
        if (!todayDocumentURL) {
            return;
        }
        
        NSURL *currentDocumentURL = [self.document fileURL];
        
        if ([currentDocumentURL isEqual:todayDocumentURL]) {
            [[NCWidgetController widgetController] setHasContent:YES forWidgetWithBundleIdentifier:AAPLAppConfigurationWidgetBundleIdentifier];
        }
    }];
}

@end
