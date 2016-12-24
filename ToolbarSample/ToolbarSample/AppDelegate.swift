/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The main NSApplicationDelegate to this sample.
 */

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        // Here we just opt-in for allowing our instance of the NSTouchBar class to be customized throughout the app.
        if #available(OSX 10.12.1, *) {
            if ((NSClassFromString("NSTouchBar")) != nil) {
                NSApplication.shared().isAutomaticCustomizeTouchBarMenuItemEnabled = true
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}
