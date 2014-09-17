/*
Copyright (C) 2014 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:

The application delegate class used for setting up our data model and state restoration.

*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: Properties

    var window: UIWindow!
    
    // MARK: Application Life Cycle

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {

        let products = [
            Product(type: Product.deviceTypeTitle, name: "iPhone", year: 2007, price: 599.00),
            Product(type: Product.deviceTypeTitle, name: "iPod", year: 2001, price: 399.00),
            Product(type: Product.deviceTypeTitle, name: "iPod touch", year: 2007, price: 210.00),
            Product(type: Product.deviceTypeTitle, name: "iPad", year: 2010, price: 499.00),
            Product(type: Product.deviceTypeTitle, name: "iPad mini", year: 2012, price: 659.00),
            Product(type: Product.desktopTypeTitle, name: "iMac", year: 1997, price: 1299.00),
            Product(type: Product.desktopTypeTitle, name: "Mac Pro", year: 2006, price: 2499.00),
            Product(type: Product.portableTypeTitle, name: "MacBook Air", year: 2008, price: 1799.00),
            Product(type: Product.portableTypeTitle, name: "MacBook Pro", year: 2006, price: 1499.00)
        ]

        let navController = window.rootViewController as UINavigationController
        
        // Note we want the first view controller (not the visibleViewController) in case
        // we are being store from UIStateRestoration.
        let tableViewController = navController.viewControllers[0] as MainTableViewController
        tableViewController.products = products

        return true
    }

    // MARK: UIStateRestoration

    func application(application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    func application(application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }
}

