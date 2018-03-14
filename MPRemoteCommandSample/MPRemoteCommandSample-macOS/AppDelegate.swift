/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	The Application's AppDelegate.
 */

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: Properties
    
    /// The instance of `AssetPlaybackManager` that the app uses for managing playback.
    let assetPlaybackManager = AssetPlaybackManager()
    
    /// The instance of `RemoteCommandManager` that the app uses for managing remote command events.
    var remoteCommandManager: RemoteCommandManager!
    
    // MARK: Application Life Cycle Methods
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Initializer the `RemoteCommandManager`.
        remoteCommandManager = RemoteCommandManager(assetPlaybackManager: assetPlaybackManager)
        
        // Always enable playback commands in MPRemoteCommandCenter.
        remoteCommandManager.activatePlaybackCommands(true)

        // Inject dependencies needed by the app.
        guard let splitViewController = NSApplication.shared().windows.first?.windowController?.contentViewController as? SplitViewController,
            let remoteCommandConfigurationViewController = splitViewController.splitViewItems.first?.viewController as? RemoteCommandConfigurationViewController,
            let assetPlaybackViewController = splitViewController.splitViewItems.last?.viewController as? AssetPlaybackViewController else { return }
        
        assetPlaybackViewController.assetPlaybackManager = assetPlaybackManager
        remoteCommandConfigurationViewController.remoteCommandDataSource = RemoteCommandDataSource(remoteCommandManager: remoteCommandManager)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

