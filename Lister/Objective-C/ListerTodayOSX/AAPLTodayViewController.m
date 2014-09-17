/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                 The AAPLTodayViewController class handles display of the Today view. It leverages iCloud for seamless interaction between devices.
              
 */

#import "AAPLTodayViewController.h"
#import "AAPLListRowViewController.h"
#import "AAPLOpenListerRowViewController.h"
#import "AAPLTodayWidgetRequiresCloudViewController.h"
#import "AAPLNoItemsRowViewController.h"
#import "AAPLListRowRepresentedObject.h"
#import "AAPLTodayWidgetRowPurposeBox.h"
@import NotificationCenter;
@import ListerKitOSX;

@interface AAPLTodayViewController () <NCWidgetProviding, NCWidgetListViewDelegate, AAPLListRowViewControllerDelegate, AAPLListDocumentDelegate>

@property (strong) IBOutlet NCWidgetListViewController *listViewController;

@property AAPLListDocument *document;
@property (nonatomic, readonly) AAPLList *list;

@end

const NSUInteger AAPLTodayViewControllerOpenListerRow = 0;

@implementation AAPLTodayViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self updateWidgetContents:nil];
}

- (void)viewWillAppear {
    [super viewWillAppear];

    self.listViewController.delegate = self;
    self.listViewController.hasDividerLines = NO;
    self.listViewController.contents = @[];
    
    [self updateWidgetContents:nil];
}

#pragma mark - NCWidgetProviding

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult result))completionHandler {
    [self updateWidgetContents:completionHandler];
}

- (NSEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(NSEdgeInsets)defaultMarginInset {
    return (NSEdgeInsets){
        .left = 0,
        .right = 0,
        .top = 0,
        .bottom = 0
    };
}

- (BOOL)widgetAllowsEditing {
    return NO;
}

#pragma mark - NCWidgetListViewDelegate

- (NSViewController *)widgetList:(NCWidgetListViewController *)list viewControllerForRow:(NSUInteger)row {
    id representedObjectForRow = self.listViewController.contents[row];
    
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
}

- (BOOL)widgetList:(NCWidgetListViewController *)list shouldRemoveRow:(NSUInteger)row {
    return row != AAPLTodayViewControllerOpenListerRow;
}

- (void)widgetList:(NCWidgetListViewController *)list didRemoveRow:(NSUInteger)row {
    AAPLListItem *item = self.list[row - 1];
    
    [self.list removeItems:@[item]];
    
    [self.document updateChangeCount:NSChangeDone];
}

#pragma mark - AAPLListRowViewControllerDelegate

- (void)listRowViewControllerDidChangeRepresentedObjectState:(AAPLListRowViewController *)listRowViewController {
    NSInteger indexOfListRowViewController = [self.listViewController rowForViewController:listRowViewController];
    
    AAPLListItem *item = self.list[indexOfListRowViewController - 1];
    [self.list toggleItem:item withPreferredDestinationIndex:NSNotFound];
    
    [self.document updateChangeCount:NSChangeDone];

    // Make sure the rows are reordered appropriately.
    self.listViewController.contents = [self listRowRepresentedObjectsForList:self.document.list];
}

#pragma mark - AAPLListDocumentDelegate

- (void)listDocumentDidChangeContents:(AAPLListDocument *)document {
    self.listViewController.contents = [self listRowRepresentedObjectsForList:document.list];
}

#pragma mark - Convenience

- (AAPLList *)list {
    return self.document.list;
}

- (NSArray *)listRowRepresentedObjectsForList:(AAPLList *)list {
    NSArray *listItems = list.allItems;

    NSMutableArray *representedObjects = [NSMutableArray array];

    NSColor *listColor = AAPLColorFromListColor(list.color);
    AAPLTodayWidgetRowPurposeBox *openInListerPurposeBox = [[AAPLTodayWidgetRowPurposeBox alloc] initWithPurpose:AAPLTodayWidgetRowPurposeOpenLister userInfo:listColor];
    
    // The "Open in Lister" has a representedObject as an NSColor, representing the text color.
    [representedObjects addObject:openInListerPurposeBox];

    for (AAPLListItem *item in listItems) {
        AAPLListRowRepresentedObject *representedObject = [[AAPLListRowRepresentedObject alloc] init];
        
        representedObject.item = item;
        representedObject.color = listColor;
        
        [representedObjects addObject:representedObject];
    }
    
    // Add a sentinel NSNull value to represent the "No Items" represented object.
    if (self.list.isEmpty) {
        // No items in the list.
        AAPLTodayWidgetRowPurposeBox *noItemsInListPurposeBox = [[AAPLTodayWidgetRowPurposeBox alloc] initWithPurpose:AAPLTodayWidgetRowPurposeNoItemsInList userInfo:nil];

        [representedObjects addObject:noItemsInListPurposeBox];
    }
    
    return representedObjects;
}

- (void)updateWidgetContents:(void (^)(NCUpdateResult result))completionHandler {
    [[AAPLTodayListManager sharedTodayListManager] fetchTodayDocumentURLWithCompletionHandler:^(NSURL *todayDocumentURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!todayDocumentURL) {
                AAPLTodayWidgetRowPurposeBox *requiresCloudPurposeBox = [[AAPLTodayWidgetRowPurposeBox alloc] initWithPurpose:AAPLTodayWidgetRowPurposeRequiresCloud userInfo:nil];
                
                self.listViewController.contents = @[requiresCloudPurposeBox];

                if (completionHandler) {
                    completionHandler(NCUpdateResultFailed);
                }
                
                return;
            }

            NSError *error;
            AAPLListDocument *document = [[AAPLListDocument alloc] initWithContentsOfURL:todayDocumentURL makesCustomWindowControllers:NO error:&error];
            
            if (error) {
                if (completionHandler) {
                    completionHandler(NCUpdateResultFailed);
                    
                    return;
                }
            }
            else {
                if ([self.document.list isEqualToList:document.list]) {
                    if (completionHandler) {
                        completionHandler(NCUpdateResultNoData);
                    }
                }
                else {
                    self.document = document;
                    self.document.delegate = self;
                    self.listViewController.contents = [self listRowRepresentedObjectsForList:self.document.list];
                    
                    if (completionHandler) {
                        completionHandler(NCUpdateResultNewData);
                    }
                }
            }
        });
    }];
}

@end
