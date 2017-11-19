/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The app delegate.
 */

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var rootViewController: UIViewController? {
        return window?.rootViewController
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        var performAdditionalHandling = true
        
        window?.makeKeyAndVisible()
        if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem, let rootViewController = rootViewController {
            let didHandleShortcutItem = ShortcutItemHandler.handle(shortcutItem, with: rootViewController)
            performAdditionalHandling = !didHandleShortcutItem
        }
        
        ShortcutItemHandler.updateDynamicShortcutItems(for: application)
        
        return performAdditionalHandling
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        var didHandleShortcutItem = false
        
        if let rootViewController = rootViewController {
            didHandleShortcutItem = ShortcutItemHandler.handle(shortcutItem, with: rootViewController)
        }
        
        completionHandler(didHandleShortcutItem)
    }
}

extension UIApplication {
    func present(alert: UIAlertController, animated: Bool = true) {
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: animated)
    }
}
