/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The `OpenListerRowViewController` class is an NSViewController subclass that provides a row in the NCWidgetListViewController to allow the user to open the Today document in Lister.
            
*/

import Cocoa
import ListerKitOSX

class OpenListerRowViewController: NSViewController {
    // MARK: Properties

    override var nibName: String {
        return "OpenListerRowViewController"
    }
    
    // MARK: IBActions
    
    @IBAction func openInLister(_: NSButton) {
        TodayListManager.fetchTodayDocumentURLWithCompletionHandler { todayDocumentURL in
            if let url = todayDocumentURL {
                NSWorkspace.sharedWorkspace().openURLs([url], withAppBundleIdentifier: AppConfiguration.App.bundleIdentifier, options: .Async, additionalEventParamDescriptor: nil, launchIdentifiers: nil)
            }
        }
    }
}
