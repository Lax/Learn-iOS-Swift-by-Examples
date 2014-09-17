/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The \c AAPLListDocumentsViewController displays a list of available documents for users to open.
            
*/

@import ListerKit;

#import "AAPLListDocumentsViewController.h"
#import "AAPLAppDelegate.h"
#import "AAPLNewListDocumentController.h"
#import "AAPLListViewController.h"
#import "AAPLListCell.h"
#import "AAPLListInfo.h"

// Table view cell identifiers.
NSString *const AAPLListDocumentsViewControllerListDocumentCellIdentifier = @"listDocumentCell";

@interface AAPLListDocumentsViewController () <AAPLListControllerDelegate, UIDocumentMenuDelegate, UIDocumentPickerDelegate>

@property (nonatomic,strong) NSUserActivity *pendingUserActivity;

@end


@implementation AAPLListDocumentsViewController
            
#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.titleTextAttributes = @{
        NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName: AAPLColorFromListColor(AAPLListColorGray)
    };
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleContentSizeCategoryDidChangeNotification:) name:UIContentSizeCategoryDidChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.titleTextAttributes = @{
        NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName: AAPLColorFromListColor(AAPLListColorGray)
    };
    
    UIColor *grayListColor = AAPLColorFromListColor(AAPLListColorGray);
    self.navigationController.navigationBar.tintColor = grayListColor;
    self.navigationController.toolbar.tintColor = grayListColor;
    self.tableView.tintColor = grayListColor;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.pendingUserActivity) {
        [self restoreUserActivityState:self.pendingUserActivity];
    }
    
    self.pendingUserActivity = nil;
}

#pragma mark - Property Overrides

- (void)setListController:(AAPLListController *)listController {
    if (listController != _listController) {
        _listController = listController;
        _listController.delegate = self;
    }
}

#pragma mark - Lifetime

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
}

#pragma mark - UIResponder

- (void)restoreUserActivityState:(NSUserActivity *)activity {
    /**
     If there is a list currently displayed; pop to the root view controller (this controller) and
     continue the activity from there. Otherwise, continue the activity directly.
     */
    if ([self.navigationController.topViewController isKindOfClass:[UINavigationController class]]) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        self.pendingUserActivity = activity;
        return;
    }
    
    NSURL *activityURL = activity.userInfo[NSUserActivityDocumentURLKey];
    
    if (activityURL != nil) {
        AAPLListInfo *activityListInfo = [[AAPLListInfo alloc] initWithURL:activityURL];
        
        NSNumber *listInfoColorNumber = activity.userInfo[AAPLAppConfigurationUserActivityListColorUserInfoKey];
        activityListInfo.color = (AAPLListColor)listInfoColorNumber.integerValue;

        [self performSegueWithIdentifier:AAPLAppDelegateMainStoryboardListDocumentsViewControllerContinueUserActivityToListViewControllerSegueIdentifier sender:activityListInfo];
    }
}

#pragma mark - IBActions

/*!
 * Note that the document picker requires that code signing, entitlements, and provisioning for
 * the project have been configured before you run Lister. If you run the app without configuring
 * entitlements correctly, an exception when this method is invoked (i.e. when the "+" button is
 * clicked).
 */
- (IBAction)pickDocument:(UIBarButtonItem *)barButtonItem {
    UIDocumentMenuViewController *documentMenu = [[UIDocumentMenuViewController alloc] initWithDocumentTypes:@[AAPLAppConfigurationListerFileUTI] inMode:UIDocumentPickerModeImport];
    documentMenu.delegate = self;
    
    NSString *newDocumentTitle = NSLocalizedString(@"New List", nil);
    [documentMenu addOptionWithTitle:newDocumentTitle image:nil order:UIDocumentMenuOrderFirst handler:^{
        // Show the AAPLNewListDocumentController.
        [self performSegueWithIdentifier:AAPLAppDelegateMainStoryboardListDocumentsViewControllerToNewListDocumentControllerSegueIdentifier sender:self];
    }];
    
    documentMenu.modalInPopover = UIModalPresentationPopover;
    documentMenu.popoverPresentationController.barButtonItem = barButtonItem;
    
    [self presentViewController:documentMenu animated:YES completion:nil];
}

#pragma mark - UIDocumentMenuDelegate

- (void)documentMenu:(UIDocumentMenuViewController *)documentMenu didPickDocumentPicker:(UIDocumentPickerViewController *)documentPicker {
    documentPicker.delegate = self;
    
    [self presentViewController:documentPicker animated:YES completion:nil];
}

- (void)documentMenuWasCancelled:(UIDocumentMenuViewController *)documentMenu {
    // The user cancelled interacting with the document menu. In your own app, you may want to
    // handle this with other logic.
}

#pragma mark - UIPickerViewDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    // The user selected the document and it should be picked up by the \c AAPLListController.
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    // The user cancelled interacting with the document picker. In your own app, you may want to
    // handle this with other logic.
}

#pragma mark - AAPLListControllerDelegate

- (void)listControllerWillChangeContent:(AAPLListController *)listController {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView beginUpdates];
    });
}

- (void)listController:(AAPLListController *)listController didInsertListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

- (void)listController:(AAPLListController *)listController didRemoveListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

- (void)listController:(AAPLListController *)listController didUpdateListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        
        AAPLListCell *cell = (AAPLListCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.label.text = listInfo.name;

        [listInfo fetchInfoWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                // Make sure that the list info is still visible once the color has been fetched.
                if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
                    cell.listColorView.backgroundColor = AAPLColorFromListColor(listInfo.color);
                }
            });
        }];
    });
}

- (void)listControllerDidChangeContent:(AAPLListController *)listController {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView endUpdates];
    });
}

- (void)listController:(AAPLListController *)listController didFailCreatingListInfo:(AAPLListInfo *)listInfo withError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *title = NSLocalizedString(@"Failed to Create List", nil);
        NSString *message = error.localizedDescription;
        NSString *okActionTitle = NSLocalizedString(@"OK", nil);
        
        UIAlertController *errorOutController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        
        [errorOutController addAction:[UIAlertAction actionWithTitle:okActionTitle style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:errorOutController animated:YES completion:nil];
    });
}

- (void)listController:(AAPLListController *)listController didFailRemovingListInfo:(AAPLListInfo *)listInfo withError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *title = NSLocalizedString(@"Failed to Delete List", nil);
        NSString *message = error.localizedDescription;
        NSString *okActionTitle = NSLocalizedString(@"OK", nil);
        
        UIAlertController *errorOutController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        
        [errorOutController addAction:[UIAlertAction actionWithTitle:okActionTitle style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:errorOutController animated:YES completion:nil];
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listController ? self.listController.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView dequeueReusableCellWithIdentifier:AAPLListDocumentsViewControllerListDocumentCellIdentifier forIndexPath:indexPath];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Assert if attempting to configure an unknown or unsupported cell type.
    NSParameterAssert([cell isKindOfClass:[AAPLListCell class]]);
    
    AAPLListCell *listCell = (AAPLListCell *)cell;
    AAPLListInfo *listInfo = self.listController[indexPath.row];
    
    listCell.label.text = listInfo.name;
    listCell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    listCell.listColorView.backgroundColor = [UIColor clearColor];
    
    // Once the list info has been loaded, update the associated cell's properties.
    [listInfo fetchInfoWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // Make sure that the list info is still visible once the color has been fetched.
            if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
                listCell.listColorView.backgroundColor = AAPLColorFromListColor(listInfo.color);
            }
        });
    }];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - UIStoryboardSegue Handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:AAPLAppDelegateMainStoryboardListDocumentsViewControllerToNewListDocumentControllerSegueIdentifier]) {
        AAPLNewListDocumentController *newListController = segue.destinationViewController;

        newListController.listController = self.listController;
    }
    else if ([segue.identifier isEqualToString:AAPLAppDelegateMainStoryboardListDocumentsViewControllerToListViewControllerSegueIdentifier] ||
             [segue.identifier isEqualToString:AAPLAppDelegateMainStoryboardListDocumentsViewControllerContinueUserActivityToListViewControllerSegueIdentifier]) {
        UINavigationController *listNavigationController = (UINavigationController *)segue.destinationViewController;
        AAPLListViewController *listViewController = (AAPLListViewController *)listNavigationController.topViewController;
        listViewController.listController = self.listController;
        
        listViewController.navigationItem.leftBarButtonItem = [self.splitViewController displayModeButtonItem];
        listViewController.navigationItem.leftItemsSupplementBackButton = YES;
        
        if ([segue.identifier isEqualToString:AAPLAppDelegateMainStoryboardListDocumentsViewControllerToListViewControllerSegueIdentifier]) {
            NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
            [listViewController configureWithListInfo:self.listController[indexPath.row]];
        }
        else if ([segue.identifier isEqualToString:AAPLAppDelegateMainStoryboardListDocumentsViewControllerContinueUserActivityToListViewControllerSegueIdentifier]) {
            AAPLListInfo *userActivityListInfo = sender;
            [listViewController configureWithListInfo:userActivityListInfo];
        }
    }
}

#pragma mark - Notifications

- (void)handleContentSizeCategoryDidChangeNotification:(NSNotification *)notification {
    [self.view setNeedsLayout];
}

@end
