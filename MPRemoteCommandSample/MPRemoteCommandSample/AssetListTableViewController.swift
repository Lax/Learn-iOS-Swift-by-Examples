/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    `AssetListTableViewController` is a `UITableViewController` subclass that lists all the m4a files in the applications bundle that can be played back in the application.
 */

import UIKit
import AVFoundation

class AssetListTableViewController: UITableViewController {
    
    // MARK: Properties
    
    /// An array of `Asset` objects representing the m4a files used for playback in this sample.
    var assets = [Asset]()
    
    /// The instance of `AssetPlaybackManager` to use for playing an `Asset`.
    var assetPlaybackManager: AssetPlaybackManager!
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Populate `assetListTableView` with all the m4a files in the Application bundle.
        guard let enumerator = FileManager.default.enumerator(at: Bundle.main.bundleURL, includingPropertiesForKeys: nil, options: [], errorHandler: nil) else { return }
        
        assets = enumerator.flatMap { element in
            guard let url = element as? URL, url.pathExtension == "m4a" else { return nil }
            
            let fileName = url.lastPathComponent
            return Asset(assetName: fileName, urlAsset: AVURLAsset(url: url))
        }
        
        // Add the notification observers needed to respond to events from the `AssetPlaybackManager`.
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(AssetListTableViewController.handleRemoteCommandNextTrackNotification(notification:)), name: AssetPlaybackManager.nextTrackNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(AssetListTableViewController.handleRemoteCommandPreviousTrackNotification(notification:)), name: AssetPlaybackManager.previousTrackNotification, object: nil)
    }
    
    deinit {
        // Remove all notification observers.
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.removeObserver(self, name: AssetPlaybackManager.nextTrackNotification, object: nil)
        notificationCenter.removeObserver(self, name: AssetPlaybackManager.previousTrackNotification, object: nil)
    }
    
    // MARK: UITableViewDataSource Protocol Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assets.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        
        let asset = assets[indexPath.row]
        
        cell.textLabel?.text = asset.assetName
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let asset = assets[indexPath.row]
        
        assetPlaybackManager.asset = asset
    }
    
    // MARK: Notification Handler Methods
    
    func handleRemoteCommandNextTrackNotification(notification: Notification) {
        guard let assetName = notification.userInfo?[Asset.nameKey] as? String else { return }
        guard let assetIndex = assets.index(where: {$0.assetName == assetName}) else { return }
        
        if assetIndex < assets.count - 1 {
            assetPlaybackManager.asset = assets[assetIndex + 1]
        }
    }
    
    func handleRemoteCommandPreviousTrackNotification(notification: Notification) {
        guard let assetName = notification.userInfo?[Asset.nameKey] as? String else { return }
        guard let assetIndex = assets.index(where: {$0.assetName == assetName}) else { return }
        
        if assetIndex > 0 {
            assetPlaybackManager.asset = assets[assetIndex - 1]
        }
    }
}
