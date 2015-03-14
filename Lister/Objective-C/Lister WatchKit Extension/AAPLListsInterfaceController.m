/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLListInterfaceController that presents a single list managed by a \c AAPLListPresenting instance.
*/

#import "AAPLListsInterfaceController.h"
#import "AAPLWatchStoryboardConstants.h"
#import "AAPLColoredTextRowController.h"
@import ListerKit;

@interface AAPLListsInterfaceController () <AAPLListsControllerDelegate>

@property (nonatomic, strong) AAPLListsController *listsController;

@property (nonatomic, weak) IBOutlet WKInterfaceTable *interfaceTable;

@end


@implementation AAPLListsInterfaceController

- (instancetype)init {
    self = [super init];

    if (self) {
        _listsController = [[AAPLAppConfiguration sharedAppConfiguration] listsControllerForCurrentConfigurationWithPathExtension:AAPLAppConfigurationListerFileExtension firstQueryHandler:nil];

        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
        [self.interfaceTable insertRowsAtIndexes:indexSet withRowType:AAPLListsInterfaceControllerNoListsRowType];
        
        if ([AAPLAppConfiguration sharedAppConfiguration].isFirstLaunch) {
            NSLog(@"Lister does not currently support configuring a storage option before the iOS app is launched. Please launch the iOS app first. See the Release Notes section in README.md for more information.");
        }
    }

    return self;
}

#pragma mark - Segues

- (id)contextForSegueWithIdentifier:(NSString *)segueIdentifier inTable:(WKInterfaceTable *)table rowIndex:(NSInteger)rowIndex {
    if ([segueIdentifier isEqualToString:AAPLListsInterfaceControllerListSelectionSegue]) {
        AAPLListInfo *listInfo = self.listsController[rowIndex];
        
        return listInfo;
    }
    
    return nil;
}

#pragma mark - AAPLListsControllerDelegate

- (void)listsController:(AAPLListsController *)listsController didInsertListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index {
    NSInteger numberOfLists = self.listsController.count;
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
    
    // The lists controller was previously empty. Remove the "no lists" row.
    if (index == 0 && numberOfLists == 1) {
        [self.interfaceTable removeRowsAtIndexes:indexSet];
    }
    
    [self.interfaceTable insertRowsAtIndexes:indexSet withRowType:AAPLListsInterfaceControllerListRowType];
    [self configureRowControllerAtIndex:index];
}

- (void)listsController:(AAPLListsController *)listsController didRemoveListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index {
    NSInteger numberOfLists = self.listsController.count;
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
    
    [self.interfaceTable removeRowsAtIndexes:indexSet];
    
    // The lists controller is now empty. Add the "no lists" row.
    if (index == 0 && numberOfLists == 0) {
        [self.interfaceTable insertRowsAtIndexes:indexSet withRowType:AAPLListsInterfaceControllerNoListsRowType];
    }
}

- (void)listsController:(AAPLListsController *)listsController didUpdateListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index {
    [self configureRowControllerAtIndex:index];
}

#pragma mark - Convenience

- (void)configureRowControllerAtIndex:(NSInteger)index {
    AAPLColoredTextRowController *watchListRowController = [self.interfaceTable rowControllerAtIndex:index];
    
    AAPLListInfo *listInfo = self.listsController[index];
    
    [watchListRowController setText:listInfo.name];
    
    [listInfo fetchInfoWithCompletionHandler:^{
        /*
             The fetchInfoWithCompletionHandler: method calls its completion handler on a background
             queue, dispatch back to the main queue to make UI updates.
        */
        dispatch_async(dispatch_get_main_queue(), ^{
            AAPLColoredTextRowController *watchListRowController = [self.interfaceTable rowControllerAtIndex:index];
            
            [watchListRowController setColor:AAPLColorFromListColor(listInfo.color)];
        });
    }];
}

#pragma mark - Interface Life Cycle

- (void)willActivate {
    // If the `AAPLListsController` is activating, we should invalidate any pending user activities.
    [self invalidateUserActivity];
    
    self.listsController.delegate = self;

    [self.listsController startSearching];
}

- (void)didDeactivate {
    [self.listsController stopSearching];
    
    self.listsController.delegate = nil;
}

- (void)handleUserActivity:(NSDictionary *)userInfo {
    // The Lister watch app only supports continuing activities where `AAPLAppConfigurationUserActivityListURLPathUserInfoKey` is provided.
    NSString *listInfoFilePath = userInfo[AAPLAppConfigurationUserActivityListURLPathUserInfoKey];
    
    // If no `listInfoFilePath` is found, there is no activity of interest to handle.
    if (!listInfoFilePath) {
        return;
    }

    NSURL *listInfoURL = [NSURL fileURLWithPath:listInfoFilePath isDirectory:NO];
    
    // Create an `AAPLListInfo` that represents the list at `listInfoURL`.
    AAPLListInfo *listInfo = [[AAPLListInfo alloc] initWithURL:listInfoURL];
    
    // Present an `AAPLListInterfaceController`.
    [self pushControllerWithName:AAPLListInterfaceControllerName context:listInfo];
}

@end
