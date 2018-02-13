/*
Copyright (C) 2017 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The application delegate class used for setting up our data model and state restoration.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - Properties

    /*
        The app delegate must implement the window from UIApplicationDelegate
        protocol to use a main storyboard file.
    */
    var window: UIWindow?
    
    // MARK: - Application Life Cycle

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let products = [
            Product(hardwareType: Product.deviceTypeTitle, title: Product.Hardware.iPhone, yearIntroduced: 2007, introPrice: 599.00),
            Product(hardwareType: Product.deviceTypeTitle, title: Product.Hardware.iPod, yearIntroduced: 2001, introPrice: 399.00),
            Product(hardwareType: Product.deviceTypeTitle, title: Product.Hardware.iPodTouch, yearIntroduced: 2007, introPrice: 210.00),
            Product(hardwareType: Product.deviceTypeTitle, title: Product.Hardware.iPad, yearIntroduced: 2010, introPrice: 499.00),
            Product(hardwareType: Product.deviceTypeTitle, title: Product.Hardware.iPadMini, yearIntroduced: 2012, introPrice: 659.00),
            Product(hardwareType: Product.desktopTypeTitle, title: Product.Hardware.iMac, yearIntroduced: 1997, introPrice: 1299.00),
            Product(hardwareType: Product.desktopTypeTitle, title: Product.Hardware.MacPro, yearIntroduced: 2006, introPrice: 2499.00),
            Product(hardwareType: Product.portableTypeTitle, title: Product.Hardware.MacBookAir, yearIntroduced: 2008, introPrice: 1799.00),
            Product(hardwareType: Product.portableTypeTitle, title: Product.Hardware.MacBookPro, yearIntroduced: 2006, introPrice: 1499.00)
        ]

		if let navController = window!.rootViewController as? UINavigationController {
			/*
				Note we want the first view controller (not the visibleViewController) in case
				we are being restored from UIStateRestoration.
			*/
			if let tableViewController = navController.viewControllers.first as? MainTableViewController {
				tableViewController.products = products
			}
		}

        return true
    }

    // MARK: - UIStateRestoration

    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }
}
