/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The application delegate.
*/

import UIKit
import ListerKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
    // MARK: Types
    
    struct MainStoryboard {
        static let name = "Main"
        
        struct Identifiers {
            static let emptyViewController = "emptyViewController"
        }
    }

    // MARK: Properties

    var window: UIWindow!

    var listsController: ListsController!
    
    /**
        A private, local queue used to ensure serialized access to Cloud containers during application
        startup.
    */
    let appDelegateQueue = dispatch_queue_create("com.example.apple-samplecode.lister.appdelegate", DISPATCH_QUEUE_SERIAL)

    // MARK: View Controller Accessor Convenience
    
    /**
        The root view controller of the window will always be a `UISplitViewController`. This is set up
        in the main storyboard.
    */
    var splitViewController: UISplitViewController {
        return window.rootViewController as UISplitViewController
    }

    /// The primary view controller of the split view controller defined in the main storyboard.
    var primaryViewController: UINavigationController {
        return splitViewController.viewControllers.first as UINavigationController
    }
    
    /**
        The view controller that displays the list of documents. If it's not visible, then this value
        is `nil`.
    */
    var listDocumentsViewController: ListDocumentsViewController? {
        return primaryViewController.viewControllers.first as? ListDocumentsViewController
    }
    
    // MARK: UIApplicationDelegate
    
    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        let appConfiguration = AppConfiguration.sharedConfiguration
        if appConfiguration.isCloudAvailable {
            /*
                Ensure the app sandbox is extended to include the default container. Perform this action on the
                `AppDelegate`'s serial queue so that actions dependent on the extension always follow it.
            */
            dispatch_async(appDelegateQueue) {
                // The initial call extends the sandbox. No need to capture the URL.
                NSFileManager.defaultManager().URLForUbiquityContainerIdentifier(nil)
                
                return
            }
        }
        
        return true
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Observe changes to the user's iCloud account status (account changed, logged out, etc...).
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleUbiquityIdentityDidChangeNotification:", name: NSUbiquityIdentityDidChangeNotification, object: nil)
        
        // Provide default lists from the app's bundle on first launch.
        AppConfiguration.sharedConfiguration.runHandlerOnFirstLaunch {
            ListUtilities.copyInitialLists()
        }

        splitViewController.delegate = self
        splitViewController.preferredDisplayMode = .AllVisible
        
        // Configure the detail controller in the `UISplitViewController` at the root of the view hierarchy.
        let navigationController = splitViewController.viewControllers.last as UINavigationController
        navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
        navigationController.topViewController.navigationItem.leftItemsSupplementBackButton = true
        
        return true
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Make sure that user storage preferences are set up after the app sandbox is extended. See `application(_:, willFinishLaunchingWithOptions:)` above.
        dispatch_async(appDelegateQueue) {
            self.setupUserStoragePreferences()
        }
    }
    
    func application(_: UIApplication, continueUserActivity: NSUserActivity, restorationHandler: [AnyObject] -> Void) -> Bool {
        // Lister only supports a single user activity type; if you support more than one the type is available from the `continueUserActivity` parameter.
        if let listDocumentsViewController = listDocumentsViewController {
            // Make sure that user activity continuation occurs after the app sandbox is extended. See `application(_:, willFinishLaunchingWithOptions:)` above.
            dispatch_async(appDelegateQueue) {
                restorationHandler([listDocumentsViewController])
            }
            
            return true
        }
        
        return false
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        // Lister currently only opens URLs of the Lister scheme type.
        if url.scheme == AppConfiguration.ListerScheme.name {
            // Obtain an app launch context from the provided lister:// URL and configure the view controller with it.
            let launchContext = AppLaunchContext(listerURL: url)
            
            if let listDocumentsViewController = listDocumentsViewController {
                // Make sure that URL opening is handled after the app sandbox is extended. See `application(_:, willFinishLaunchingWithOptions:)` above.
                dispatch_async(appDelegateQueue) {
                    listDocumentsViewController.configureViewControllerWithLaunchContext(launchContext)
                }
                
                return true
            }
        }
        
        return false
    }
    
    // MARK: UISplitViewControllerDelegate

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController _: UIViewController) -> Bool {
        /*
            In a regular width size class, Lister displays a split view controller with a navigation controller
            displayed in both the master and detail areas.
            If there's a list that's currently selected, it should be on top of the stack when collapsed. 
            Ensuring that the navigation bar takes on the appearance of the selected list requires the 
            transfer of the configuration of the navigation controller that was shown in the detail area.
        */
        if secondaryViewController is UINavigationController && (secondaryViewController as UINavigationController).topViewController is ListViewController {
            // Obtain a reference to the navigation controller currently displayed in the detail area.
            let secondaryNavigationController = secondaryViewController as UINavigationController
            
            // Transfer the settings for the `navigationBar` and the `toolbar` to the main navigation controller.
            primaryViewController.navigationBar.titleTextAttributes = secondaryNavigationController.navigationBar.titleTextAttributes
            primaryViewController.navigationBar.tintColor = secondaryNavigationController.navigationBar.tintColor
            primaryViewController.toolbar?.tintColor = secondaryNavigationController.toolbar?.tintColor
            
            return false
        }
        
        return true
    }
    
    func splitViewController(splitViewController: UISplitViewController, separateSecondaryViewControllerFromPrimaryViewController _: UIViewController) -> UIViewController? {
        /*
            In this delegate method, the reverse of the collapsing procedure described above needs to be
            carried out if a list is being displayed. The appropriate controller to display in the detail area
            should be returned. If not, the standard behavior is obtained by returning nil.
        */
        if primaryViewController.topViewController is UINavigationController && (primaryViewController.topViewController as UINavigationController).topViewController is ListViewController {
            // Obtain a reference to the navigation controller containing the list controller to be separated.
            let secondaryViewController = primaryViewController.popViewControllerAnimated(false) as UINavigationController
            let listViewController = secondaryViewController.topViewController as ListViewController
            
            // Obtain the `textAttributes` and `tintColor` to setup the separated navigation controller.    
            let textAttributes = listViewController.textAttributes
            let tintColor = listViewController.listPresenter.color.colorValue
            
            // Transfer the settings for the `navigationBar` and the `toolbar` to the detail navigation controller.
            secondaryViewController.navigationBar.titleTextAttributes = textAttributes
            secondaryViewController.navigationBar.tintColor = tintColor
            secondaryViewController.toolbar?.tintColor = tintColor
            
            // Display a bar button on the left to allow the user to expand or collapse the main area, similar to Mail.
            secondaryViewController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
            
            return secondaryViewController
        }
        
        return nil
    }
    
    // MARK: Notifications
    
    func handleUbiquityIdentityDidChangeNotification(notification: NSNotification) {
        primaryViewController.popToRootViewControllerAnimated(true)
        
        setupUserStoragePreferences()
    }
    
    // MARK: User Storage Preferences
    
    func setupUserStoragePreferences() {
        let storageState = AppConfiguration.sharedConfiguration.storageState
    
        /*
            Check to see if the account has changed since the last time the method was called. If it has, let
            the user know that their documents have changed. If they've already chosen local storage (i.e. not
            iCloud), don't notify them since there's no impact.
        */
        if storageState.accountDidChange && storageState.storageOption == .Cloud {
            notifyUserOfAccountChange(storageState)
            // Return early. State resolution will take place after the user acknowledges the change.
            return
        }

        resolveStateForUserStorageState(storageState)
    }
    
    func resolveStateForUserStorageState(storageState: StorageState) {
        if storageState.cloudAvailable {
            if storageState.storageOption == .NotSet  || (storageState.storageOption == .Local && storageState.accountDidChange) {
                // iCloud is available, but we need to ask the user what they prefer.
                promptUserForStorageOption()
            }
            else {
                /*
                    The user has already selected a specific storage option. Set up the lists controller to use
                    that storage option.
                */
                configureListsController(accountChanged: storageState.accountDidChange)
            }
        }
        else {
            /* 
                iCloud is not available, so we'll reset the storage option and configure the list controller.
                The next time that the user signs in with an iCloud account, he or she can change provide their
                desired storage option.
            */
            if storageState.storageOption != .NotSet {
                AppConfiguration.sharedConfiguration.storageOption = .NotSet
            }
            
            configureListsController(accountChanged: storageState.accountDidChange)
        }
    }
    
    // MARK: Alerts
    
    func notifyUserOfAccountChange(storageState: StorageState) {
        /*
            Copy a 'Today' list from the bundle to the local documents directory if a 'Today' list doesn't exist.
            This provides more context for the user than no lists and ensures the user always has a 'Today' list (a
            design choice made in Lister).
        */
        if !storageState.cloudAvailable {
            ListUtilities.copyTodayList()
        }
        
        let title = NSLocalizedString("Sign Out of iCloud", comment: "")
        let message = NSLocalizedString("You have signed out of the iCloud account previously used to store documents. Sign back in with that account to access those documents.", comment: "")
        let okActionTitle = NSLocalizedString("OK", comment: "")
        
        let signedOutController = UIAlertController(title: title, message: message, preferredStyle: .Alert)

        let action = UIAlertAction(title: okActionTitle, style: .Cancel) { _ in
            self.resolveStateForUserStorageState(storageState)
        }
        signedOutController.addAction(action)
        
        listDocumentsViewController?.presentViewController(signedOutController, animated: true, completion: nil)
    }
    
    func promptUserForStorageOption() {
        let title = NSLocalizedString("Choose Storage Option", comment: "")
        let message = NSLocalizedString("Do you want to store documents in iCloud or only on this device?", comment: "")
        let localOnlyActionTitle = NSLocalizedString("Local Only", comment: "")
        let cloudActionTitle = NSLocalizedString("iCloud", comment: "")
        
        let storageController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let localOption = UIAlertAction(title: localOnlyActionTitle, style: .Default) { localAction in
            AppConfiguration.sharedConfiguration.storageOption = .Local

            self.configureListsController(accountChanged: true)
        }
        storageController.addAction(localOption)
        
        let cloudOption = UIAlertAction(title: cloudActionTitle, style: .Default) { cloudAction in
            AppConfiguration.sharedConfiguration.storageOption = .Cloud

            self.configureListsController(accountChanged: true) {
                ListUtilities.migrateLocalListsToCloud()
            }
        }
        storageController.addAction(cloudOption)
        
        listDocumentsViewController?.presentViewController(storageController, animated: true, completion: nil)
    }
   
    // MARK: Convenience
    
    func configureListsController(#accountChanged: Bool, storageOptionChangeHandler: (Void -> Void)? = nil) {
        if listsController != nil && !accountChanged {
            // The current controller is correct. There is no need to reconfigure it.
            return
        }

        if listsController == nil {
            // There is currently no lists controller. Configure an appropriate one for the current configuration.
            listsController = AppConfiguration.sharedConfiguration.listsControllerForCurrentConfigurationWithPathExtension(AppConfiguration.listerFileExtension, firstQueryHandler: storageOptionChangeHandler)
            
            // Ensure that this controller is passed along to the `ListDocumentsViewController`.
            listDocumentsViewController?.listsController = listsController
            
            listsController.startSearching()
        }
        else if accountChanged {
            // A lists controller is configured; however, it needs to have its coordinator updated based on the account change. 
            listsController.listCoordinator = AppConfiguration.sharedConfiguration.listCoordinatorForCurrentConfigurationWithLastPathComponent(AppConfiguration.listerFileExtension, firstQueryHandler: storageOptionChangeHandler)
        }
    }
}

