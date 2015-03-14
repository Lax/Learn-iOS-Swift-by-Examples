/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
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
#import "AAPLList.h"

// Table view cell identifiers.
NSString *const AAPLListViewControllerListItemCellIdentifier = @"listItemCell";
NSString *const AAPLListViewControllerListColorCellIdentifier = @"listColorCell";


@interface AAPLListViewController () <UITextFieldDelegate, AAPLListColorCellDelegate, AAPLListDocumentDelegate>

// Set in \c textFieldDidBeginEditing:. \c nil otherwise.
@property (nonatomic, weak) UITextField *activeTextField;

@property (nonatomic, strong) AAPLListInfo *listInfo;

@property (nonatomic, readonly) NSURL *documentURL;

@property (nonatomic, readonly) NSArray *listToolbarItems;

@property (nonatomic, readonly) AAPLAllListItemsPresenter *listPresenter;

@end


@implementation AAPLListViewController

#pragma mark - View Life Cycle

- (BOOL)canBecomeFirstResponder {
    return true;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = 44.0;
    
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
        
        self.textAttributes = @{
            NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
            NSForegroundColorAttributeName: AAPLColorFromListColor(self.listPresenter.color)
        };
        
        /*
            When the document is opened, make sure that the document stores its extra metadata in the `userInfo`
            dictionary. See `AAPLListDocument`'s -updateUserActivityState: method for more information.
        */
        if (self.document.userActivity) {
            [self.document updateUserActivityState:self.document.userActivity];
        }

        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentStateChangedNotification:) name:UIDocumentStateChangedNotification object:self.document];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self resignFirstResponder];
    
    self.document.delegate = nil;
    [self.document closeWithCompletionHandler:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDocumentStateChangedNotification object:self.document];
    
    // Hide the toolbar so the list can't be edited.
    [self.navigationController setToolbarHidden:YES animated:animated];
}

#pragma mark - Property Overrides

- (NSURL *)documentURL {
    return self.document.fileURL;
}

- (void)setDocument:(AAPLListDocument *)document {
    _document = document;
    
    document.delegate = self;

    self.listPresenter.undoManager = document.undoManager;
    self.listPresenter.delegate = self;
}

- (NSUndoManager *)undoManager {
    return self.document.undoManager;
}

- (AAPLAllListItemsPresenter *)listPresenter {
    return self.document.listPresenter;
}

- (void)setTextAttributes:(NSDictionary *)textAttributes {
    _textAttributes = [textAttributes copy];
    
    if (self.isViewLoaded) {
        [self updateInterfaceWithTextAttributes];
    }
}

// Return the toolbar items since they are used in edit mode.
- (NSArray *)listToolbarItems {
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    NSString *title = NSLocalizedString(@"Delete List", nil);
    UIBarButtonItem *deleteList = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(deleteList:)];
    deleteList.tintColor = [UIColor redColor];

    if ([self.documentURL.lastPathComponent isEqualToString:[AAPLAppConfiguration sharedAppConfiguration].localizedTodayDocumentNameAndExtension]) {
        deleteList.enabled = false;
    }
    
    return @[flexibleSpace, deleteList, flexibleSpace];
}

#pragma mark - Setup

- (void)configureWithListInfo:(AAPLListInfo *)listInfo {
    self.listInfo = listInfo;
    
    AAPLAllListItemsPresenter *listPresenter = [[AAPLAllListItemsPresenter alloc] init];
    self.document = [[AAPLListDocument alloc] initWithFileURL:listInfo.URL listPresenter:listPresenter];

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
    
    // In order to update the UI, dispatch back to the main queue as there are no promises about the queue this will be called on.
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
        // If the list info doesn't already exist (but it should), then create a new one.
        self.listInfo = self.listInfo ?: [[AAPLListInfo alloc] initWithURL:self.documentURL];
        self.listInfo.color = self.listPresenter.color;
        [self.listsController setListInfoHasNewContents:self.listInfo];
        
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
    return self.listPresenter.count + 1;
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

    AAPLListItem *listItem = self.listPresenter.presentedListItems[indexPath.row - 1];
    [self.listPresenter removeListItem:listItem];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    AAPLListItem *item = self.listPresenter.presentedListItems[fromIndexPath.row - 1];
    
    // `toIndexPath.row` will never be `0` since we don't allow moving to the zeroth row (it's the color selection row).
    [self.listPresenter moveListItem:item toIndex:toIndexPath.row - 1];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Make sure the cell is one of the classes we've specified.
    NSParameterAssert([cell isKindOfClass:[AAPLListColorCell class]] || [cell isKindOfClass:[AAPLListItemCell class]]);
    
    if ([cell isKindOfClass:[AAPLListColorCell class]]) {
        AAPLListColorCell *colorCell = (AAPLListColorCell *)cell;
        [colorCell configure];
        colorCell.selectedColor = self.listPresenter.color;
        colorCell.delegate = self;
    }
    else if ([cell isKindOfClass:[AAPLListItemCell class]]) {
        [self configureListItemCell:(AAPLListItemCell *)cell forRow:indexPath.row];
    }
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    /*
        When the user swipes to show the delete confirmation, don't enter editing mode.
        `UITableViewController` enters editing mode by default so we override without calling super.
    */
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    /*
        When the user swipes to hide the delete confirmation, no need to exit edit mode because we didn't enter it.
        `UITableViewController` enters editing mode by default so we override without calling super.
    */
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)fromIndexPath toProposedIndexPath:(NSIndexPath *)proposedIndexPath {
    AAPLListItem *listItem = self.listPresenter.presentedListItems[fromIndexPath.row - 1];
    
    if (proposedIndexPath.row == 0) {
        return fromIndexPath;
    }
    else if ([self.listPresenter canMoveListItem:listItem toIndex:proposedIndexPath.row - 1]) {
        return proposedIndexPath;
    }
    
    return fromIndexPath;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSIndexPath *indexPath = [self indexPathForView:textField];
    
    if (indexPath != nil && indexPath.row > 0) {
        AAPLListItem *listItem = self.listPresenter.presentedListItems[indexPath.row - 1];
        
        [self.listPresenter updateListItem:listItem withText:textField.text];
    }
    else if (textField.text.length > 0) {
        AAPLListItem *listItem = [[AAPLListItem alloc] initWithText:textField.text];
        
        [self.listPresenter insertListItem:listItem];
    }
    
    self.activeTextField = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSIndexPath *indexPath = [self indexPathForView:textField];
    
    if (textField.text.length == 0 || indexPath.row == 0) {
        [textField resignFirstResponder];
        
        return YES;
    }

    return NO;
}

#pragma mark - AAPLListColorCellDelegate

- (void)listColorCellDidChangeSelectedColor:(AAPLListColorCell *)listColorCell {
    self.listPresenter.color = listColorCell.selectedColor;
}

# pragma mark - IBActions

- (IBAction)deleteList:(id)sender {
    [self.listsController removeListInfo:self.listInfo];

    [self hideViewControllerAfterListWasDeleted];
}

- (IBAction)checkBoxTapped:(AAPLCheckBox *)sender {
    NSIndexPath *indexPath = [self indexPathForView:sender];
   
    // Check to see if the tapped row is within the list item rows.
    if (indexPath.row >= 1 && indexPath.row <= self.listPresenter.count) {
        AAPLListItem *listItem = self.listPresenter.presentedListItems[indexPath.row - 1];
        
        [self.listPresenter toggleListItem:listItem];
    }
}

#pragma mark - AAPLListDocumentDelegate

- (void)listDocumentWasDeleted:(AAPLListDocument *)document {
    [self hideViewControllerAfterListWasDeleted];
}

#pragma mark - AAPLListPresenterDelegate

- (void)listPresenterDidRefreshCompleteLayout:(id<AAPLListPresenting>)listPresenter {
    self.textAttributes = @{
        NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName: AAPLColorFromListColor(self.listPresenter.color)
    };
    
    [self.tableView reloadData];
}

- (void)listPresenterWillChangeListLayout:(id<AAPLListPresenting>)listPresenter isInitialLayout:(BOOL)isInitialLayout {
    [self.tableView beginUpdates];
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didInsertListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {
    NSArray *indexPathsForInsertion = @[[NSIndexPath indexPathForRow:index + 1 inSection:0]];
    
    [self.tableView insertRowsAtIndexPaths:indexPathsForInsertion withRowAnimation:UITableViewRowAnimationFade];
    
    // Reload the ListItemCell to be configured for the row to create a new list item.
    if (index == 0) {
        NSArray *indexPathsForReloading = @[[NSIndexPath indexPathForRow:0 inSection:0]];
        
        [self.tableView reloadRowsAtIndexPaths:indexPathsForReloading withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didRemoveListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {
    NSArray *indexPathsForRemoval = @[[NSIndexPath indexPathForRow:index + 1 inSection:0]];
    
    [self.tableView deleteRowsAtIndexPaths:indexPathsForRemoval withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didUpdateListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {
    [self.tableView endUpdates];
    
    [self.tableView beginUpdates];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index + 1 inSection:0];
    
    AAPLListItemCell *listItemCell = (AAPLListItemCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [self configureListItemCell:listItemCell forRow:index + 1];
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didMoveListItem:(AAPLListItem *)listItem fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    NSIndexPath *fromIndexPath = [NSIndexPath indexPathForRow:fromIndex + 1 inSection:0];
    NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:toIndex + 1 inSection:0];
    
    [self.tableView moveRowAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didUpdateListColorWithColor:(AAPLListColor)color {
    self.textAttributes = @{
        NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName: AAPLColorFromListColor(color)
    };
    
    // The document infrastructure needs to be updated to capture the list's color when it changes.
    if (self.document.userActivity) {
        [self.document updateUserActivityState:self.document.userActivity];
    }
}

- (void)listPresenterDidChangeListLayout:(id<AAPLListPresenting>)listPresenter isInitialLayout:(BOOL)isInitialLayout {
    [self.tableView endUpdates];
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

- (void)configureListItemCell:(AAPLListItemCell *)listItemCell forRow:(NSInteger)row {
    listItemCell.checkBox.checked = NO;
    listItemCell.checkBox.hidden = NO;
    
    listItemCell.textField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    listItemCell.textField.delegate = self;
    listItemCell.textField.textColor = [UIColor darkTextColor];
    listItemCell.textField.enabled = YES;
    
    if (row == 0) {
        // Configure an "Add Item" list item cell.
        listItemCell.textField.placeholder = NSLocalizedString(@"Add Item", nil);
        listItemCell.textField.text = @"";
        listItemCell.checkBox.hidden = YES;
    }
    else {
        AAPLListItem *listItem = self.listPresenter.presentedListItems[row - 1];
        
        listItemCell.complete = listItem.isComplete;
        listItemCell.textField.text = listItem.text;
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
