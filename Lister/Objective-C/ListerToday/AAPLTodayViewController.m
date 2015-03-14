/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLTodayViewController class displays the Today view containing the contents of the Today list.
*/

@import NotificationCenter;
@import ListerKit;
#import "AAPLTodayViewController.h"
#import "AAPLCheckBoxCell.h"
#import "AAPLListCoordinator.h"
#import "AAPLLocalListCoordinator.h"
#import "AAPLCloudListCoordinator.h"

const CGFloat AAPLTodayRowHeight = 44.f;
const NSInteger AAPLTodayBaseRowCount = 5;

NSString *AAPLTodayViewControllerContentCellIdentifier = @"todayViewCell";
NSString *AAPLTodayViewControllerMessageCellIdentifier = @"messageCell";


@interface AAPLTodayViewController () <AAPLListPresenterDelegate, AAPLListsControllerDelegate, NCWidgetProviding>

@property (nonatomic, strong) AAPLListDocument *document;
@property (nonatomic, getter=isShowingAll) BOOL showingAll;
@property (nonatomic, readonly, getter=isTodayAvailable) BOOL todayAvailable;
@property (nonatomic, strong) AAPLListsController *listsController;
@property (nonatomic, readonly) AAPLIncompleteListItemsPresenter *listPresenter;
@property (nonatomic, readonly) CGFloat preferredViewHeight;

@end

@implementation AAPLTodayViewController

#pragma mark = Properties

- (void)setDocument:(AAPLListDocument *)document {
    _document = document;
    
    document.listPresenter.delegate = self;
}

- (AAPLIncompleteListItemsPresenter *)listPresenter {
    return self.document.listPresenter;
}

- (void)setShowingAll:(BOOL)showingAll {
    if (showingAll != _showingAll) {
        _showingAll = showingAll;
        
        // Now that all items will be shown, resize the content area for the additional rows.
        [self resetContentSize];
    }
}

- (BOOL)isTodayAvailable {
    return self.document && self.listPresenter;
}

- (CGFloat)preferredViewHeight {
    // Determine the total number of items available for presentation.
    NSInteger itemCount = self.isTodayAvailable && !self.listPresenter.isEmpty ? self.listPresenter.count : 1;
    
    /*
        On first launch only display up to `AAPLTodayBaseRowCount + 1` rows. An additional row is used to display
        the "Show All" row.
    */
    NSInteger rowCount = self.isShowingAll ? itemCount : MIN(itemCount, AAPLTodayBaseRowCount + 1);
    
    return rowCount * AAPLTodayRowHeight;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    
    NSString *localizedTodayListName = [AAPLAppConfiguration sharedAppConfiguration].localizedTodayDocumentNameAndExtension;
    
    self.listsController = [[AAPLAppConfiguration sharedAppConfiguration] listsControllerForCurrentConfigurationWithLastPathComponent:localizedTodayListName firstQueryHandler:nil];
    
    self.listsController.delegate = self;
    [self.listsController startSearching];
    
    [self resetContentSize];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.document closeWithCompletionHandler:nil];
}

#pragma mark - NCWidgetProviding

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
    return UIEdgeInsetsMake(defaultMarginInsets.top, 27.f, defaultMarginInsets.bottom, defaultMarginInsets.right);
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    if (completionHandler) {
        completionHandler(NCUpdateResultNewData);
    }
}

#pragma mark - AAPLListsControllerDelegate

- (void)listsController:(AAPLListsController *)listsController didInsertListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index {
    // Once we've found the Today list, we'll hand off ownership of listening to udpates to the list presenter.
    [self.listsController stopSearching];
    
    self.listsController = nil;
    
    // Update the Today widget with the Today list info.
    [self processListInfoAsTodayDocument:listInfo];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.isTodayAvailable) {
        // Make sure to allow for a row to note that the widget is unavailable.
        return 1;
    }
    
    if (self.listPresenter.isEmpty) {
        // Make sure to allow for a row to note that no incomplete items remain.
        return 1;
    }
    
    return self.isShowingAll ? self.listPresenter.count : MIN(self.listPresenter.count, AAPLTodayBaseRowCount + 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.listPresenter) {
        if (self.listPresenter.isEmpty) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:AAPLTodayViewControllerMessageCellIdentifier forIndexPath:indexPath];
            cell.textLabel.text = NSLocalizedString(@"No incomplete items in today's list.", @"");
            
            return cell;
        }
        else {
            NSInteger itemCount = self.listPresenter.count;
            
            /*
                Check to determine what to show at the row at index `AAPLTodayBaseRowCount`. If not showing
                all rows (explicitly) and the item count is less than `AAPLTodayBaseRowCount` + 1 diplay a
                message cell allowing the user to disclose all rows.
             */
            if (!self.showingAll && indexPath.row == AAPLTodayBaseRowCount && itemCount != AAPLTodayBaseRowCount + 1) {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:AAPLTodayViewControllerMessageCellIdentifier forIndexPath:indexPath];
                
                cell.textLabel.text = NSLocalizedString(@"Show All...", @"");
                
                return cell;
            }
            else {
                AAPLCheckBoxCell *checkBoxCell = [tableView dequeueReusableCellWithIdentifier:AAPLTodayViewControllerContentCellIdentifier forIndexPath:indexPath];
                
                AAPLListItem *item = self.listPresenter.presentedListItems[indexPath.row];
                
                [self configureCheckBoxCell:checkBoxCell forListItem:item];
                
                return checkBoxCell;
            }
        }
    }
    else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:AAPLTodayViewControllerMessageCellIdentifier forIndexPath:indexPath];
        
        cell.textLabel.text = NSLocalizedString(@"Lister's Today widget is currently unavailable.", @"");
        
        return cell;
    }
}

- (void)configureCheckBoxCell:(AAPLCheckBoxCell *)checkBoxCell forListItem:(AAPLListItem *)listItem {
    checkBoxCell.checkBox.tintColor = AAPLColorFromListColor(self.listPresenter.color);
    checkBoxCell.checkBox.checked = listItem.isComplete;
    checkBoxCell.checkBox.hidden = NO;
    
    checkBoxCell.label.text = listItem.text;
    
    checkBoxCell.label.textColor = listItem.isComplete ? [UIColor lightGrayColor] : [UIColor whiteColor];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Show all of the cells if the user taps the "Show All..." row.
    if (self.todayAvailable && !self.showingAll && indexPath.row == AAPLTodayBaseRowCount) {
        self.showingAll = YES;
        
        [self.tableView beginUpdates];
        
        NSIndexPath *indexPathForRemoval = [NSIndexPath indexPathForRow:AAPLTodayBaseRowCount inSection:0];
        
        [self.tableView deleteRowsAtIndexPaths:@[indexPathForRemoval] withRowAnimation:UITableViewRowAnimationFade];
        
        NSMutableArray *insertedIndexPaths = [NSMutableArray array];
        
        for (NSInteger idx = AAPLTodayBaseRowCount; idx < self.listPresenter.count; idx++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
            [insertedIndexPaths addObject:indexPath];
        }
        
        [self.tableView insertRowsAtIndexPaths:insertedIndexPaths withRowAnimation:UITableViewRowAnimationFade];
        
        [self.tableView endUpdates];
        
        return;
    }
    
    // Construct a URL with the lister scheme and the file path of the document.
    NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
    urlComponents.scheme = AAPLAppConfigurationListerSchemeName;
    urlComponents.path = self.document.fileURL.path;
    
    // Add a query item to encode the color associated with the list.
    NSString *colorQueryValue = [NSString stringWithFormat:@"%ld", (long)self.listPresenter.color];
    NSURLQueryItem *colorQueryItem = [NSURLQueryItem queryItemWithName:AAPLAppConfigurationListerColorQueryKey value:colorQueryValue];
    urlComponents.queryItems = @[colorQueryItem];

    // Use the `extensionContext`'s ability to open a URL to trigger the containing app.
    [self.extensionContext openURL:urlComponents.URL completionHandler:nil];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.layer.backgroundColor = [UIColor clearColor].CGColor;
}

#pragma mark - IBActions

- (IBAction)checkBoxTapped:(AAPLCheckBox *)sender {
    NSIndexPath *indexPath = [self indexPathForView:sender];
    
    AAPLListItem *item = self.listPresenter.presentedListItems[indexPath.row];
    [self.listPresenter toggleListItem:item];
}

#pragma mark - ListPresenterDelegate

- (void)listPresenterDidRefreshCompleteLayout:(id<AAPLListPresenting>)listPresenter {
    /**
     	Note when we reload the data, the color of the list will automatically change because the list's color
        is only shown in each list item in the iOS Today widget.
     */
    [self.tableView reloadData];
}

- (void)listPresenterWillChangeListLayout:(id<AAPLListPresenting>)listPresenter isInitialLayout:(BOOL)isInitialLayout {
    [self.tableView beginUpdates];
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didInsertListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:index inSection:0]];
    
    // Hide the "No items in list" row.
    if (index == 0 && self.listPresenter.count == 1) {
        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didRemoveListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:index inSection:0]];
    
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    
    // Show the "No items in list" row.
    if (index == 0 && self.listPresenter.isEmpty) {
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didUpdateListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    
    AAPLCheckBoxCell *checkBoxCell = (AAPLCheckBoxCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [self configureCheckBoxCell:checkBoxCell forListItem:self.listPresenter.presentedListItems[indexPath.row]];
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didMoveListItem:(AAPLListItem *)listItem fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    NSIndexPath *fromIndexPath = [NSIndexPath indexPathForRow:fromIndex inSection:0];
    NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:toIndex inSection:0];
    
    [self.tableView moveRowAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didUpdateListColorWithColor:(AAPLListColor)color {
    for (NSInteger idx = 0; idx < self.listPresenter.presentedListItems.count; idx++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
        
        AAPLCheckBoxCell *checkBoxCell = (AAPLCheckBoxCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        checkBoxCell.checkBox.tintColor = AAPLColorFromListColor(color);
    }
}

- (void)listPresenterDidChangeListLayout:(id<AAPLListPresenting>)listPresenter isInitialLayout:(BOOL)isInitialLayout {
    [self resetContentSize];
    
    [self.tableView endUpdates];
    
    /*
        The underlying document changed because of user interaction (this event only occurs if the list
        presenter's underlying list presentation changes based on user interaction).
     */
    if (!isInitialLayout) {
        [self.document updateChangeCount:UIDocumentChangeDone];
    }
}

#pragma mark - Convenience

- (void)processListInfoAsTodayDocument:(AAPLListInfo *)listInfo {
    // Ignore any updates if we already have the Today document.
    if (self.document) {
        return;
    }
    
    AAPLIncompleteListItemsPresenter *incompleteListItemsPresenter = [[AAPLIncompleteListItemsPresenter alloc] init];
    self.document = [[AAPLListDocument alloc] initWithFileURL:listInfo.URL listPresenter:incompleteListItemsPresenter];
    
    [self.document openWithCompletionHandler:^(BOOL success) {
        if (!success) {
            NSLog(@"Couldn't open document: %@.", self.document.fileURL);
        }
        
        [self resetContentSize];
    }];
}

- (NSIndexPath *)indexPathForView:(UIView *)view {
    CGPoint viewOrigin = view.bounds.origin;
    CGPoint viewLocation = [self.tableView convertPoint:viewOrigin fromView:view];
    
    return [self.tableView indexPathForRowAtPoint:viewLocation];
}

- (void)resetContentSize {
    CGSize preferredSize = self.preferredContentSize;

    preferredSize.height = self.preferredViewHeight;

    self.preferredContentSize = preferredSize;
}

@end
