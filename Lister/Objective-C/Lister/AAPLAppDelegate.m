/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The application delegate.
*/

#import "AAPLAppDelegate.h"
#import "AAPLListDocumentsViewController.h"
#import "AAPLListViewController.h"
#import "AAPLAppLaunchContext.h"
@import ListerKit;

// The main storyboard name.
NSString *const AAPLAppDelegateMainStoryboardName = @"Main";

// View controller storyboard identifiers.
NSString *const AAPLAppDelegateMainStoryboardEmptyViewControllerIdentifier = @"emptyViewController";
NSString *const AAPLAppDelegateMainStoryboardListViewControllerIdentifier = @"listViewController";
NSString *const AAPLAppDelegateMainStoryboardListNavigationViewControllerIdentifier = @"listViewNavigationController";

// View controller segue identifiers.
NSString *const AAPLAppDelegateMainStoryboardListDocumentsViewControllerToNewListDocumentControllerSegueIdentifier = @"newListDocument";
NSString *const AAPLAppDelegateMainStoryboardListDocumentsViewControllerToListViewControllerSegueIdentifier = @"showListDocument";
NSString *const AAPLAppDelegateMainStoryboardListDocumentsViewControllerContinueUserActivity = @"showListDocumentFromUserActivity";

@interface AAPLAppDelegate () <UISplitViewControllerDelegate>

@property (nonatomic, strong) AAPLListsController *listsController;

/*!
 * The root view controller of the window will always be a UISplitViewController. This is setup in
 * the main storyboard.
 */
@property (nonatomic, readonly) UISplitViewController *splitViewController;

/*!
 * The primary view controller of the split view controller defined in the main storyboard.
 */
@property (nonatomic, readonly) UINavigationController *primaryViewController;

/*!
 * The view controller that displays the list of documents. If it's not visible, then this value is nil.
 */
@property (nonatomic, readonly) AAPLListDocumentsViewController *listDocumentsViewController;

/*!
 * @return A private, local queue used to ensure serialized access to Cloud containers during application 
 * startup.
 */
@property (nonatomic, strong) dispatch_queue_t appDelegateQueue;

@end

@implementation AAPLAppDelegate

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _appDelegateQueue = dispatch_queue_create("com.example.apple-samplecode.lister.appdelegate", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    AAPLAppConfiguration *appConfiguration = [AAPLAppConfiguration sharedAppConfiguration];
    
    if (appConfiguration.isCloudAvailable) {
        /* 
            Ensure the app sandbox is extended to include the default container. Perform this action on the
            `AAPLAppDelegate`'s serial queue so that actions dependent on the extension always follow it.
         */
        dispatch_async(self.appDelegateQueue, ^{
            // The initial call extends the sandbox. No need to capture the URL.
            [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
        });
    }
    
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Observe changes to the user's iCloud account status (account changed, logged out, etc...).
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(handleUbiquityIdentityDidChangeNotification:) name:NSUbiquityIdentityDidChangeNotification object: nil];
    
    // Provide default lists from the app's bundle on first launch.
    [[AAPLAppConfiguration sharedAppConfiguration] runHandlerOnFirstLaunch:^{
        [AAPLListUtilities copyInitialLists];
    }];
    
    // Set ourselves as the split view controller's delegate.
    self.splitViewController.delegate = self;
    self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    
    // Configure the detail controller in the `UISplitViewController` at the root of the view hierarchy.
    UINavigationController *navigationController = self.splitViewController.viewControllers.lastObject;
    navigationController.topViewController.navigationItem.leftBarButtonItem = [self.splitViewController displayModeButtonItem];
    navigationController.topViewController.navigationItem.leftItemsSupplementBackButton = YES;

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Make sure that user storage preferences are set up after the app sandbox is extended. See `application:willFinishLaunchingWithOptions:` above.
    dispatch_async(self.appDelegateQueue, ^{
        [self setupUserStoragePreferences];
    });
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    // Lister only supports a single user activity type; if you support more than one the type is available from the userActivity parameter.
    if (restorationHandler && self.listDocumentsViewController) {
        // Make sure that user activity continuation occurs after the app sandbox is extended. See `application:willFinishLaunchingWithOptions:` above.
        dispatch_async(self.appDelegateQueue, ^{
            restorationHandler(@[self.listDocumentsViewController]);
        });

        return true;
    }
    
    return false;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // Lister currently only opens URLs of the Lister scheme type.
    if ([url.scheme isEqualToString:AAPLAppConfigurationListerSchemeName]) {
        AAPLAppLaunchContext *launchContext = [[AAPLAppLaunchContext alloc] initWithListerURL: url];
        
        // Only configure the view controller if a launch context was successfully created.
        if (launchContext) {
            // Make sure that URL opening is handled after the app sandbox is extended. See `application:willFinishLaunchingWithOptions:` above.
            dispatch_async(self.appDelegateQueue, ^{
                [self.listDocumentsViewController configureViewControllerWithLaunchContext:launchContext];
            });
            
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - Property Overrides

- (UISplitViewController *)splitViewController {
    return (UISplitViewController *)self.window.rootViewController;
}

- (UINavigationController *)primaryViewController {
    return self.splitViewController.viewControllers.firstObject;
}

- (AAPLListDocumentsViewController *)listDocumentsViewController {
    return (AAPLListDocumentsViewController *)self.primaryViewController.viewControllers.firstObject;
}

#pragma mark - UISplitViewControllerDelegate

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    
    /*
         In a regular width size class, Lister displays a split view controller with a navigation controller
         displayed in both the master and detail areas.
         If there's a list that's currently selected, it should be on top of the stack when collapsed.
         Ensuring that the navigation bar takes on the appearance of the selected list requires the
         transfer of the configuration of the navigation controller that was shown in the detail area.
    */
    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [((UINavigationController *)secondaryViewController).topViewController isKindOfClass:[AAPLListViewController class]]) {
        // Obtain a reference to the navigation controller currently displayed in the detail area.
        UINavigationController *secondaryNavigationController = (UINavigationController *)secondaryViewController;
        
        // Transfer the settings for the `navigationBar` and the `toolbar` to the main navigation controller.
        self.primaryViewController.navigationBar.titleTextAttributes = secondaryNavigationController.navigationBar.titleTextAttributes;
        self.primaryViewController.navigationBar.tintColor = secondaryNavigationController.navigationBar.tintColor;
        self.primaryViewController.toolbar.tintColor = secondaryNavigationController.toolbar.tintColor;

        return NO;
    }

    return YES;
}

- (UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController {
    
    /*
         In this delegate method, the reverse of the collapsing procedure described above needs to be
         carried out if a list is being displayed. The appropriate controller to display in the detail area
         should be returned. If not, the standard behavior is obtained by returning nil.
    */
    if ([self.primaryViewController.topViewController isKindOfClass:[UINavigationController class]] &&
        [((UINavigationController *)self.primaryViewController.topViewController).topViewController isKindOfClass:[AAPLListViewController class]]) {
        // Obtain a reference to the navigation controller containing the list controller to be separated.
        UINavigationController *secondaryViewController = (UINavigationController *)[self.primaryViewController popViewControllerAnimated:NO];
        AAPLListViewController *listViewController = (AAPLListViewController *)secondaryViewController.topViewController;
        
        // Obtain the `textAttributes` and `tintColor` to setup the separated navigation controller.
        NSDictionary *textAttributes = listViewController.textAttributes;
        UIColor *tintColor = AAPLColorFromListColor(listViewController.document.listPresenter.color);
        
        // Transfer the settings for the `navigationBar` and the `toolbar` to the detail navigation controller.
        secondaryViewController.navigationBar.titleTextAttributes = textAttributes;
        secondaryViewController.navigationBar.tintColor = tintColor;
        secondaryViewController.toolbar.tintColor = tintColor;
        
        // Display a bar button on the left to allow the user to expand or collapse the main area, similar to Mail.
        secondaryViewController.topViewController.navigationItem.leftBarButtonItem = [splitViewController displayModeButtonItem];
        
        return secondaryViewController;
    }

    return nil;
}

#pragma mark - Notifications

- (void)handleUbiquityIdentityDidChangeNotification:(NSNotification *)notification {
    [self.primaryViewController popToRootViewControllerAnimated:YES];
    
    [self setupUserStoragePreferences];
}

#pragma mark - User Storage Preferences

- (void)setupUserStoragePreferences {
    AAPLAppStorageState storageState = [AAPLAppConfiguration sharedAppConfiguration].storageState;
    
    /*
        Check to see if the account has changed since the last time the method was called. If it has, let the
        user know that their documents have changed. If they've already chosen local storage (i.e. not iCloud),
        don't notify them since there's no impact.
    */
    if (storageState.accountDidChange) {
        [self notifyUserOfAccountChange:storageState];

        // Return early. State resolution will take place after the user acknowledges the change.
        return;
    }
    
    [self resolveStateForUserStorageState:storageState];
}

- (void)resolveStateForUserStorageState:(AAPLAppStorageState)storageState {
    if (storageState.cloudAvailable) {
        if (storageState.storageOption == AAPLAppStorageNotSet || (storageState.storageOption == AAPLAppStorageLocal && storageState.accountDidChange)) {
            // iCloud is available, but we need to ask the user what they prefer.
            [self promptUserForStorageOption];
        }
        else {
            /*
                The user has already selected a specific storage option. Set up the lists controller to use that
                storage option.
            */
            [self configureListsController:storageState.accountDidChange storageOptionChangeHandler:nil];
        }
    }
    else {
        /*
            iCloud is not available, so we'll reset the storage option and configure the lists controller. The
            next time that the user signs in with an iCloud account, he or she can change provide their desired
            storage option.
        */
        if (storageState.storageOption != AAPLAppStorageNotSet) {
            [AAPLAppConfiguration sharedAppConfiguration].storageOption = AAPLAppStorageNotSet;
        }
        
        [self configureListsController:storageState.accountDidChange storageOptionChangeHandler:nil];
    }
}

#pragma mark - Alerts

- (void)notifyUserOfAccountChange:(AAPLAppStorageState)storageState {
    /*
        Copy a 'Today' list from the bundle to the local documents directory if a 'Today' list doesn't exist.
        This provides more context for the user than no lists and ensures the user always has a 'Today' list (a
        design choice made in Lister).
    */
    if (!storageState.cloudAvailable) {
        [AAPLListUtilities copyTodayList];
    }
    
    NSString *title = NSLocalizedString(@"iCloud Sign Out", nil);
    NSString *message = NSLocalizedString(@"You have signed out of the iCloud account previously used to store documents. Sign back in to access those documents.", nil);
    NSString *okActionTitle = NSLocalizedString(@"OK", nil);
    
    UIAlertController *signedOutController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:okActionTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self resolveStateForUserStorageState:storageState];
    }];
    [signedOutController addAction:action];
    
    [self.listDocumentsViewController presentViewController:signedOutController animated:YES completion:nil];
}

- (void)promptUserForStorageOption {
    NSString *title = NSLocalizedString(@"Choose Storage Option", nil);
    NSString *message = NSLocalizedString(@"Do you want to store documents in iCloud or only on this device?", nil);
    NSString *localOnlyActionTitle = NSLocalizedString(@"Local Only", nil);
    NSString *cloudActionTitle = NSLocalizedString(@"iCloud", nil);
    
    UIAlertController *storageController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *localOption = [UIAlertAction actionWithTitle:localOnlyActionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [AAPLAppConfiguration sharedAppConfiguration].storageOption = AAPLAppStorageLocal;

        [self configureListsController:YES storageOptionChangeHandler:nil];
    }];
    [storageController addAction:localOption];
    
    UIAlertAction *cloudOption = [UIAlertAction actionWithTitle:cloudActionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [AAPLAppConfiguration sharedAppConfiguration].storageOption = AAPLAppStorageCloud;

        [self configureListsController:YES storageOptionChangeHandler:^{
            [AAPLListUtilities migrateLocalListsToCloud];
        }];
    }];
    [storageController addAction:cloudOption];
    
    [self.listDocumentsViewController presentViewController:storageController animated:YES completion:nil];
}

#pragma mark - Convenience

- (void)configureListsController:(BOOL)accountChanged storageOptionChangeHandler:(void (^)(void))storageOptionChangeHandler {
    if (self.listsController != nil && !accountChanged) {
        // The current controller is correct. There is no need to reconfigure it.
        return;
    }

    if (!self.listsController) {
        // There is currently no lists controller. Configure an appropriate one for the current configuration.
        self.listsController = [[AAPLAppConfiguration sharedAppConfiguration] listsControllerForCurrentConfigurationWithPathExtension:AAPLAppConfigurationListerFileExtension firstQueryHandler:storageOptionChangeHandler];
        
        // Ensure that this controller is passed along to the `AAPLListDocumentsViewController`.
        self.listDocumentsViewController.listsController = self.listsController;
        
        [self.listsController startSearching];
    }
    else if (accountChanged) {
        // A lists controller is configured; however, it needs to have its coordinator updated based on the account change. 
        self.listsController.listCoordinator = [[AAPLAppConfiguration sharedAppConfiguration] listsCoordinatorForCurrentConfigurationWithPathExtension:AAPLAppConfigurationListerFileExtension firstQueryHandler:storageOptionChangeHandler];
    }
}

@end
