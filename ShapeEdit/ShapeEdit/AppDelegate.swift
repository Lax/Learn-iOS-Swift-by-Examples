/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the application delegate and main entry point. It supports open in place to allow opening documents directly from other applications.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
    // MARK: Properties

    var window: UIWindow?
    
    // MARK: UIApplicationDelegate

    func application(application: UIApplication, openURL url: NSURL, options: [String: AnyObject]) -> Bool {
        /*
            `options[UIApplicationOpenURLOptionsOpenInPlaceKey]` will be set if 
            the app doesn't need to make a copy of the document to open or edit it.
            For example, the document could be in the ubiquitous container of the
            application.
        */
        guard let shouldOpenInPlace = options[UIApplicationOpenURLOptionsOpenInPlaceKey] as? Bool else {
            return false
        }
        
        guard let navigation = window?.rootViewController as? UINavigationController else { 
            return false
        }

        guard let documentBrowserController = navigation.viewControllers.first as? DocumentBrowserController else { 
            return false
        }
        
        documentBrowserController.openDocumentAtURL(url, copyBeforeOpening: !shouldOpenInPlace.boolValue)

        return true
    }
}
