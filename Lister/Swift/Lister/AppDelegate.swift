/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The application delegate.
            
*/

import UIKit
import ListerKit

@UIApplicationMain class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
    var window: UIWindow!
    
    struct MainStoryboard {
        static let name = "Main"
        
        struct Identifiers {
            static let emptyViewController = "emptyViewController"
        }
    }
    
    // MARK: View Controller Accessor Convenience
    
    // The root view controller of the window will always be a UISplitViewController. This is setup in the main storyboard.
    var splitViewController: UISplitViewController {
        return window.rootViewController as UISplitViewController
    }
    
    // The primary view controller of the split view controller defined in the main storyboard.
    var primaryViewController: UINavigationController {
        return splitViewController.viewControllers[0] as UINavigationController
    }
    
    // The view controller that displays the list of documents. If it's not visible, then this value is nil.
    var listDocumentsViewController: ListDocumentsViewController? {
        return primaryViewController.topViewController as? ListDocumentsViewController
    }
    
    // MARK: UIApplicationDelegate
    
    func application(UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary) -> Bool {
        AppConfiguration.sharedConfiguration.runHandlerOnFirstLaunch {
            ListCoordinator.sharedListCoordinator.copyInitialDocuments()
        }
        
        splitViewController.preferredDisplayMode = .AllVisible
        splitViewController.delegate = self
        
        return true
    }
    
    // MARK: UISplitViewControllerDelegate
    
    func targetDisplayModeForActionInSplitViewController(_: UISplitViewController) -> UISplitViewControllerDisplayMode {
        return .AllVisible
    }
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController _: UIViewController) -> Bool {
        splitViewController.preferredDisplayMode = .Automatic
        
        // If there's a list that's currently selected in separated mode and we want to show it in collapsed mode, we'll transfer over the view controller's settings.
        if let secondaryViewController = secondaryViewController as? UINavigationController {
            primaryViewController.navigationBar.titleTextAttributes = secondaryViewController.navigationBar.titleTextAttributes
            primaryViewController.navigationBar.tintColor = secondaryViewController.navigationBar.tintColor
            primaryViewController.toolbar.tintColor = secondaryViewController.toolbar.tintColor
            
            primaryViewController.showDetailViewController(secondaryViewController.topViewController, sender: nil)
        }
        
        return true
    }
    
    func splitViewController(splitViewController: UISplitViewController, separateSecondaryViewControllerFromPrimaryViewController _: UIViewController) -> UIViewController? {
        // If no list is on the stack, fill the detail area with an empty controller.
        if primaryViewController.topViewController === primaryViewController.viewControllers[0] {
            let storyboard = UIStoryboard(name: MainStoryboard.name, bundle: nil)
            
            return storyboard.instantiateViewControllerWithIdentifier(MainStoryboard.Identifiers.emptyViewController) as? UIViewController
        }
        
        let textAttributes = primaryViewController.navigationBar.titleTextAttributes
        let tintColor = primaryViewController.navigationBar.tintColor
        let poppedViewController = primaryViewController.popViewControllerAnimated(false)
        
        let navigationViewController = UINavigationController(rootViewController: poppedViewController)
        navigationViewController.navigationBar.titleTextAttributes = textAttributes
        navigationViewController.navigationBar.tintColor = tintColor
        navigationViewController.toolbar.tintColor = tintColor
        
        return navigationViewController
    }
}

