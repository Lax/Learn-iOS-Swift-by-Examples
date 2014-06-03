/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

*/

import Cocoa
import ListerKitOSX

class ApplicationDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(NSNotification) {
        AppConfiguration.sharedConfiguration.runHandlerOnFirstLaunch {
            // Make sure that no other documents are visible except for the Today document.
            NSDocumentController.sharedDocumentController().closeAllDocumentsWithDelegate(nil, didCloseAllSelector: nil, contextInfo: nil)
            
            self.openTodayDocument()
        }
    }
    
    // Note that there are two possibile callers for this method. The first is the application delegate if it's the first launch.
    // The other possibility is if you use the keyboard shortcut (Command-T) to open your Today document.
    @IBAction func openTodayDocument(_: AnyObject? = nil) {
        let listManager = TodayListManager.sharedTodayListManager
        
        let documentController = NSDocumentController.sharedDocumentController() as NSDocumentController
        
        var error: NSError?
        if !listManager.ensureTodayDocumentExistsWithError(&error) {
            documentController.presentError(error)
            return
        }
        
        documentController.openDocumentWithContentsOfURL(listManager.todayDocumentURL, display: true) { (document, _, _) in
            documentController.addDocument(document)
        }
    }
}

// <rdar://problem/16880777> can't compare two NSObjectProtocol instances even though they implement -isEqual:
func ==(lhs: protocol<NSObjectProtocol, NSCoding, NSCopying>, rhs: protocol<NSObjectProtocol, NSCoding, NSCopying>) -> Bool {
    return lhs.isEqual(rhs)
}
