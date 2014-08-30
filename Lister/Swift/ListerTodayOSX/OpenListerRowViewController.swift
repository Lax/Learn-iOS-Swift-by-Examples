/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                An NSViewController subclass responsible for providing a row in the NCWidgetListViewController to allow the user to open the Today document in Lister.
            
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
            if let todayDocumentURL = todayDocumentURL {
                let workspace = NSWorkspace.sharedWorkspace()
                let options: NSWorkspaceLaunchOptions = .Async
                
                workspace.openURLs([todayDocumentURL], withAppBundleIdentifier: AppConfiguration.Extensions.widgetBundleIdentifier, options: options, additionalEventParamDescriptor: nil, launchIdentifiers: nil)
            }
        }
    }
}
