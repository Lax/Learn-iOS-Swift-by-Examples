/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The application delegate.
*/

import Cocoa
import ListerKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: Properties
    
    @IBOutlet weak var todayListMenuItem: NSMenuItem!
    
    var ubiquityIdentityDidChangeNotificationToken: NSObjectProtocol?
    
    // MARK: NSApplicationDelegate
    
    func applicationDidFinishLaunching(notification: NSNotification) {
        AppConfiguration.sharedConfiguration.runHandlerOnFirstLaunch {
            
            // If iCloud is enabled and it's the first launch, we'll show the Today document initially.
            if AppConfiguration.sharedConfiguration.isCloudAvailable {
                // Make sure that no other documents are visible except for the Today document.
                NSDocumentController.sharedDocumentController().closeAllDocumentsWithDelegate(nil, didCloseAllSelector: nil, contextInfo: nil)

                self.openTodayDocument()
            }
        }
        
        // Update the menu item at app launch.
        updateTodayListMenuItemForCloudAvailability()
        
        ubiquityIdentityDidChangeNotificationToken = NSNotificationCenter.defaultCenter().addObserverForName(NSUbiquityIdentityDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            // Update the menu item once the iCloud account changes.
            self?.updateTodayListMenuItemForCloudAvailability()
            
            return
        }
    }
    
    // MARK: IBActions
    
    /**
        Note that there are two possibile callers for this method. The first is the application delegate if
        it's the first launch. The other possibility is if you use the keyboard shortcut (Command-T) to open
        your Today document.
    */
    @IBAction func openTodayDocument(_: AnyObject? = nil) {
        TodayListManager.fetchTodayDocumentURLWithCompletionHandler { url in
            if let url = url {
                dispatch_async(dispatch_get_main_queue()) {
                    let documentController = NSDocumentController.sharedDocumentController() as NSDocumentController
                    
                    documentController.openDocumentWithContentsOfURL(url, display: true) { _ in
                        // Configuration of the document can go here...
                    }
                }
            }
        }
    }
    
    // MARK: Convenience
    
    func updateTodayListMenuItemForCloudAvailability() {
        if AppConfiguration.sharedConfiguration.isCloudAvailable {
            todayListMenuItem.action = "openTodayDocument:"
            todayListMenuItem.target = self
        }
        else {
            todayListMenuItem.action = nil
            todayListMenuItem.target = nil
        }
    }
}

