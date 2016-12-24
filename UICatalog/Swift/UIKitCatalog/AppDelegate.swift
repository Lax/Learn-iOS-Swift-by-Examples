/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The application-specific delegate class.
*/

import UIKit

@UIApplicationMain
class AppDelegate: NSObject, UIApplicationDelegate, UISplitViewControllerDelegate {
    // MARK: - Properties

    var window: UIWindow?

    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let splitViewController = window!.rootViewController as! UISplitViewController
        
        splitViewController.delegate = self
        splitViewController.preferredDisplayMode = .allVisible

        return true
    }
    
    // MARK: - UISplitViewControllerDelegate

    func targetDisplayModeForAction(in splitViewController: UISplitViewController) -> UISplitViewControllerDisplayMode {
        return .allVisible
    }
}
