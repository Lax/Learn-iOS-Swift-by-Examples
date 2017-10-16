/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
Main entry point to the application.
*/

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    /*func applicationWillFinishLaunching(_ notification: Notification) {
        NSUserDefaultsController.shared().defaults.set(false, forKey: "NSFullScreenMenuItemEverywhere")
    }*/

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
