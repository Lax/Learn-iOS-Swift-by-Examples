/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The \c AAPLListViewController class displays the contents of a list document. It also allows the user to create, update, and delete items, change the color of the list, or delete the list.
            
*/

@import NotificationCenter;
@import ListerKit;

#import "AAPLAppDelegate.h"
#import "AAPLListViewController.h"
#import "AAPLListItemCell.h"
#import "AAPLListColorCell.h"

// Table view cell identifiers.
NSString *const AAPLListViewControllerListItemCellIdentifier = @"listItemCell";
NSString *const AAPLListViewControllerListColorCellIdentifier = @"listColorCell";


@interface AAPLListViewController () <UITextFieldDelegate, AAPLListColorCellDelegate, AAPLListDocumentDelegate>

// Set in \c textFieldDidBeginEditing:. \c nil otherwise.
@property (nonatomic, weak) UITextField *activeTextField;

@property (nonatomic, strong) AAPLListInfo *listInfo;

@property (nonatomic, readonly) AAPLList *list;

@property (nonatomic, readonly) NSURL *documentURL;

@property (nonatomic, readonly) NSArray *listToolbarItems;

@end


@implementation AAPLListViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateInterfaceWithTextAttributes];
    
    // Use the edit button item provided by the table view controller.
    self.navigationItem.rightBarButtonItem = [self editButtonItem];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.document openWithCompletionHandler:^(BOOL success) {
        if (!success) {
            // In your app you should handle this gracefully.
            NSLog(@"Couldn't open document: %@.", self.documentURL.absoluteString);
            abort();
        }
        
        [self.tableView reloadData];

        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentStateChangedNotification:) name:UIDocumentStateChangedNotification object:self.document];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.document.delegate = nil;
    [self.document closeWithCompletionHandler:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDocumentStateChangedNotification object:self.document];
    
    // Hide the toolbar so the list can't be edited.
    [self.navigationController setToolbarHidden:YES animated:animated];
}

#pragma mark - Property Overrides

- (AAPLList *)list {
    return self.document.list;
}

- (NSURL *)documentURL {
    return self.document.fileURL;
}

- (void)setTextAttributes:(NSDictionary *)textAttributes {
    _textAttributes = [textAttributes copy];
    
    if (self.isViewLoaded) {
        [self updateInterfaceWithTextAttributes];
    }
}

// Return the toolbar items since they are used in edit mode.
- (NSArray *)listToolbarItems {
    NSString *title = NSLocalizedString(@"Delete List", nil);
    UIBarButtonItem *deleteList = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(deleteList:)];
    deleteList.tintColor = [UIColor redColor];

    if ([self.documentURL.lastPathComponent isEqualToString:[AAPLAppConfiguration sharedAppConfiguration].localizedTodayDocumentNameAndExtension]) {
        deleteList.enabled = false;
    }
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    return @[flexibleSpace, deleteList, flexibleSpace];
}

#pragma mark - Setup

- (void)configureWithListInfo:(AAPLListInfo *)listInfo {
    self.listInfo = listInfo;
    
    self.document = [[AAPLListDocument alloc] initWithFileURL:listInfo.URL];
    self.document.delegate = self;
    
    self.navigationItem.title = listInfo.name;
    
    self.textAttributes = @{
        NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName: AAPLColorFromListColor(listInfo.color) ?: AAPLColorFromListColor(AAPLListColorGray)
    };
}

#pragma mark - Notifications

- (void)handleDocumentStateChangedNotification:(NSNotification *)notification {
    UIDocumentState state = self.document.documentState;
    
    if (state & UIDocumentStateInConflict) {
        [self resolveConflicts];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - UIViewController Overrides

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    // Prevent navigating back in edit mode.
    [self.navigationItem setHidesBackButton:editing animated:animated];
    
    // Make sure to resign first responder on the active text field if needed.
    [self.activeTextField endEditing:NO];
    
    // Reload the first row to switch from "Add Item" to "Change Color".
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    // If moving out of edit mode, notify observers about the list color and trigger a save.
    if (!editing) {
        // Notify the document of a change.
        [self.document updateChangeCount:UIDocumentChangeDone];

        // If the list info doesn't already exist (but it should), then create a new one.
        self.listInfo = self.listInfo ?: [[AAPLListInfo alloc] initWithURL:self.documentURL];
        self.listInfo.color = self.list.color;
        [self.listController setListInfoHasNewContents:self.listInfo];
        
        [self triggerNewDataForWidget];
    }

    [self.navigationController setToolbarHidden:!editing animated:animated];
    [self.navigationController.toolbar setItems:self.listToolbarItems animated:animated];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.document) {
        // Don't show anything if the document hasn't been loaded.
        return 0;
    }

    // Show the items in a list, plus a separate row that lets users enter a new item.
    return self.list.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier;
    
    if (self.editing && indexPath.row == 0) {
        identifier = AAPLListViewControllerListColorCellIdentifier;
    }
    else {
        identifier = AAPLListViewControllerListItemCellIdentifier;
    }
    
    return [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // The initial row is reserved for adding new items so it can't be deleted or edited.
    if (indexPath.row == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // The initial row is reserved for adding new items so it can't be moved.
    if (indexPath.row == 0) {
        return NO;
    }
    
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }

    AAPLListItem *item = self.list[indexPath.row - 1];
    [self.list removeItems:@[item]];
    
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [self triggerNewDataForWidget];
    
    // Notify the document of a change.
    [self.document updateChangeCount:UIDocumentChangeDone];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    AAPLListItem *item = self.list[fromIndexPath.row - 1];
    [self.list moveItem:item toIndex:toIndexPath.row - 1];
    
    // Notify the document of a change.
    [self.document updateChangeCount:UIDocumentChangeDone];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Assert if attempting to configure an unknown or unsupported cell type.
    NSParameterAssert([cell isKindOfClass:[AAPLListColorCell class]] || [cell isKindOfClass:[AAPLListItemCell class]]);
    
    if ([cell isKindOfClass:[AAPLListColorCell class]]) {
        AAPLListColorCell *colorCell = (AAPLListColorCell *)cell;
        [colorCell configure];
        colorCell.selectedColor = self.list.color;
        colorCell.delegate = self;
    }
    else if ([cell isKindOfClass:[AAPLListItemCell class]]) {
        [self configureListItemCell:(AAPLListItemCell *)cell usingColor:self.list.color forRow:indexPath.row];
    }
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    // When the user swipes to show the delete confirmation, don't enter editing mode.
    // UITableViewController enters editing mode by default so we override without calling super.
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    // When the user swipes to hide the delete confirmation, no need to exit edit mode because we didn't enter it.
    // UITableViewController enters editing mode by default so we override without calling super.
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)fromIndexPath toProposedIndexPath:(NSIndexPath *)proposedIndexPath {
    AAPLListItem *item = self.list[fromIndexPath.row - 1];
    
    if (proposedIndexPath.row == 0) {
        NSInteger row = item.isComplete ? self.list.indexOfFirstCompletedItem + 1 : 1;

        return [NSIndexPath indexPathForRow:row inSection:0];
    }
    else if ([self.list canMoveItem:item toIndex:proposedIndexPath.row - 1 inclusive:NO]) {
        return proposedIndexPath;
    }
    else if (item.isComplete) {
        return [NSIndexPath indexPathForRow:self.list.indexOfFirstCompletedItem + 1 inSection:0];
    }
    else {
        return [NSIndexPath indexPathForRow:self.list.indexOfFirstCompletedItem inSection:0];
    }
    
    return proposedIndexPath;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    BOOL shouldNotifyDocumentOfChange = NO;
    
    NSIndexPath *indexPath = [self indexPathForView:textField];
    
    // Check to see if a change needs to be made to an existing list item (i.e. row > 0)
    // or if we need to insert a new list item.
    BOOL isForExistingListItem = indexPath.row > 0;
    
    if (isForExistingListItem) {
        // Edit the item in place.
        AAPLListItem *item = self.list[indexPath.row - 1];
        
        // Delete the item row if the user deletes all characters in the text field.
        if (textField.text.length == 0) {
            [self.list removeItems:@[item]];
            
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            
            [self triggerNewDataForWidget];
            
            shouldNotifyDocumentOfChange = YES;
        }
        // Update the item's text if it changed (besides removing all characters, which is a delete).
        else if (![item.text isEqualToString:textField.text]) {
            item.text = textField.text;
            
            [self triggerNewDataForWidget];
            
            shouldNotifyDocumentOfChange = YES;
        }
    }
    else if (textField.text.length > 0) {
        // Adds the item to the top of the list.
        AAPLListItem *item = [[AAPLListItem alloc] initWithText:textField.text];
        NSInteger insertedIndex = [self.list insertItem:item];
        
        // Update the edit row to show the check box.
        AAPLListItemCell *itemCell = (AAPLListItemCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        itemCell.checkBox.hidden = NO;
        
        // Update the edit row to indicate that deleting all text in an item will delete the item.
        itemCell.textField.placeholder = NSLocalizedString(@"Delete Item", nil);
        
        // Insert a new add item row into the table view.
        [self.tableView beginUpdates];
        
        NSIndexPath *targetIndexPath = [NSIndexPath indexPathForRow:insertedIndex inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[targetIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
        
        [self triggerNewDataForWidget];
        
        shouldNotifyDocumentOfChange = YES;
    }
    
    if (shouldNotifyDocumentOfChange) {
        [self.document updateChangeCount:UIDocumentChangeDone];
    }
    
    self.activeTextField = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    // Always resign first responder and return. If the field is empty, the item will be deleted.
    [textField resignFirstResponder];

    return YES;
}

#pragma mark - AAPLListColorCellDelegate

- (void)listColorCellDidChangeSelectedColor:(AAPLListColorCell *)listColorCell {
    self.list.color = listColorCell.selectedColor;
    
    self.textAttributes = @{
        NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName: AAPLColorFromListColor(self.list.color)
    };
    
    NSArray *indexPaths = [self.tableView indexPathsForVisibleRows];
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

# pragma mark - IBActions

- (IBAction)deleteList:(id)sender {
    [self.listController removeListInfo:self.listInfo];

    [self hideViewControllerAfterListWasDeleted];
}

- (IBAction)checkBoxTapped:(AAPLCheckBox *)sender {
    NSIndexPath *indexPath = [self indexPathForView:sender];
   
    // Check to see if the tapped row is within the list item rows.
    if (indexPath.row >= 1 && indexPath.row <= self.list.count) {
        AAPLListItem *item = self.list[indexPath.row - 1];
        AAPLListOperationInfo info = [self.list toggleItem:item withPreferredDestinationIndex:NSNotFound];
        
        if (info.fromIndex == info.toIndex) {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else {
            // Animate the row up or down depending on whether it was complete/incomplete.
            NSIndexPath *targetRow = [NSIndexPath indexPathForRow:info.toIndex + 1 inSection:0];
            
            [self.tableView beginUpdates];
            [self.tableView moveRowAtIndexPath:indexPath toIndexPath:targetRow];
            [self.tableView endUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[targetRow] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
        [self triggerNewDataForWidget];
        
        // Notify the document of a change.
        [self.document updateChangeCount:UIDocumentChangeDone];
    }
}

#pragma mark - AAPLListDocumentDelegate

- (void)listDocumentWasDeleted:(AAPLListDocument *)document {
    [self hideViewControllerAfterListWasDeleted];
}

#pragma mark - Convenience

- (void)updateInterfaceWithTextAttributes {
    UINavigationController *controller = self.navigationController.navigationController ?: self.navigationController;
    
    controller.navigationBar.titleTextAttributes = self.textAttributes;
    controller.navigationBar.tintColor = self.textAttributes[NSForegroundColorAttributeName];
    controller.toolbar.tintColor = self.textAttributes[NSForegroundColorAttributeName];

    self.tableView.tintColor = self.textAttributes[NSForegroundColorAttributeName];
}

- (void)hideViewControllerAfterListWasDeleted {
    if (self.splitViewController && self.splitViewController.isCollapsed) {
        UINavigationController *controller = self.navigationController.navigationController ?: self.navigationController;
        [controller popViewControllerAnimated:YES];
    }
    else {
        UINavigationController *emptyViewController = (UINavigationController *)[self.storyboard instantiateViewControllerWithIdentifier:AAPLAppDelegateMainStoryboardEmptyViewControllerIdentifier];
        emptyViewController.topViewController.navigationItem.leftBarButtonItem = [self.splitViewController displayModeButtonItem];
        
        self.splitViewController.viewControllers = @[self.splitViewController.viewControllers.firstObject, emptyViewController];
    }
}

- (void)configureListItemCell:(AAPLListItemCell *)itemCell usingColor:(AAPLListColor)color forRow:(NSInteger)row {
    itemCell.checkBox.checked = NO;
    itemCell.checkBox.hidden = NO;
    
    itemCell.textField.text = @"";
    itemCell.textField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    itemCell.textField.delegate = self;
    itemCell.textField.textColor = [UIColor darkTextColor];
    itemCell.textField.enabled = YES;
    
    if (row == 0) {
        // Configure an "Add Item" list item cell.
        itemCell.textField.placeholder = NSLocalizedString(@"Add Item", nil);
        itemCell.checkBox.hidden = YES;
    }
    else {
        AAPLListItem *item = self.list[row - 1];
        
        itemCell.complete = item.isComplete;
        itemCell.textField.text = item.text;
    }
}

- (void)triggerNewDataForWidget {
    NSString *localizedTodayDocumentName = [AAPLAppConfiguration sharedAppConfiguration].localizedTodayDocumentName;
    
    if ([self.document.localizedName isEqualToString:localizedTodayDocumentName]) {
        [[NCWidgetController widgetController] setHasContent:YES forWidgetWithBundleIdentifier:AAPLAppConfigurationWidgetBundleIdentifier];
    }
}


- (void)resolveConflicts {
    // Any automatic merging logic or presentation of conflict resolution UI should go here.
    // For this sample, just pick the current version and mark the conflict versions as resolved.
    [NSFileVersion removeOtherVersionsOfItemAtURL:self.documentURL error:nil];
    
    NSArray *conflictVersions = [NSFileVersion unresolvedConflictVersionsOfItemAtURL:self.documentURL];
    for (NSFileVersion *fileVersion in conflictVersions) {
        fileVersion.resolved = YES;
    }
}

- (NSIndexPath *)indexPathForView:(UIView *)view {
    CGPoint viewOrigin = view.bounds.origin;

    CGPoint viewLocation = [self.tableView convertPoint:viewOrigin fromView:view];
    
    return [self.tableView indexPathForRowAtPoint:viewLocation];
}

@end
