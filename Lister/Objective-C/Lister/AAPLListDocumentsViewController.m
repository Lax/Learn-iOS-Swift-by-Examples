/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLListDocumentsViewController displays a list of available documents for users to open.
*/

@import ListerKit;
@import WatchConnectivity;

#import "AAPLListDocumentsViewController.h"
#import "AAPLAppDelegate.h"
#import "AAPLAppLaunchContext.h"
#import "AAPLNewListDocumentController.h"
#import "AAPLListViewController.h"
#import "AAPLListCell.h"
#import "AAPLListInfo.h"

// Table view cell identifiers.
NSString *const AAPLListDocumentsViewControllerListDocumentCellIdentifier = @"listDocumentCell";

@interface AAPLListDocumentsViewController () <AAPLListsControllerDelegate, UIDocumentMenuDelegate, UIDocumentPickerDelegate, WCSessionDelegate>

@property (nonatomic, strong) AAPLAppLaunchContext *pendingLaunchContext;

@property (nonatomic) BOOL watchAppInstalledAtLastStateChange;

@end


@implementation AAPLListDocumentsViewController
            
#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([WCSession isSupported]) {
        [WCSession defaultSession].delegate = self;
        [[WCSession defaultSession] activateSession];
    }
    
    self.tableView.rowHeight = 44.0;
    
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
    
    if (self.pendingLaunchContext) {
        [self configureViewControllerWithLaunchContext:self.pendingLaunchContext];
    }
    
    self.pendingLaunchContext = nil;
}

#pragma mark - Property Overrides

- (void)setListsController:(AAPLListsController *)listsController {
    if (listsController != _listsController) {
        _listsController = listsController;
        _listsController.delegate = self;
    }
}

#pragma mark - Lifetime

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
}

#pragma mark - UIResponder

- (void)restoreUserActivityState:(NSUserActivity *)activity {
    // Obtain an app launch context from the provided activity and configure the view controller with it.
    AAPLAppLaunchContext *launchContext = [[AAPLAppLaunchContext alloc] initWithUserActivity:activity];
    
    // Configure the view controller with the launch context.
    [self configureViewControllerWithLaunchContext:launchContext];
}

#pragma mark - IBActions

/*!
    Note that the document picker requires that code signing, entitlements, and provisioning for
    the project have been configured before you run Lister. If you run the app without configuring
    entitlements correctly, an exception when this method is invoked (i.e. when the "+" button is
    clicked).
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
    // The user selected the document and it should be picked up by the \c AAPLListsController.
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    // The user cancelled interacting with the document picker. In your own app, you may want to
    // handle this with other logic.
}

#pragma mark - AAPLListsControllerDelegate

- (void)listsControllerWillChangeContent:(AAPLListsController *)listsController {
    [self.tableView beginUpdates];
}

- (void)listsController:(AAPLListsController *)listsController didInsertListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)listsController:(AAPLListsController *)listsController didRemoveListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)listsController:(AAPLListsController *)listsController didUpdateListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)listsControllerDidChangeContent:(AAPLListsController *)listsController {
    [self.tableView endUpdates];
    
    // This method will handle interactions with the watch connectivity session on behalf of the app.
    [self updateWatchConnectivitySessionApplicationContext];
}

- (void)listsController:(AAPLListsController *)listsController didFailCreatingListInfo:(AAPLListInfo *)listInfo withError:(NSError *)error {
    NSString *title = NSLocalizedString(@"Failed to Create List", nil);
    NSString *message = error.localizedDescription;
    NSString *okActionTitle = NSLocalizedString(@"OK", nil);
    
    UIAlertController *errorOutController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [errorOutController addAction:[UIAlertAction actionWithTitle:okActionTitle style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:errorOutController animated:YES completion:nil];
}

- (void)listsController:(AAPLListsController *)listsController didFailRemovingListInfo:(AAPLListInfo *)listInfo withError:(NSError *)error {
    NSString *title = NSLocalizedString(@"Failed to Delete List", nil);
    NSString *message = error.localizedDescription;
    NSString *okActionTitle = NSLocalizedString(@"OK", nil);
    
    UIAlertController *errorOutController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [errorOutController addAction:[UIAlertAction actionWithTitle:okActionTitle style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:errorOutController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listsController ? self.listsController.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView dequeueReusableCellWithIdentifier:AAPLListDocumentsViewControllerListDocumentCellIdentifier forIndexPath:indexPath];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Assert if attempting to configure an unknown or unsupported cell type.
    NSParameterAssert([cell isKindOfClass:[AAPLListCell class]]);
    
    AAPLListCell *listCell = (AAPLListCell *)cell;
    AAPLListInfo *listInfo = self.listsController[indexPath.row];
    
    listCell.label.text = listInfo.name;
    listCell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    listCell.listColorView.backgroundColor = [UIColor clearColor];
    
    // Once the list info has been loaded, update the associated cell's properties.
    [listInfo fetchInfoWithCompletionHandler:^{
        /*
             The fetchInfoWithCompletionHandler: method calls its completion handler on a background
             queue, dispatch back to the main queue to make UI updates.
        */
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

#pragma mark - WCSessionDelegate

- (void)sessionWatchStateDidChange:(nonnull WCSession *)session {
    if (!self.watchAppInstalledAtLastStateChange && session.watchAppInstalled) {
        self.watchAppInstalledAtLastStateChange = session.watchAppInstalled;
        [self updateWatchConnectivitySessionApplicationContext];
    }
}

- (void)session:(nonnull WCSession *)session didFinishFileTransfer:(nonnull WCSessionFileTransfer *)fileTransfer error:(nullable NSError *)error {
    if (error) {
        NSLog(@"%s, file: %@, error: %@", __FUNCTION__, fileTransfer.file.fileURL.lastPathComponent, error.localizedDescription);
    }
}

- (void)session:(nonnull WCSession *)session didReceiveFile:(nonnull WCSessionFile *)file {
    [self.listsController copyListFromURL:file.fileURL toListWithName:[file.fileURL.lastPathComponent stringByDeletingPathExtension]];
}

#pragma mark - UIStoryboardSegue Handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:AAPLAppDelegateMainStoryboardListDocumentsViewControllerToNewListDocumentControllerSegueIdentifier]) {
        AAPLNewListDocumentController *newListController = segue.destinationViewController;

        newListController.listsController = self.listsController;
    }
    else if ([segue.identifier isEqualToString:AAPLAppDelegateMainStoryboardListDocumentsViewControllerToListViewControllerSegueIdentifier] ||
             [segue.identifier isEqualToString:AAPLAppDelegateMainStoryboardListDocumentsViewControllerContinueUserActivity]) {
        UINavigationController *listNavigationController = (UINavigationController *)segue.destinationViewController;
        AAPLListViewController *listViewController = (AAPLListViewController *)listNavigationController.topViewController;
        listViewController.listsController = self.listsController;
        
        listViewController.navigationItem.leftBarButtonItem = [self.splitViewController displayModeButtonItem];
        listViewController.navigationItem.leftItemsSupplementBackButton = YES;
        
        if ([segue.identifier isEqualToString:AAPLAppDelegateMainStoryboardListDocumentsViewControllerToListViewControllerSegueIdentifier]) {
            NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
            [listViewController configureWithListInfo:self.listsController[indexPath.row]];
        }
        else if ([segue.identifier isEqualToString:AAPLAppDelegateMainStoryboardListDocumentsViewControllerContinueUserActivity]) {
            AAPLListInfo *userActivityListInfo = sender;
            [listViewController configureWithListInfo:userActivityListInfo];
        }
    }
}

#pragma mark - Notifications

- (void)handleContentSizeCategoryDidChangeNotification:(NSNotification *)notification {
    [self.view setNeedsLayout];
}


#pragma mark - Convenience

- (void)configureViewControllerWithLaunchContext:(AAPLAppLaunchContext *)launchContext {
    /**
        If there is a list currently displayed; pop to the root view controller (this controller) and
        continue configuration from there. Otherwise, configure the view controller directly.
    */
    if ([self.navigationController.topViewController isKindOfClass:[UINavigationController class]]) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        self.pendingLaunchContext = launchContext;
        
        return;
    }
    
    AAPLListInfo *activityListInfo = [[AAPLListInfo alloc] initWithURL:launchContext.listURL];
    activityListInfo.color = launchContext.listColor;
    
    [self performSegueWithIdentifier:AAPLAppDelegateMainStoryboardListDocumentsViewControllerContinueUserActivity sender:activityListInfo];
}

- (void)updateWatchConnectivitySessionApplicationContext {
    // Do not proceed if `WCSession` is not supported on this iOS device.
    if (![WCSession isSupported]) { return; }
    
    WCSession *session = [WCSession defaultSession];
    
    // Do not proceed if the watch app is not installed on the paired watch.
    if (!session.watchAppInstalled) { return; }
    
    // This array will be used to collect the data about the lists for the application context.
    __block NSMutableArray *lists = [NSMutableArray array];
    // A background queue to execute operations on to fetch the information about the lists.
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    // This operation will execute last and will actually update the application context.
    NSBlockOperation *updateApplicationContextOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error;
        if (![session updateApplicationContext:@{ AAPLApplicationActivityContextCurrentListsKey: [lists copy] } error:&error]) {
            NSLog(@"Error updating context: %@", error.localizedDescription);
        }
    }];
    
    // Loop through the available lists in order to accumulate contextual information about them.
    for (int idx = 0; idx < self.listsController.count; idx++) {
        // Obtain the list info object from the controller.
        AAPLListInfo *info = self.listsController[idx];
        
        // This operation will fetch the information for an individual list.
        NSBlockOperation *listInfoOperation = [NSBlockOperation blockOperationWithBlock:^{
            // The `-fetchInfoWithCompletionHandler:` method executes asynchronously. Use a semaphore to wait.
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [info fetchInfoWithCompletionHandler:^{
                // Now that the `info` object is fully populated. Add an entry to the `lists` dictionary.
                [lists addObject:@{
                    AAPLApplicationActivityContextListNameKey: info.name,
                    AAPLApplicationActivityContextListColorKey: @(info.color)
                }];
                // Signal the semaphore indicating that it can stop waiting.
                dispatch_semaphore_signal(semaphore);
            }];
            // Wait on the semaphore to ensure the operation doesn't return until the fetch is complete.
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }];
        
        // Depending on `listInfoOperation` ensures it completes before `updateApplicationContextOperation` executes.
        [updateApplicationContextOperation addDependency:listInfoOperation];
        [queue addOperation:listInfoOperation];
        
        // Use file coordination to obtain exclusive access to read the file in order to initiate a transfer.
        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
        NSFileAccessIntent *readingIntent = [NSFileAccessIntent readingIntentWithURL:info.URL options:0];
        [fileCoordinator coordinateAccessWithIntents:@[readingIntent] queue:[[NSOperationQueue alloc] init] byAccessor:^(NSError *accessError) {
            if (accessError) {
                return;
            }
            
            // Iterate through outstanding transfers; and cancel any for the same URL as they are obsolete.
            for (WCSessionFileTransfer *transfer in session.outstandingFileTransfers) {
                if ([transfer.file.fileURL isEqual:readingIntent.URL]) {
                    [transfer cancel];
                    break;
                }
            }
            
            // Initiate the new transfer.
            [session transferFile:readingIntent.URL metadata:nil];
        }];
    }
    
    [queue addOperation:updateApplicationContextOperation];
}

@end
