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
@end


@implementation AAPLListDocumentsViewController
            
#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setNeedsStatusBarAppearanceUpdate];
    
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

#pragma mark - Setup

- (void)selectListWithListInfo:(AAPLListInfo *)listInfo {
    if (!self.splitViewController) {
        return;
    }
    
    // A local configuration block to reuse for list selection.
    void (^configureListViewController)(AAPLListViewController *listViewController) = ^(AAPLListViewController *listViewController) {
        listViewController.listController = self.listController;
        [listViewController configureWithListInfo:listInfo];
    };
    
    if (self.splitViewController.isCollapsed) {
        AAPLListViewController *listViewController = [self.storyboard instantiateViewControllerWithIdentifier:AAPLAppDelegateMainStoryboardListViewControllerIdentifier];
        
        configureListViewController(listViewController);

        [self showViewController:listViewController sender:self];
    }
    else {
        UINavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:AAPLAppDelegateMainStoryboardListNavigationViewControllerIdentifier];
        
        AAPLListViewController *listViewController = (AAPLListViewController *)navigationController.topViewController;
        
        configureListViewController(listViewController);
        
        self.splitViewController.viewControllers = @[self.splitViewController.viewControllers.firstObject, [[UIViewController alloc] init]];

        [self showDetailViewController:navigationController sender:self];
    }
}

#pragma mark - IBActions

/*!
 * Note that the document picker requires that code signing, entitlements, and provisioning for
 * the project have been configured before you run Lister. If you run the app without configuring
 * entitlements correctly, an exception when this method is invoked (i.e. when the "+" button is
 * clicked).
 */
- (IBAction)pickDocument {
    UIDocumentMenuViewController *documentMenu = [[UIDocumentMenuViewController alloc] initWithDocumentTypes:@[AAPLAppConfigurationListerFileUTI] inMode:UIDocumentPickerModeImport];
    documentMenu.delegate = self;
    
    NSString *newDocumentTitle = NSLocalizedString(@"New List", nil);
    [documentMenu addOptionWithTitle:newDocumentTitle image:nil order:UIDocumentMenuOrderFirst handler:^{
        // Show the AAPLNewListDocumentController.
        [self performSegueWithIdentifier:AAPLAppDelegateMainStoryboardListDocumentsViewControllerToNewListDocumentControllerSegueIdentifier sender:self];
    }];
    
    documentMenu.modalInPopover = UIModalPresentationPopover;
    
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
    AAPLListCell *cell = [tableView dequeueReusableCellWithIdentifier:AAPLListDocumentsViewControllerListDocumentCellIdentifier forIndexPath:indexPath];
    
    AAPLListInfo *listInfo = self.listController[indexPath.row];

    cell.label.text = listInfo.name;
    cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    cell.listColorView.backgroundColor = [UIColor clearColor];
    
    // Once the list info has been loaded, update the associated cell's properties.
    [listInfo fetchInfoWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // Make sure that the list info is still visible once the color has been fetched.
            if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
                cell.listColorView.backgroundColor = AAPLColorFromListColor(listInfo.color);
            }
        });
    }];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AAPLListInfo *listInfo = self.listController[indexPath.row];
    
    [self selectListWithListInfo:listInfo];
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
}

#pragma mark - Notifications

- (void)handleContentSizeCategoryDidChangeNotification:(NSNotification *)notification {
    [self.view setNeedsLayout];
}

@end
