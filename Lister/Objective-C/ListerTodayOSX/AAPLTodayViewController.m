/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLTodayViewController class displays the Today view containing the contents of the Today list.
*/

#import "AAPLTodayViewController.h"
#import "AAPLListRowViewController.h"
#import "AAPLOpenListerRowViewController.h"
#import "AAPLTodayWidgetRequiresCloudViewController.h"
#import "AAPLNoItemsRowViewController.h"
#import "AAPLListRowRepresentedObject.h"
#import "AAPLTodayWidgetRowPurposeBox.h"
@import NotificationCenter;
@import ListerKit;

@interface AAPLTodayViewController () <NCWidgetProviding, NCWidgetListViewDelegate, AAPLListRowViewControllerDelegate, AAPLListPresenterDelegate>

@property (strong) IBOutlet NCWidgetListViewController *widgetListViewController;

@property AAPLListDocument *document;
@property (readonly) AAPLIncompleteListItemsPresenter *listPresenter;

@end

const NSUInteger AAPLTodayViewControllerOpenListerRow = 0;


@implementation AAPLTodayViewController

#pragma mark - NCWidgetProviding

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult result))completionHandler {
    [[AAPLTodayListManager sharedTodayListManager] fetchTodayDocumentURLWithCompletionHandler:^(NSURL *todayDocumentURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (todayDocumentURL == nil) {
                AAPLTodayWidgetRowPurposeBox *requiresCloudPurposeBox = [[AAPLTodayWidgetRowPurposeBox alloc] initWithPurpose:AAPLTodayWidgetRowPurposeRequiresCloud userInfo:nil];
                
                self.widgetListViewController.contents = @[requiresCloudPurposeBox];

                completionHandler(NCUpdateResultFailed);

                return;
            }
            
            NSError *error;
            
            AAPLListDocument *newDocument = [[AAPLListDocument alloc] initWithContentsOfURL:todayDocumentURL listPresenter:nil makesCustomWindowControllers:NO error:&error];
            
            if (newDocument) {
                BOOL existingDocumentIsUpToDate = [self.document.listPresenter.archiveableList isEqualToList:newDocument.listPresenter.archiveableList];

                if (existingDocumentIsUpToDate) {
                    completionHandler(NCUpdateResultNoData);
                }
                else {
                    self.document = newDocument;
                    
                    AAPLIncompleteListItemsPresenter *listPresenter = [[AAPLIncompleteListItemsPresenter alloc] init];
                    listPresenter.delegate = self;
                    
                    self.document.listPresenter = listPresenter;
                    
                    completionHandler(NCUpdateResultNewData);
                }
            }
            else {
                completionHandler(NCUpdateResultFailed);
            }
        });
    }];
}

- (NSEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(NSEdgeInsets)defaultMarginInset {
    return (NSEdgeInsets){
        .left   = 0,
        .right  = 0,
        .top    = 0,
        .bottom = 0
    };
}

- (BOOL)widgetAllowsEditing {
    return NO;
}

#pragma mark - NCWidgetListViewDelegate

- (NSViewController *)widgetList:(NCWidgetListViewController *)listViewController viewControllerForRow:(NSUInteger)row {
    id representedObjectForRow = self.widgetListViewController.contents[row];
    
    if ([representedObjectForRow isKindOfClass:[AAPLTodayWidgetRowPurposeBox class]]) {
        switch ([representedObjectForRow purpose]) {
            case AAPLTodayWidgetRowPurposeOpenLister:
                return [[AAPLOpenListerRowViewController alloc] init];
                break;
                
            case AAPLTodayWidgetRowPurposeNoItemsInList:
                return [[AAPLNoItemsRowViewController alloc] init];
                break;
                
            case AAPLTodayWidgetRowPurposeRequiresCloud:
                return [[AAPLTodayWidgetRequiresCloudViewController alloc] init];
                break;
        }
    }

    AAPLListRowViewController *listRowViewController = [[AAPLListRowViewController alloc] init];
    
    listRowViewController.representedObject = representedObjectForRow;

    listRowViewController.delegate = self;

    return listRowViewController;
    
//    return [[AAPLTodayWidgetRequiresCloudViewController alloc] init];
}

#pragma mark - AAPLListRowViewControllerDelegate

- (void)listRowViewControllerDidChangeRepresentedObjectState:(AAPLListRowViewController *)listRowViewController {
    NSInteger indexOfListRowViewController = [self.widgetListViewController rowForViewController:listRowViewController];
    
    AAPLListItem *listItem = self.listPresenter.presentedListItems[indexOfListRowViewController - 1];
    [self.listPresenter toggleListItem:listItem];
}

#pragma mark - AAPLListPresenting

- (void)listPresenterDidRefreshCompleteLayout:(id<AAPLListPresenting>)listPresenter {
    // Refresh the display for all of the rows.
    [self setListRowRepresentedObjects];
}

/*!
    The following methods are not necessary to implement for the \c AAPLTodayViewController because the rows for
    \c widgetListViewController are set in both -listPresenterDidRefreshCompleteLayout: and in the
    \c -listPresenterDidChangeListLayout:isInitialLayout: method.
 */
- (void)listPresenterWillChangeListLayout:(id<AAPLListPresenting>)listPresenter isInitialLayout:(BOOL)isInitialLayout {}
- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didInsertListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {}
- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didRemoveListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {}
- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didUpdateListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {}
- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didMoveListItem:(AAPLListItem *)listItem fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {}
- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didUpdateListColorWithColor:(AAPLListColor)color {}

- (void)listPresenterDidChangeListLayout:(id<AAPLListPresenting>)listPresenter isInitialLayout:(BOOL)isInitialLayout {
    if (isInitialLayout) {
        [self setListRowRepresentedObjects];
    }
    else {
        [self.document updateChangeCount:NSChangeDone];
        
        [self.document saveDocumentWithDelegate:nil didSaveSelector:NULL contextInfo:NULL];
        
        [[NCWidgetController widgetController] setHasContent:YES forWidgetWithBundleIdentifier:AAPLAppConfigurationWidgetBundleIdentifier];
    }
}

#pragma mark - Convenience

- (AAPLIncompleteListItemsPresenter *)listPresenter {
    return self.document.listPresenter;
}

- (void)setListRowRepresentedObjects {
    NSMutableArray *representedObjects = [NSMutableArray array];

    // The "Open in Lister" has a `representedObject` as an `NSColor`, representing the text color.
    NSColor *listColor = AAPLColorFromListColorForNotificationCenter(self.listPresenter.color);
    AAPLTodayWidgetRowPurposeBox *openInListerPurposeBox = [[AAPLTodayWidgetRowPurposeBox alloc] initWithPurpose:AAPLTodayWidgetRowPurposeOpenLister userInfo:listColor];
    
    [representedObjects addObject:openInListerPurposeBox];

    for (AAPLListItem *listItem in self.listPresenter.presentedListItems) {
        AAPLListRowRepresentedObject *representedObject = [[AAPLListRowRepresentedObject alloc] init];
        
        representedObject.listItem = listItem;
        representedObject.color = listColor;

        [representedObjects addObject:representedObject];
    }

    // Add an `AAPLTodayWidgetRowPurposeNoItemsInList` box to represent the "No Items" represented object.
    if (self.listPresenter.isEmpty) {
        AAPLTodayWidgetRowPurposeBox *noItemsInListPurposeBox = [[AAPLTodayWidgetRowPurposeBox alloc] initWithPurpose:AAPLTodayWidgetRowPurposeNoItemsInList userInfo:nil];

        [representedObjects addObject:noItemsInListPurposeBox];
    }
    
    self.widgetListViewController.contents = representedObjects;
}

@end
