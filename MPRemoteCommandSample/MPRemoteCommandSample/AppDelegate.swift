/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The Application's AppDelegate, contains basic `AVAudioSession` setup.
*/

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: Properties
    
    var window: UIWindow?
    
    /// The instance of `AssetPlaybackManager` that the app uses for managing playback.
    let assetPlaybackManager = AssetPlaybackManager()
    
    /// The instance of `RemoteCommandManager` that the app uses for managing remote command events.
    var remoteCommandManager: RemoteCommandManager!
    
    // MARK: Application Life Cycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Initializer the `RemoteCommandManager`.
        remoteCommandManager = RemoteCommandManager(assetPlaybackManager: assetPlaybackManager)
        
        // Always enable playback commands in MPRemoteCommandCenter.
        remoteCommandManager.activatePlaybackCommands(true)
        
        // Setup AVAudioSession to indicate to the system you how intend to play audio.
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback, mode: AVAudioSessionModeDefault)
        }
        catch {
            print("An error occured setting the audio session category: \(error)")
        }
        
        // Set the AVAudioSession as active.  This is required so that your application becomes the "Now Playing" app.
        do {
            try audioSession.setActive(true, with: [])
        }
        catch {
            print("An Error occured activating the audio session: \(error)")
        }
        
        // Inject dependencies needed by the app.
        
        guard let tabBarController = window?.rootViewController as? UITabBarController,
        let firstNavigationController = tabBarController.viewControllers?.first as? UINavigationController,
        let lastNavigationController = tabBarController.viewControllers?.last as? UINavigationController,
        let assetListTableViewController = firstNavigationController.topViewController as? AssetListTableViewController,
        let remoteCommandListTableViewController = lastNavigationController.topViewController as? RemoteCommandListTableViewController else { return true }
        
        assetListTableViewController.assetPlaybackManager = assetPlaybackManager
        remoteCommandListTableViewController.remoteCommandDataSource = RemoteCommandDataSource(remoteCommandManager: remoteCommandManager)
        
        return true
    }
}

