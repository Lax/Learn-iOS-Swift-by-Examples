/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The application delegate.
            
*/

#import "AAPLAppDelegate.h"
#import "AAPLListDocumentsViewController.h"
#import "AAPLListViewController.h"
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
NSString *const AAPLAppDelegateMainStoryboardListDocumentsViewControllerContinueUserActivityToListViewControllerSegueIdentifier = @"showListDocumentFromUserActivity";

@interface AAPLAppDelegate () <UISplitViewControllerDelegate>

@property (nonatomic, strong) AAPLListController *listController;

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

@end

@implementation AAPLAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(handleUbiquityIdentityDidChangeNotification:) name:NSUbiquityIdentityDidChangeNotification object: nil];
    
    [[AAPLAppConfiguration sharedAppConfiguration] runHandlerOnFirstLaunch:^{
        [AAPLListUtilities copyInitialLists];
    }];
    
    // Set ourselves as the split view controller's delegate.
    self.splitViewController.delegate = self;
    self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    UINavigationController *navigationController = self.splitViewController.viewControllers.lastObject;
    navigationController.topViewController.navigationItem.leftBarButtonItem = [self.splitViewController displayModeButtonItem];
    navigationController.topViewController.navigationItem.leftItemsSupplementBackButton = YES;

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self setupUserStoragePreferences];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler {
    // Lister only supports a single user activity type; if you support more than one the type is available from the `userActivity` parameter.
    if (restorationHandler && self.listDocumentsViewController) {
        restorationHandler(@[self.listDocumentsViewController]);
        return true;
    }
    
    return false;
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
    
    // If there's a list that's currently selected in separated mode and we want to show it in collapsed mode, we'll transfer over the view controller's settings.
    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [((UINavigationController *)secondaryViewController).topViewController isKindOfClass:[AAPLListViewController class]]) {
        UINavigationController *secondaryNavigationController = (UINavigationController *)secondaryViewController;
        
        self.primaryViewController.navigationBar.titleTextAttributes = secondaryNavigationController.navigationBar.titleTextAttributes;
        self.primaryViewController.navigationBar.tintColor = secondaryNavigationController.navigationBar.tintColor;
        self.primaryViewController.toolbar.tintColor = secondaryNavigationController.toolbar.tintColor;

        return NO;
    }

    return YES;
}

- (UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController {
    if ([self.primaryViewController.topViewController isKindOfClass:[UINavigationController class]] &&
        [((UINavigationController *)self.primaryViewController.topViewController).topViewController isKindOfClass:[AAPLListViewController class]]) {
        UINavigationController *secondaryViewController = (UINavigationController *)[self.primaryViewController popViewControllerAnimated:NO];
        AAPLListViewController *listViewController = (AAPLListViewController *)secondaryViewController.topViewController;
        
        // Obtain the `textAttributes` and `tintColor` to setup the separated navigation controller.
        NSDictionary *textAttributes = listViewController.textAttributes;
        UIColor *tintColor = AAPLColorFromListColor(listViewController.document.list.color);
        
        secondaryViewController.navigationBar.titleTextAttributes = textAttributes;
        secondaryViewController.navigationBar.tintColor = tintColor;
        secondaryViewController.toolbar.tintColor = tintColor;
        
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
    
    // Check to see if the account has changed since the last time the method was called. If it has,
    // let the user know that their documents have changed. If they've already chosen local storage
    // (i.e. not iCloud), don't notify them since there's no impact.
    if (storageState.accountDidChange) {
        [self notifyUserOfAccountChange];
    }
    
    if (storageState.cloudAvailable) {
        if (storageState.storageOption == AAPLAppStorageNotSet) {
            // iCloud is available, but we need to ask the user what they prefer.
            [self promptUserForStorageOption];
        }
        else {
            // The user has already selected a specific storage option. Set up the list controller to
            // use that storage option.
            [self configureListController:storageState.accountDidChange];
        }
    }
    else {
        // iCloud is not available, so we'll reset the storage option and configure the list controller.
        // The next time that the user signs in with an iCloud account, he or she can change provide
        // their desired storage option.
        if (storageState.storageOption != AAPLAppStorageNotSet) {
            [AAPLAppConfiguration sharedAppConfiguration].storageOption = AAPLAppStorageNotSet;
        }
        
        [self configureListController:storageState.accountDidChange];
    }
}

#pragma mark - Alerts

- (void)notifyUserOfAccountChange {
    // Copy a 'Today' list from the bundle to the local documents directory if a 'Today' list
    // doesn't exist. This provides more context for the user than no lists and ensures the user
    // always has a 'Today' list (a design choice made in Lister).
    [AAPLListUtilities copyTodayList];
    
    NSString *title = NSLocalizedString(@"iCloud Sign Out", nil);
    NSString *message = NSLocalizedString(@"You have signed out of the iCloud account previously used to store documents. Sign back in to access those documents.", nil);
    NSString *okActionTitle = NSLocalizedString(@"OK", nil);
    
    UIAlertController *signedOutController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [signedOutController addAction:[UIAlertAction actionWithTitle:okActionTitle style:UIAlertActionStyleCancel handler:nil]];
    
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

        [self configureListController:YES];
    }];
    [storageController addAction:localOption];
    
    UIAlertAction *cloudOption = [UIAlertAction actionWithTitle:cloudActionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [AAPLListUtilities migrateLocalListsToCloud];

        [AAPLAppConfiguration sharedAppConfiguration].storageOption = AAPLAppStorageCloud;

        [self configureListController:YES];
    }];
    [storageController addAction:cloudOption];
    
    [self.listDocumentsViewController presentViewController:storageController animated:YES completion:nil];
}

#pragma mark - Convenience

- (void)configureListController:(BOOL)accountChanged {
    id<AAPLListCoordinator> listCoordinator;
    
    if ([AAPLAppConfiguration sharedAppConfiguration].storageOption != AAPLAppStorageCloud) {
        // This will be called if the storage option is either AAPLAppStorageLocal or AAPLAppStorageNotSet.
        listCoordinator = [[AAPLLocalListCoordinator alloc] initWithPathExtension:AAPLAppConfigurationListerFileExtension];
    }
    else {
        listCoordinator = [[AAPLCloudListCoordinator alloc] initWithPathExtension:AAPLAppConfigurationListerFileExtension];
    }
    
    if (!self.listController) {
        self.listController = [[AAPLListController alloc] initWithListCoordinator:listCoordinator sortComparator:^NSComparisonResult(AAPLListInfo *lhs, AAPLListInfo *rhs) {
            return [lhs.name compare:rhs.name];
        }];
        
        self.listDocumentsViewController.listController = self.listController;
    }
    else if (accountChanged) {
        self.listController.listCoordinator = listCoordinator;
    }
}

@end
