/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLListInterfaceController interface controller that presents a single list managed by an \c AAPLListPresenting object.
*/

#import "AAPLListsInterfaceController.h"
#import "AAPLExtensionDelegate.h"
#import "AAPLWatchStoryboardConstants.h"
#import "AAPLColoredTextRowController.h"

@import UIKit;
@import WatchConnectivity;
@import ListerKit;

@interface AAPLListsInterfaceController () <AAPLConnectivityListsControllerDelegate>

@property (nonatomic, strong) AAPLConnectivityListsController *listsController;

@property (nonatomic, weak) IBOutlet WKInterfaceTable *interfaceTable;

@end

@implementation AAPLListsInterfaceController

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _listsController = [[AAPLConnectivityListsController alloc] init];
        
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
        [_interfaceTable insertRowsAtIndexes:indexSet withRowType:AAPLListsInterfaceControllerNoListsRowType];
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

#pragma mark - AAPLConnectivityListsController

- (void)listsController:(AAPLConnectivityListsController *)listsController didInsertListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index {
    NSInteger numberOfLists = self.listsController.count;
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
    
    // The lists controller was previously empty. Remove the "no lists" row.
    if (index == 0 && numberOfLists == 1) {
        [self.interfaceTable removeRowsAtIndexes:indexSet];
    }
    
    [self.interfaceTable insertRowsAtIndexes:indexSet withRowType:AAPLListsInterfaceControllerListRowType];
    [self configureRowControllerAtIndex:index];
}

- (void)listsController:(AAPLConnectivityListsController *)listsController didRemoveListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index {
    NSInteger numberOfLists = self.listsController.count;
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
    
    [self.interfaceTable removeRowsAtIndexes:indexSet];
    
    // The lists controller is now empty. Add the "no lists" row.
    if (index == 0 && numberOfLists == 0) {
        [self.interfaceTable insertRowsAtIndexes:indexSet withRowType:AAPLListsInterfaceControllerNoListsRowType];
    }
}

- (void)listsController:(AAPLConnectivityListsController *)listsController didUpdateListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index {
    [self configureRowControllerAtIndex:index];
}

#pragma mark - Convenience

- (void)configureRowControllerAtIndex:(NSInteger)index {
    AAPLColoredTextRowController *watchListRowController = [self.interfaceTable rowControllerAtIndex:index];

    AAPLListInfo *listInfo = self.listsController[index];
    
    [watchListRowController setColor:AAPLColorFromListColor(listInfo.color)];
    [watchListRowController setText:listInfo.name];
}

#pragma mark - Interface Life Cycle

- (void)willActivate {
    AAPLExtensionDelegate *extensionDelegate = [WKExtension sharedExtension].delegate;
    
    if (extensionDelegate) {
        extensionDelegate.mainInterfaceController = self;
    }
    
    // If the `AAPLListsController` is activating, we should invalidate any pending user activities.
    [self invalidateUserActivity];
    
    self.listsController.delegate = self;
    
    [self.listsController startSearching];
}

- (void)didDeactivate {
    [self.listsController stopSearching];
}

- (void)handleUserActivity:(NSDictionary *)userInfo {
    // The Lister watch app only supports continuing activities where `AAPLAppConfigurationUserActivityListURLPathUserInfoKey` is provided.
    NSString *listInfoFilePath = userInfo[AAPLAppConfigurationUserActivityListURLPathUserInfoKey];
    
    
    // If no `listInfoFilePath` is found, there is no activity of interest to handle.
    if (!listInfoFilePath) {
        return;
    }
    
    // Create an `AAPLListInfo` that represents the list at `listInfoFilePath`.
    AAPLListInfo *listInfo = [[AAPLListInfo alloc] init];
    listInfo.name = listInfoFilePath.lastPathComponent.stringByDeletingPathExtension;
    listInfo.color = [userInfo[AAPLAppConfigurationUserActivityListColorUserInfoKey] integerValue];
    
    // Present an `AAPLListInterfaceController`.
    [self pushControllerWithName:AAPLListInterfaceControllerName context:listInfo];
}

@end



