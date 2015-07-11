/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLListInterfaceController interface controller that presents a single list managed by an \c AAPLListPresenting object.
*/

#import "AAPLListInterfaceController.h"
#import "AAPLListsInterfaceController.h"
#import "AAPLListItemRowController.h"
#import "AAPLWatchStoryboardConstants.h"

@import WatchConnectivity;
@import ListerKit;

@interface AAPLListInterfaceController () <AAPLListPresenterDelegate, NSFilePresenter>

@property (nonatomic,strong) AAPLIncompleteListItemsPresenter *listPresenter;
@property (nonatomic,strong) AAPLListInfo *listInfo;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *interfaceTable;

@property (copy) NSURL *listURL;
@property (readwrite, retain) NSOperationQueue *presentedItemOperationQueue;

@property (nonatomic) BOOL presenting;
@property (nonatomic) BOOL hasUnsavedChanges;
@property (nonatomic) BOOL editingDisabled;

@end

@implementation AAPLListInterfaceController

#pragma mark - Initializers

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _presentedItemOperationQueue = [[NSOperationQueue alloc] init];
    }
    
    return self;
}

#pragma mark - Property Overrides

- (NSURL *)presentedItemURL {
    return self.listURL;
}

#pragma mark - Interface Table Selection

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
    if (self.editingDisabled) { return; }
    
    AAPLListItem *listItem = self.listPresenter.presentedListItems[rowIndex];
    
    [self.listPresenter toggleListItem:listItem];
    self.hasUnsavedChanges = YES;
}

#pragma mark - Actions

- (IBAction)markAllListItemsAsComplete {
    [self.listPresenter updatePresentedListItemsToCompletionState:YES];
}

- (IBAction)markAllListItemsAsIncomplete {
    [self.listPresenter updatePresentedListItemsToCompletionState:NO];
}

- (void)refreshAllData {
    NSInteger listItemCount = self.listPresenter.count;
    
    if (listItemCount > 0) {
        // Update the data to show all of the list items.
        [self.interfaceTable setNumberOfRows:listItemCount withRowType:AAPLListInterfaceControllerListItemRowType];
        
        for (NSInteger idx = 0; idx < listItemCount; idx++) {
            [self configureRowControllerAtIndex:idx];
        }
    }
    else {
        // Show a "No Items" row.
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
        
        [self.interfaceTable insertRowsAtIndexes:indexSet withRowType:AAPLListInterfaceControllerNoItemsRowType];
    }
}

#pragma mark - ListPresenterDelegate

- (void)listPresenterDidRefreshCompleteLayout:(id<AAPLListPresenting>)listPresenter {
    [self refreshAllData];
}

- (void)listPresenterWillChangeListLayout:(id<AAPLListPresenting>)listPresenter isInitialLayout:(BOOL)isInitialLayout {
    // `WKInterfaceTable` objects do not need to be notified of changes to the table, so this is a no op.
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didInsertListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
    
    // The list presenter was previously empty. Remove the "no items" row.
    if (index == 0 && self.listPresenter.count == 1) {
        [self.interfaceTable removeRowsAtIndexes:indexSet];
    }
    
    [self.interfaceTable insertRowsAtIndexes:indexSet withRowType:AAPLListInterfaceControllerListItemRowType];
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didRemoveListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
    
    [self.interfaceTable removeRowsAtIndexes:indexSet];
    
    // The list presenter is now empty. Add the "no items" row.
    if (index == 0 && self.listPresenter.isEmpty) {
        [self.interfaceTable insertRowsAtIndexes:indexSet withRowType:AAPLListInterfaceControllerNoItemsRowType];
    }
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didUpdateListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {
    [self configureRowControllerAtIndex:index];
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didUpdateListColorWithColor:(AAPLListColor)color {
    for (NSInteger idx = 0; idx < self.listPresenter.count; idx++) {
        [self configureRowControllerAtIndex:idx];
    }
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didMoveListItem:(AAPLListItem *)listItem fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    // Remove the item from the fromIndex straight away.
    NSIndexSet *fromIndexSet = [[NSIndexSet alloc] initWithIndex:fromIndex];
    [self.interfaceTable removeRowsAtIndexes:fromIndexSet];
    
    /*
     Determine where to insert the moved item. If the `toIndex` was beyond the `fromIndex`, normalize
     its value.
     */
    NSIndexSet *toIndexSet;
    if (toIndex > fromIndex) {
        toIndexSet = [[NSIndexSet alloc] initWithIndex:toIndex - 1];
    }
    else {
        toIndexSet = [[NSIndexSet alloc] initWithIndex:toIndex];
    }
    
    [self.interfaceTable insertRowsAtIndexes:toIndexSet withRowType:AAPLListInterfaceControllerListItemRowType];
}

- (void)listPresenterDidChangeListLayout:(id<AAPLListPresenting>)listPresenter isInitialLayout:(BOOL)isInitialLayout {
    if (isInitialLayout) {
        // Display all of the list items on the first layout.
        [self refreshAllData];
    }
}

#pragma mark - Convenience

- (void)addFilePresenterIfNeeded {
    if (!self.presenting) {
        self.presenting = YES;
        [NSFileCoordinator addFilePresenter:self];
    }
}

- (void)removeFilePresenterIfNeeded {
    if (self.presenting) {
        self.presenting = NO;
        [NSFileCoordinator removeFilePresenter:self];
    }
}

- (void)setUpInterfaceTable {
    self.listPresenter = [[AAPLIncompleteListItemsPresenter alloc] init];
    self.listPresenter.delegate = self;
    
    [AAPLListUtilities readListAtURL:self.presentedItemURL withCompletionHandler:^(AAPLList *list, NSError *error) {
        if (error) {
            NSLog(@"Unable to read list at URL.");
        }
        else {
            [self addFilePresenterIfNeeded];
            [self.listPresenter setList:list];
            
            /*
             Once the document for the list has been found and opened, update the user activity with its URL path
             to enable the container iOS app to start directly in this list document. A URL path
             is passed instead of a URL because the `userInfo` dictionary of a WatchKit app's user activity
             does not allow NSURL values.
             */
            NSDictionary *userInfo = @{
                AAPLAppConfigurationUserActivityListURLPathUserInfoKey: self.presentedItemURL.path,
                AAPLAppConfigurationUserActivityListColorUserInfoKey: @(self.listPresenter.color)
            };
            
            /*
             Lister uses a specific user activity name registered in the Info.plist and defined as a constant to
             separate this action from the built-in UIDocument handoff support.
             */
            [self updateUserActivity:AAPLAppConfigurationUserActivityTypeWatch userInfo:userInfo webpageURL:nil];
        }
    }];
}

- (void)configureRowControllerAtIndex:(NSInteger)index {
    AAPLListItemRowController *listItemRowController = [self.interfaceTable rowControllerAtIndex:index];
    
    AAPLListItem *listItem = self.listPresenter.presentedListItems[index];
    
    [listItemRowController setText:listItem.text];
    UIColor *textColor = listItem.isComplete ? [UIColor grayColor] : [UIColor whiteColor];
    [listItemRowController setTextColor:textColor];
    
    // Update the checkbox image.
    NSString *state = listItem.isComplete ? @"checked" : @"unchecked";
    
    NSString *colorName = [AAPLNameFromListColor(self.listPresenter.color) lowercaseString];
    
    NSString *imageName = [NSString stringWithFormat:@"checkbox-%@-%@", colorName, state];
    
    [listItemRowController setCheckBoxImageNamed:imageName];
}

- (void)saveUnsavedChangesWithCompletionHandler:(void (^)(BOOL success))completionHandler {
    if (!self.hasUnsavedChanges) {
        if (completionHandler) {
            completionHandler(YES);
        }
        
        return;
    }
    
    [AAPLListUtilities createList:self.listPresenter.archiveableList atURL:self.presentedItemURL withCompletionHandler:^(NSError *error) {
        BOOL success;
        if (error) {
            success = false;
        }
        else {
            success = true;
            
            WCSession *session = [WCSession defaultSession];
            
            for (WCSessionFileTransfer *transfer in session.outstandingFileTransfers) {
                if ([transfer.file.fileURL isEqual:self.presentedItemURL]) {
                    [transfer cancel];
                    break;
                }
            }
            
            [session transferFile:self.presentedItemURL metadata:nil];
        }
        
        if (completionHandler) {
            completionHandler(success);
        }
    }];
}

#pragma mark - Interface Life Cycle

- (void)awakeWithContext:(id)context {
    NSAssert([context isKindOfClass:[AAPLListInfo class]], @"Expected class of `context` is AAPLListInfo.");
    
    self.listInfo = context;
    NSURL *documentsURL = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    self.listURL = [documentsURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", self.listInfo.name, AAPLAppConfigurationListerFileExtension]];
    
    [self setTitle:self.listInfo.name];
    [self setUpInterfaceTable];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
    
    [self saveUnsavedChangesWithCompletionHandler:^(BOOL success) {
        [self removeFilePresenterIfNeeded];
    }];
}

#pragma mark - NSFilePresenter

- (void)relinquishPresentedItemToReader:(void (^)(void (^ __nullable reacquirer)(void)))reader {
    self.editingDisabled = YES;
    
    if (reader) {
        reader(^{
            self.editingDisabled = NO;
        });
    }
}

- (void)relinquishPresentedItemToWriter:(void (^)(void (^ __nullable reacquirer)(void)))writer {
    self.editingDisabled = YES;
    
    if (writer) {
        writer(^{
            self.editingDisabled = NO;
        });
    }
}

- (void)presentedItemDidChange {
    [self setUpInterfaceTable];
}

- (void)savePresentedItemChangesWithCompletionHandler:(void (^)(NSError * __nullable errorOrNil))completionHandler {
    if (!self.hasUnsavedChanges) {
        if (completionHandler) {
            completionHandler(nil);
        }
        
        return;
    }
    
    [self saveUnsavedChangesWithCompletionHandler:^(BOOL success) {
        if (completionHandler) {
            completionHandler(nil);
        }
    }];
}

- (void)presentedItemDidMoveToURL:(NSURL *)newURL {
    self.listURL = newURL;
}

@end



