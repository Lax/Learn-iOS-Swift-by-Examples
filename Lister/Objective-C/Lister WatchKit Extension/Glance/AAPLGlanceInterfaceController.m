/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Controls the interface of the Glance. The controller displays statistics about the Today list.
*/

#import "AAPLGlanceInterfaceController.h"
#import "AAPLWatchStoryboardConstants.h"
#import "AAPLGlanceBadge.h"
@import ListerKit;

@interface AAPLGlanceInterfaceController () <AAPLListsControllerDelegate, AAPLListPresenterDelegate>

@property (nonatomic, weak) IBOutlet WKInterfaceImage *glanceBadgeImage;
@property (nonatomic, weak) IBOutlet WKInterfaceGroup *glanceBadgeGroup;
@property (nonatomic, weak) IBOutlet WKInterfaceLabel *remainingItemsLabel;

@property (nonatomic, strong) AAPLListsController *listsController;
@property (nonatomic, strong) AAPLListDocument *listDocument;
@property (nonatomic, readonly) AAPLAllListItemsPresenter *listPresenter;

/// These properties track the underlying values that represent the badge.
@property (nonatomic) NSInteger presentedTotalListItemCount;
@property (nonatomic) NSInteger presentedCompleteListItemCount;

@end

/*!
 * Represents an undefined state for either the \c presentedTotalListItemCount or \c presentedCompleteListItemCount
 * properties.
*/
const NSInteger AAPLGlanceInterfaceControllerCountUndefined = -1;

@implementation AAPLGlanceInterfaceController

#pragma mark - Property Overrides

- (AAPLAllListItemsPresenter *)listPresenter {
    return self.listDocument.listPresenter;
}

#pragma mark - Initializers

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _presentedTotalListItemCount = AAPLGlanceInterfaceControllerCountUndefined;
        _presentedCompleteListItemCount = AAPLGlanceInterfaceControllerCountUndefined;
        
        if ([AAPLAppConfiguration sharedAppConfiguration].isFirstLaunch) {
            NSLog(@"Lister does not currently support configuring a storage option before the iOS app is launched. Please launch the iOS app first. See the Release Notes section in README.md for more information.");
        }
    }
    
    return self;
}

#pragma mark - Setup

- (void)setUpInterface {
    // If no previously presented data exists, clear the initial UI elements.
    if (self.presentedCompleteListItemCount == AAPLGlanceInterfaceControllerCountUndefined &&
        self.presentedTotalListItemCount == AAPLGlanceInterfaceControllerCountUndefined) {
        [self.glanceBadgeGroup setBackgroundImage:nil];
        [self.glanceBadgeImage setImage:nil];
        [self.remainingItemsLabel setHidden:YES];
    }
    
    [self initializeListController];
}

- (void)initializeListController {
    NSString *localizedTodayListName = [AAPLAppConfiguration sharedAppConfiguration].localizedTodayDocumentNameAndExtension;

    self.listsController = [[AAPLAppConfiguration sharedAppConfiguration] listsControllerForCurrentConfigurationWithLastPathComponent:localizedTodayListName firstQueryHandler:nil];
    
    self.listsController.delegate = self;
    
    [self.listsController startSearching];
}

#pragma mark - AAPLListsControllerDelegate

- (void)listsController:(AAPLListsController *)listsController didInsertListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index {
    // Once we've found the Today list, we'll hand off ownership of listening to udpates to the list presenter.
    [self.listsController stopSearching];
    
    self.listsController = nil;
    
    // Update the badge with the Today list info.
    [self processListInfoAsTodayDocument:listInfo];
}

#pragma mark - AAPLListPresenterDelegate

- (void)listPresenterDidRefreshCompleteLayout:(id<AAPLListPresenting>)listPresenter {
    // Since the list changed completely, show present the Glance badge.
    [self presentGlanceBadge];
}

/*!
 * These methods are no ops because all of the data is bulk rendered after the the content changes. This can
 * occur in \c -listPresenterDidRefreshCompleteLayout: or in \c -listPresenterDidChangeListLayout:isInitialLayout:.
 */
- (void)listPresenterWillChangeListLayout:(id<AAPLListPresenting>)listPresenter isInitialLayout:(BOOL)isInitialLayout {}
- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didInsertListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {}
- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didRemoveListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {}
- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didUpdateListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {}
- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didUpdateListColorWithColor:(AAPLListColor)color {}
- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didMoveListItem:(AAPLListItem *)listItem fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {}

- (void)listPresenterDidChangeListLayout:(id<AAPLListPresenting>)listPresenter isInitialLayout:(BOOL)isInitialLayout {
    /*
        The list's layout changed. However, since we don't care that a small detail about the list changed,
        we're going to re-animate the badge.
    */
    [self presentGlanceBadge];
}

#pragma mark - Lifecycle

- (void)willActivate {
    /* 
        Setup the interface in `willActivate` to ensure the interface is refreshed each time the interface
        controller is presented.
    */
    [self setUpInterface];
}

- (void)didDeactivate {
    // Close the document when the interface controller is finished presenting.
    [self.listDocument closeWithCompletionHandler:^(BOOL success) {
        if (!success) {
            NSLog(@"Couldn't close document: %@.", self.listDocument.fileURL.absoluteString);
            
            return;
        }
        
        self.listDocument = nil;
    }];
    
    [self.listsController stopSearching];
    self.listsController.delegate = nil;
    self.listsController = nil;
}

#pragma mark - Convenience

- (void)processListInfoAsTodayDocument:(AAPLListInfo *)listInfo {
    AAPLAllListItemsPresenter *listPresenter = [[AAPLAllListItemsPresenter alloc] init];

    self.listDocument = [[AAPLListDocument alloc] initWithFileURL:listInfo.URL listPresenter:listPresenter];
    
    listPresenter.delegate = self;
    
    [self.listDocument openWithCompletionHandler:^(BOOL success) {
        if (!success) {
            NSLog(@"Couldn't open document: %@.", self.listDocument.fileURL.absoluteString);
            
            return;
        }
        
        /*
            Once the Today document has been found and opened, update the user activity with its URL path
            to enable a tap on the glance to jump directly to the Today document in the watch app. A URL path
            is passed instead of a URL because the `userInfo` dictionary of a WatchKit app's user activity
            does not allow NSURL values.
        */
        NSDictionary *userInfo = @{
            AAPLAppConfigurationUserActivityListURLPathUserInfoKey: self.listDocument.fileURL.path,
            AAPLAppConfigurationUserActivityListColorUserInfoKey: @(self.listPresenter.color)
        };
        
        /*
            Lister uses a specific user activity name registered in the Info.plist and defined as a constant to
            separate this action from the built-in UIDocument handoff support.
        */
        [self updateUserActivity:AAPLAppConfigurationUserActivityTypeWatch userInfo:userInfo webpageURL:nil];
    }];
}

- (void)presentGlanceBadge {
    NSInteger totalListItemCount = self.listPresenter.count;

    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"isComplete == YES"];
    NSArray *completeListItems = [self.listPresenter.presentedListItems filteredArrayUsingPredicate:filterPredicate];
    NSInteger completeListItemCount = completeListItems.count;

    /*
        If the `totalListItemCount` and the `completeListItemCount` haven't changed, there's no need to re-present
        the badge.
    */
    if (self.presentedTotalListItemCount == totalListItemCount && self.presentedCompleteListItemCount == completeListItemCount) {
        return;
    }

    // Update `totalListItemCount` and the `completeListItemCount`.
    self.presentedTotalListItemCount = totalListItemCount;
    self.presentedCompleteListItemCount = completeListItemCount;
    
    // Construct and present the new badge.
    AAPLGlanceBadge *glanceBadge = [[AAPLGlanceBadge alloc] initWithTotalItemCount:totalListItemCount completeItemCount:completeListItemCount];

    [self.glanceBadgeGroup setBackgroundImage:glanceBadge.groupBackgroundImage];
    [self.glanceBadgeImage setImageNamed:glanceBadge.imageName];
    [self.glanceBadgeImage startAnimatingWithImagesInRange:glanceBadge.imageRange duration:glanceBadge.animationDuration repeatCount:1];

    /*
        Create a localized string for the # items remaining in the Glance badge. The string is retrieved from
        the Localizable.stringsdict file.
    */
    NSString *itemsRemainingText = [NSString localizedStringWithFormat:NSLocalizedString(@"%d items left", nil), glanceBadge.incompleteItemCount];
    [self.remainingItemsLabel setText:itemsRemainingText];
    [self.remainingItemsLabel setHidden:NO];
}

@end
