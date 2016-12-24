/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The application delegate.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = [:]) -> Bool {
        
        // Minimal basic setup without a storyboard.
        let localWindow = UIWindow(frame: UIScreen.main.bounds)
        localWindow.rootViewController = CanvasMainViewController()
        localWindow.makeKeyAndVisible()
        window = localWindow
        
        return true
    }

}

