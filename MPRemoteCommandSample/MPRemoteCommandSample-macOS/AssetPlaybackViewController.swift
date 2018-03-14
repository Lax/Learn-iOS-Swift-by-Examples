/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    `AssetPlaybackViewController` is a `NSViewController` subclass that lists all the m4a files in the applications bundle that can be played back in the application as well as provides basic metadata about the currently playing `Asset`.
 */

import Cocoa
import AVFoundation

class AssetPlaybackViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    // MARK: Types
    
    /// The reuse identifier to use for retrieving a view that represents an `Asset`.
    static let assetTableCellViewIdentifier = "AssetTableCellViewIdentifier"

    // MARK: Properties
    
    /// The `NSImageView` for displaying the artwork of the currently playing `Asset`.
    @IBOutlet weak var assetCoverArtImageView: NSImageView!
    
    /// The 'NSTextField` for displaying the `assetName` of the currently playing `Asset`.
    @IBOutlet weak var assetNameTextField: NSTextField!
    
    /// The 'NSTextField` for displaying the current playback position in minutes and seconds of the currently playing `Asset`.
    @IBOutlet weak var currentPlaybackPositionTextField: NSTextField!
    
    /// The `NSProgressIndicator` for displaying the playback progress of the currently playing `Asset`.
    @IBOutlet weak var playbackProgressIndicator: NSProgressIndicator!
    
    /// The `NSTextField` for displaying the total duration in minutes and seconds of the currently playing `Asset`.
    @IBOutlet weak var totalPlaybackDurationTextField: NSTextField!
    
    /// The `NSTableView` used for displaying a list of `Asset` objects.
    @IBOutlet weak var assetListTableView: NSTableView!
    
    /// The `NSButton` that can be used to either return back to the beginning of the currently playing `Asset` or to switch playback to the previous `Asset` in the list if any.  See `handleUserDidPressBackwardToolbarItem(_:)` for how this is determined.
    @IBOutlet weak var backwardButton: NSButton!
    
    /// The `NSButton` that can be used to play or pause playback of the currently playing `Asset`.
    @IBOutlet weak var playPauseButton: NSButton!
    
    /// The `NSButton` that can be used to switch playback to the next `Asset` in the list if any.
    @IBOutlet weak var forwardButton: NSButton!
    
    /// An array of `Asset` objects representing the m4a files used for playback in this sample.
    var assets = [Asset]()
    
    /// The instance of `DateComponentsFormatter` used for formatting times displayed in `currentPlaybackPositionTextField` and `totalPlaybackDurationTextField`.
    let dateComponentFormatter = DateComponentsFormatter()
    
    /// The instance of `AssetPlaybackManager` to use for playing an `Asset` and triggering playback events.
    var assetPlaybackManager: AssetPlaybackManager! {
        didSet {
            // Add the Key-Value Observers needed to keep the UI up to date.
            assetPlaybackManager.addObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.percentProgress), options: NSKeyValueObservingOptions.new, context: nil)
            assetPlaybackManager.addObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.duration), options: NSKeyValueObservingOptions.new, context: nil)
            assetPlaybackManager.addObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.playbackPosition), options: NSKeyValueObservingOptions.new, context: nil)
            
            // Add the notification observers needed to respond to events from the `AssetPlaybackManager`.
            let notificationCenter = NotificationCenter.default
            
            notificationCenter.addObserver(self, selector: #selector(AssetPlaybackViewController.handleCurrentAssetDidChangeNotification(notification:)), name: AssetPlaybackManager.currentAssetDidChangeNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(AssetPlaybackViewController.handleRemoteCommandNextTrackNotification(notification:)), name: AssetPlaybackManager.nextTrackNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(AssetPlaybackViewController.handleRemoteCommandPreviousTrackNotification(notification:)), name: AssetPlaybackManager.previousTrackNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(AssetPlaybackViewController.handlePlayerRateDidChangeNotification(notification:)), name: AssetPlaybackManager.playerRateDidChangeNotification, object: nil)
        }
    }

    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the `DateComponentsFormatter` for formatting strings in a "0:00" format.
        dateComponentFormatter.unitsStyle = .positional
        dateComponentFormatter.allowedUnits = [.minute, .second]
        dateComponentFormatter.zeroFormattingBehavior = [.pad]
        
        // Populate `assetListTableView` with all the m4a files in the Application bundle.
        guard let enumerator = FileManager.default.enumerator(at: Bundle.main.bundleURL, includingPropertiesForKeys: nil, options: [], errorHandler: nil) else { return }
        
        assets = enumerator.flatMap { element in
            guard let url = element as? URL, url.pathExtension == "m4a" else { return nil }
            
            let fileName = url.lastPathComponent
            return Asset(assetName: fileName, urlAsset: AVURLAsset(url: url))
        }
        
        assetListTableView.reloadData()
    }
    
    deinit {
        // Remove all KVO and notification observers.
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.removeObserver(self, name: AssetPlaybackManager.currentAssetDidChangeNotification, object: nil)
        notificationCenter.removeObserver(self, name: AssetPlaybackManager.previousTrackNotification, object: nil)
        notificationCenter.removeObserver(self, name: AssetPlaybackManager.nextTrackNotification, object: nil)
        notificationCenter.removeObserver(self, name: AssetPlaybackManager.playerRateDidChangeNotification, object: nil)
        
        assetPlaybackManager.removeObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.percentProgress))
        assetPlaybackManager.removeObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.duration))
        assetPlaybackManager.removeObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.playbackPosition))
    }
    
    // MARK: NSTableViewDataSource Protocol Methods
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return assets.count
    }
    
    // MARK: NSTableViewDelegate Protocol Methods
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableCellView = tableView.make(withIdentifier: AssetPlaybackViewController.assetTableCellViewIdentifier, owner: self) as? NSTableCellView else { return nil }
        
        let asset = assets[row]
        
        tableCellView.textField?.stringValue = asset.assetName
        
        return tableCellView
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = assetListTableView.selectedRow
        
        if selectedRow != -1 {
            let asset = assets[selectedRow]
            
            assetPlaybackManager.asset = asset
        }
    }
    
    // MARK: Target-Action Methods
    
    @IBAction func handleUserDidPressBackwardButton(_ sender: Any) {
        if assetPlaybackManager.playbackPosition < 5.0 {
            // If the currently playing asset is less than 5 seconds into playback then skip to the previous `Asset`.
            assetPlaybackManager.previousTrack()
        }
        else {
            // Otherwise seek back to the beginning of the currently playing `Asset`.
            assetPlaybackManager.seekTo(0)
        }
    }
    
    @IBAction func handleUserDidPressPlayPauseButton(_ sender: Any) {
        assetPlaybackManager.togglePlayPause()
    }

    @IBAction func handleUserDidPressForwardButton(_ sender: Any) {
        assetPlaybackManager.nextTrack()
    }
    
    // MARK: UI Update Method.
    
    /// This method handles updating the state of the `NSToolbarItem` objects associated with `WindowController` based on the state of `AssetPlaybackManager`.
    func updateToolbarItemState() {
        if assetPlaybackManager.asset == nil {
            backwardButton.isEnabled = false
            playPauseButton.isEnabled = false
            forwardButton.isEnabled = false
            
            playPauseButton.image = #imageLiteral(resourceName: "Play")
        }
        else {
            backwardButton.isEnabled = true
            playPauseButton.isEnabled = true
            forwardButton.isEnabled = true
            
            if assetPlaybackManager.player.rate == 0 {
                playPauseButton.image = #imageLiteral(resourceName: "Play")
            }
            else {
                playPauseButton.image = #imageLiteral(resourceName: "Pause")
            }
        }
    }

    
    // MARK: Key-Value Observing Method
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AssetPlaybackManager.percentProgress) {
            playbackProgressIndicator.doubleValue = Double(assetPlaybackManager.percentProgress)
        }
        else if keyPath == #keyPath(AssetPlaybackManager.duration) {
            guard let stringValue = dateComponentFormatter.string(from: TimeInterval(assetPlaybackManager.duration)) else { return }
            
            totalPlaybackDurationTextField.stringValue = stringValue
        }
        else if keyPath == #keyPath(AssetPlaybackManager.playbackPosition) {
            guard let stringValue = dateComponentFormatter.string(from: TimeInterval(assetPlaybackManager.playbackPosition)) else { return }
            
            currentPlaybackPositionTextField.stringValue = stringValue
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: Notification Observer Methods
    
    func handleCurrentAssetDidChangeNotification(notification: Notification) {
        if assetPlaybackManager.asset != nil {
            assetNameTextField.stringValue = assetPlaybackManager.asset.assetName
            
            guard let asset = assetPlaybackManager.asset else {
                return
            }
            
            let urlAsset = asset.urlAsset
            
            let artworkData = AVMetadataItem.metadataItems(from: urlAsset.commonMetadata, withKey: AVMetadataCommonKeyArtwork, keySpace: AVMetadataKeySpaceCommon).first?.value as? Data ?? Data()
            
            let image = NSImage(data: artworkData) ?? NSImage()
            
            assetCoverArtImageView.image = image
            
            for i in assets.startIndex..<assets.endIndex {
                if asset.assetName == assets[i].assetName {
                    assetListTableView.selectRowIndexes(IndexSet(integer: i), byExtendingSelection: false)
                    break
                }
            }
        }
        else {
            assetCoverArtImageView.image = nil
            assetNameTextField.stringValue = "Select Item Below to play"
            totalPlaybackDurationTextField.stringValue = "-:--"
            currentPlaybackPositionTextField.stringValue = "-:--"
            playbackProgressIndicator.doubleValue = 0.0
            assetListTableView.deselectAll(nil)
        }
        
        updateToolbarItemState()
    }
    
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
    
    func handlePlayerRateDidChangeNotification(notification: Notification) {
        updateToolbarItemState()
    }
}
