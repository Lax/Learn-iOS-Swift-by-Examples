/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The view controller responsible for displaying the contents of a list document.
*/

#import "AAPLListViewController.h"
#import "AAPLAddItemViewController.h"
#import "AAPLColorPaletteView.h"
#import "AAPLListItemView.h"
#import "AAPLTableRowView.h"
@import ListerKit;
@import NotificationCenter;

// View identifiers.
NSString *const AAPLListViewControllerListItemViewIdentifier = @"AAPLListViewControllerListItemViewIdentifier";
NSString *const AAPLListViewControllerNoListItemViewIdentifier = @"AAPLListViewControllerNoListItemViewIdentifier";

// List table view.
NSString *const AAPLListViewControllerDragType = @"AAPLListViewControllerDragType";
NSString *const AAPLListViewControllerPasteboardType = @"public.item.list";

@interface AAPLListViewController() <NSTableViewDelegate, AAPLListPresenterDelegate, AAPLColorPaletteViewDelegate, AAPLListItemViewDelegate>

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet AAPLColorPaletteView *colorPaletteView;

// Convenience
@property (readonly) AAPLAllListItemsPresenter *listPresenter;

@end


@implementation AAPLListViewController

#pragma mark - Convenience

- (void)setDocument:(AAPLListDocument *)document {
    _document = document;
    
    AAPLAllListItemsPresenter *listPresenter = [[AAPLAllListItemsPresenter alloc] init];
    listPresenter.delegate = self;
    
    document.listPresenter = listPresenter;
    
    listPresenter.undoManager = self.document.undoManager;
}

- (AAPLAllListItemsPresenter *)listPresenter {
    return [self.document listPresenter];
}

- (NSUndoManager *)undoManager {
    return [self.document undoManager];
}

#pragma mark - View Life Cycle

- (void)viewDidAppear {
    [super viewDidAppear];
    
    // Load the current data for the table view.
    [self.tableView reloadData];

    // Enable dragging for the list items of our specific type.
    [self.tableView registerForDraggedTypes:@[AAPLListViewControllerDragType, NSPasteboardTypeString]];
    [self.tableView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
}


#pragma mark - NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (!self.document) {
        return 0;
    }

    return self.listPresenter.isEmpty ? 1 : self.listPresenter.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (self.listPresenter.isEmpty) {
        return [tableView makeViewWithIdentifier:AAPLListViewControllerNoListItemViewIdentifier owner:nil];
    }

    AAPLListItemView *listItemView = [tableView makeViewWithIdentifier:AAPLListViewControllerListItemViewIdentifier owner:nil];
    
    AAPLListItem *listItem = self.listPresenter.presentedListItems[row];
    
    [self configureListItemView:listItemView forListItem:listItem];
    
    return listItemView;
}

// Only allow rows to be selectable if there are items in the list.
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return !self.listPresenter.isEmpty;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
    // Don't allow moving/copying the empty list item.
    NSPasteboard *pasteboard = [info draggingPasteboard];
    
    NSDragOperation result = NSDragOperationNone;
    
    // Only allow drops above.
    if (dropOperation == NSTableViewDropAbove) {
        // If the drag source is our table view, it's a move.
        if ([info draggingSource] == tableView) {
            NSArray *listItems = [self listItemsWithListerPasteboardType:pasteboard refreshesItemIdentities:NO];

            // Only allow a move if there's a single item being moved, and the list allows it.
            if (listItems.count == 1 && [self.listPresenter canMoveListItem:listItems.firstObject toIndex:row]) {
                result = NSDragOperationMove;
            }
        }
        else {
            if ([self listItemsWithListerPasteboardType:pasteboard refreshesItemIdentities:NO] || [self listItemsWithStringPasteboardType:pasteboard]) {
                result = NSDragOperationCopy;
            }
        }
    }
    
    return result;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
    NSPasteboard *pasteboard = [info draggingPasteboard];
    
    if (info.draggingSource == self.tableView) {
        NSArray *listItems = [self listItemsWithListerPasteboardType:pasteboard refreshesItemIdentities:NO];

        NSAssert(listItems.count == 1, @"There must be exactly one moved item.");
        NSAssert(dropOperation == NSTableViewDropAbove, @"Only NSTableViewDropAbove operations are allowed.");

        AAPLListItem *listItem = listItems.firstObject;
        
        NSInteger fromIndex = [self.listPresenter.presentedListItems indexOfObject:listItem];
        
        NSInteger normalizedToIndex = row;
        if (fromIndex < row) {
            normalizedToIndex--;
        }
        
        [self.listPresenter moveListItem:listItem toIndex:normalizedToIndex];
    }
    else {
        NSArray *listItems = [self listItemsWithStringPasteboardType:pasteboard];
        
        NSAssert(listItems, @"`listItems` must not be nil");
        
        [self.listPresenter insertListItems:listItems];
    }
    
    return YES;
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pasteboard {
    if (self.listPresenter.empty) {
        return NO;
    }
    
    NSArray *items = [self.listPresenter.presentedListItems objectsAtIndexes:rowIndexes];

    [self writeListItems:items toPasteboard:pasteboard];
    
    return YES;
}

#pragma mark - NSPasteboard Convenience

- (NSArray *)listItemsWithListerPasteboardType:(NSPasteboard *)pasteboard refreshesItemIdentities:(BOOL)refreshesItemIdentities {
    if ([pasteboard canReadItemWithDataConformingToTypes:@[AAPLListViewControllerPasteboardType]]) {
        NSMutableArray *listItems = [NSMutableArray array];
        
        for (NSPasteboardItem *pasteboardItem in pasteboard.pasteboardItems) {
            NSData *itemsData = [pasteboardItem dataForType:AAPLListViewControllerPasteboardType];
            
            NSArray *pasteboardsListItems = [NSKeyedUnarchiver unarchiveObjectWithData:itemsData];
            
            if (refreshesItemIdentities) {
                for (AAPLListItem *listItem in pasteboardsListItems) {
                    [listItem refreshIdentity];
                }
            }
            
            [listItems addObjectsFromArray:pasteboardsListItems];
        }
        
        return listItems;
    }
    
    return nil;
}

- (NSArray *)listItemsWithStringPasteboardType:(NSPasteboard *)pasteboard {
    if ([pasteboard canReadItemWithDataConformingToTypes:@[NSPasteboardTypeString]]) {
        NSMutableArray *listItems = [NSMutableArray array];
        
        for (NSPasteboardItem *pasteboardItem in pasteboard.pasteboardItems) {
            NSString *targetType = [pasteboardItem availableTypeFromArray:@[NSPasteboardTypeString]];
            
            NSString *pasteboardString = [pasteboardItem stringForType:targetType];
            
            NSArray *formattedListItems = [AAPLListFormatting listItemsFromString:pasteboardString];
            [listItems addObjectsFromArray:formattedListItems];
        }
        
        return listItems;
    }
    
    return nil;
}

- (void)writeListItems:(NSArray *)listItems toPasteboard:(NSPasteboard *)pasteboard {
    [pasteboard declareTypes:@[AAPLListViewControllerDragType, NSPasteboardTypeString] owner:nil];
    
    // Save the items as data.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:listItems];
    [pasteboard setData:data forType:AAPLListViewControllerPasteboardType];
    
    // Save the items as a string.
    NSString *listItemsString = [AAPLListFormatting stringFromListItems:listItems];
    [pasteboard setString:listItemsString forType:NSPasteboardTypeString];
}

#pragma mark - Cut / Copy / Paste / Delete

- (void)cut:(id)sender {
    NSIndexSet *selectedRowIndexes = self.tableView.selectedRowIndexes;
    
    if (selectedRowIndexes.count > 0) {
        NSArray *listItems = [self.listPresenter.presentedListItems objectsAtIndexes:selectedRowIndexes];
        
        [self writeListItems:listItems toPasteboard:[NSPasteboard generalPasteboard]];
        
        [self.listPresenter removeListItems:listItems];
    }
}

- (void)copy:(id)sender {
    NSIndexSet *selectedRowIndexes = self.tableView.selectedRowIndexes;
    
    if (selectedRowIndexes.count > 0) {
        NSArray *items = [self.listPresenter.presentedListItems objectsAtIndexes:selectedRowIndexes];
        
        [self writeListItems:items toPasteboard:[NSPasteboard generalPasteboard]];
    }
}

- (void)paste:(id)sender {
    // First check if the items were serialized as data, then check for text.
    NSArray *listItems = [self listItemsWithListerPasteboardType:[NSPasteboard generalPasteboard] refreshesItemIdentities:YES];

    if (!listItems) {
        listItems = [self listItemsWithStringPasteboardType:[NSPasteboard generalPasteboard]];
    }
    
    if (listItems.count > 0) {
        [self.listPresenter insertListItems:listItems];
    }
}

- (void)keyDown:(NSEvent *)event {
    unichar character = [event.charactersIgnoringModifiers characterAtIndex:0];
    
    // Only handle delete keyboard event.
    if (character == NSDeleteCharacter) {
        NSArray *listItems = [self.listPresenter.presentedListItems objectsAtIndexes:self.tableView.selectedRowIndexes];
        
        [self.listPresenter removeListItems:listItems];
    }
}

#pragma mark - IBActions

- (IBAction)markAllListItemsAsComplete:(id)sender {
    [self.listPresenter updatePresentedListItemsToCompletionState:YES];
}

- (IBAction)markAllListItemsAsIncomplete:(id)sender {
    [self.listPresenter updatePresentedListItemsToCompletionState:NO];
}

#pragma mark - AAPLListItemViewDelegate

- (void)listItemViewDidToggleCompletionState:(AAPLListItemView *)listItemView {
    NSInteger row = [self.tableView rowForView:listItemView];
    
    AAPLListItem *listItem = self.listPresenter.presentedListItems[row];
    
    [self.listPresenter toggleListItem:listItem];
}

- (void)listItemViewTextDidEndEditing:(AAPLListItemView *)listItemView {
    NSInteger row = [self.tableView rowForView:listItemView];
    
    if (row == -1) {
        return;
    }
    
    NSString *cleansedString = [listItemView.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    AAPLListItem *listItem = self.listPresenter.presentedListItems[row];
    
    // If a list item's text is empty after editing, delete it.
    if (cleansedString.length <= 0) {
        [self.listPresenter removeListItem:listItem];
    }
    else {
        [self.listPresenter updateListItem:listItem withText:listItemView.stringValue];
    }
}

#pragma mark - AAPLAddItemViewControllerDelegate

- (void)addItemViewController:(AAPLAddItemViewController *)addItemViewController didCreateNewItemWithText:(NSString *)text {
    AAPLListItem *newListItem = [[AAPLListItem alloc] initWithText:text];
    
    [self.listPresenter insertListItem:newListItem];
}

#pragma mark - AAPLColorPaletteViewDelegate

- (void)colorPaletteViewDidChangeSelectedColor:(AAPLColorPaletteView *)colorPaletteView {
    self.listPresenter.color = colorPaletteView.selectedColor;
}

#pragma mark - AAPLListPresenterDelegate

- (void)listPresenterDidRefreshCompleteLayout:(id<AAPLListPresenting>)listPresenter {
    [self.tableView reloadData];
    
    self.colorPaletteView.selectedColor = listPresenter.color;
}

- (void)listPresenterWillChangeListLayout:(id<AAPLListPresenting>)listPresenter isInitialLayout:(BOOL)isInitialLayout {
    [self.tableView beginUpdates];
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didInsertListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];

    // Hide the "No items in list" row.
    if (index == 0 && listPresenter.count == 1) {
        [self.tableView removeRowsAtIndexes:indexSet withAnimation:NSTableViewAnimationSlideUp];
    }
    
    [self.tableView insertRowsAtIndexes:indexSet withAnimation:NSTableViewAnimationSlideDown];
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didRemoveListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
    
    [self.tableView removeRowsAtIndexes:indexSet withAnimation:NSTableViewAnimationSlideUp];
    
    // Show the "No items in list" row.
    if (index == 0 && listPresenter.isEmpty) {
        [self.tableView insertRowsAtIndexes:indexSet withAnimation:NSTableViewAnimationSlideDown];
    }
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didUpdateListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {
    AAPLListItemView *listItemView = [self.tableView viewAtColumn:0 row:index makeIfNecessary:NO];
    
    [self configureListItemView:listItemView forListItem:listItem];
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didMoveListItem:(AAPLListItem *)listItem fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    [self.tableView moveRowAtIndex:fromIndex toIndex:toIndex];
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didUpdateListColorWithColor:(AAPLListColor)color {
    self.colorPaletteView.selectedColor = color;
    
    /**
        Update the list item views with the newly selected color. Only update the `AAPLListItemView` subclasses
        since they only have a tint color.
    */
    [self.tableView enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
        id listItemView = [rowView viewAtColumn:0];
        
        if ([listItemView isKindOfClass:[AAPLListItemView class]]) {
            [listItemView setTintColor:AAPLColorFromListColor(self.listPresenter.color)];
        }
    }];
}

- (void)listPresenterDidChangeListLayout:(id<AAPLListPresenting>)listPresenter isInitialLayout:(BOOL)isInitialLayout {
    [self.tableView endUpdates];
    
    if (!isInitialLayout) {
        [self updateWidget];
    }
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

#pragma mark - Convenience

- (void)configureListItemView:(AAPLListItemView *)listItemView forListItem:(AAPLListItem *)listItem {
    listItemView.complete = listItem.isComplete;
    
    listItemView.tintColor = AAPLColorFromListColor(self.listPresenter.color);
    
    listItemView.stringValue = listItem.text;
    
    listItemView.delegate = self;
}

@end
