/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The application delegate.
*/

import UIKit
import Intents
import AscentFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        // Pass the activity to the `WorkoutsController` to handle.
        if let navigationController = window?.rootViewController as? UINavigationController {
            restorationHandler(navigationController.viewControllers)
        }
        
        return true
    }
}
