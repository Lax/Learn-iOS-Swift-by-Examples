/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The application-specific delegate class.
*/

import UIKit

@UIApplicationMain
class AppDelegate: NSObject, UIApplicationDelegate, UISplitViewControllerDelegate {
    // MARK: Properties

    var window: UIWindow?

    // MARK: UIApplicationDelegate

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let splitViewController = window!.rootViewController as! UISplitViewController
        
        splitViewController.delegate = self
        splitViewController.preferredDisplayMode = .AllVisible

        return true
    }
    
    // MARK: UISplitViewControllerDelegate

    func targetDisplayModeForActionInSplitViewController(splitViewController: UISplitViewController) -> UISplitViewControllerDisplayMode {
        return .AllVisible
    }
}
