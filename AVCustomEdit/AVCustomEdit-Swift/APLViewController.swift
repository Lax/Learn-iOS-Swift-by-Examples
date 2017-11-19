/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 UIViewController subclasses which handles setup, playback and export of AVMutableComposition along with other user
  interactions like scrubbing, toggling play/pause, selecting transition type.
 */

import UIKit
import AVFoundation
import Foundation
import CoreFoundation
import CoreGraphics
import Photos

// MARK: APLPlayerView Class

// A simple `UIView` subclass that is backed by an `AVPlayerLayer` layer.
class APLPlayerView: UIView {
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        
        set {
            playerLayer.player = newValue
        }
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
}

class APLViewController: UIViewController, UIGestureRecognizerDelegate, UIPopoverPresentationControllerDelegate,
    APLTransitionTypePickerDelegate, UIAdaptivePresentationControllerDelegate, APLExportStatus {

    // MARK: Properties

    /// Context used in KVO to identify rate changes.
    fileprivate var playerRateObservationContext = 0
    /// Context used in KVO to identify player status changes.
    fileprivate var playerStatusObservationContext = 1

    /// Storyboard Seque identifier for the 'Set Transition'.
    static let transition = "Transition"

    /// APLSimpleEditor object instance used to build a composition from the clips.
    fileprivate var editor: APLSimpleEditor = APLSimpleEditor()

    /// The movie clips.
    fileprivate var clips = [AVAsset]()

    /// The available time ranges for the movie clips.
    fileprivate var clipTimeRanges = [CMTimeRange]()

    /// Instance of AVPlayer used for movie playback.
    fileprivate var player = AVPlayer()

    /// Instance of AVPlayerItem used to represent the presentation state of the asset played by the AVPlayer.
    fileprivate var playerItem: AVPlayerItem? = nil {
        didSet {
            // Replace the current player item with the new item.
            player.replaceCurrentItem(with: self.playerItem)
        }
    }

    /// The `UIView` subclass containing an AVPlayerLayer layer to which the output of AVPlayer can be directed.
    @IBOutlet fileprivate weak var playerView: APLPlayerView!
    /// The `UIToolbar` control that will display the scrubber, playPauseButton, and other elements.
    @IBOutlet fileprivate weak var toolbar: UIToolbar!
    /// The `UISlider` for scrubbing through the video.
    @IBOutlet fileprivate weak var scrubber: UISlider!
    /// The `UIBarButtonItem` for starting/stopping video playback.
    @IBOutlet fileprivate weak var playPauseButton: UIBarButtonItem!
    /// The `UIBarButtonItem` for selecting the desired transition (diagonal wipe or cross dissolve)
    @IBOutlet fileprivate weak var transitionButton: UIBarButtonItem!
    /// The `UIBarButtonItem` for exporting the video clips to a single file.
    @IBOutlet fileprivate weak var exportButton: UIBarButtonItem!
    /// The 'UILabel` for displaying the current time during playback.
    @IBOutlet fileprivate weak var currentTimeLabel: UILabel!
    /// The 'UIProgressView` for displaying the status of the export operation.
    @IBOutlet fileprivate weak var exportProgressView: UIProgressView!

    /// Indicates whether the movie is playing.
    fileprivate var playing = false

    /// Indicates whether the user is currently scrubbing video using the toolbar slider.
    fileprivate var scrubInFlight = false
    /// After the movie has played to its end time, seek back to time zero to play it again.
    fileprivate var seekToZeroBeforePlaying = false
    /// Last position of the scrubber slider.
    fileprivate var lastScrubSliderValue: Float = 0
    /// Player rate prior to stopping playback.
    fileprivate var playRateToRestore: Float = 0
    /// Used to update scrubber control and playback time value.
    fileprivate var timeObserver: Any?
    
    // Defaults for the transition settings.
    fileprivate var transitionDuration = 2.0
    fileprivate var transitionType = TransitionType.diagonalWipe.rawValue
    fileprivate var transitionsEnabled = true

    // MARK: Initialization

    required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
        player.addObserver(self, forKeyPath: "rate", options: [.new, .old],
                           context: &playerRateObservationContext)
    }

    // MARK: View Loading
    
    override func viewDidLoad() {

        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        
        playerView.player = self.player

        updateScrubber()
        updateTimeLabel()
        
        // Add the clips from the main bundle to create a composition using them.
        setupEditingAndPlayback()
    }

    override func viewDidAppear(_ animated: Bool) {

        super.viewDidAppear(animated)

        addTimeObserverToPlayer()
    }

    override func viewWillDisappear(_ animated: Bool) {

        super.viewWillDisappear(animated)
        
        player.pause()
        removeTimeObserverFromPlayer()
    }

    // MARK: Set Transition

    override func prepare(for segue: UIStoryboardSegue, sender:Any?) {
        
        if segue.identifier == APLViewController.transition {
            
            // Setup transition type picker controller before it is shown.
            guard let transitionTypePickerController = segue.destination as? APLTransitionTypeController else { return }
            guard let controller = transitionTypePickerController.popoverPresentationController else { return }
            /*
             This will cause the 'adaptivePresentationStyleForPresentationController' and
             'viewControllerForAdaptivePresentationStyle' functions to be called.
             */
            controller.delegate = self

            transitionTypePickerController.delegate = self
            transitionTypePickerController.currentTransition = transitionType
            if transitionType == TransitionType.crossDissolve.rawValue {
                // Make sure the view is loaded first.
                if transitionTypePickerController.crossDissolveCell == nil {
                    transitionTypePickerController.loadView()
                }
                transitionTypePickerController.crossDissolveCell.accessoryType = .checkmark
            } else {
                // Make sure the view is loaded first.
                if transitionTypePickerController.diagonalWipeCell == nil {
                    transitionTypePickerController.loadView()
                }
                transitionTypePickerController.diagonalWipeCell.accessoryType = .checkmark
            }
        }
    }

    // Specify the presentation style to use (called for iPhone only).
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .fullScreen
    }

    // Called when the Set Transition view controller 'Done' button is pressed.
    func doneAction() {
        // Dismiss the view controller that was presented.
        self.dismiss(animated: true) {}
    }

    /*
     Present/wrap the view controller in a navigation controller (for iPhone/compact).
     If this method is not implemented, or returns nil, then the originally presented view controller is used.
    */
    func presentationController(_ controller: UIPresentationController,
                                viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {

        let navController = UINavigationController(rootViewController: controller.presentedViewController)
        let presentedViewController = controller.presentedViewController
        presentedViewController.navigationItem.rightBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))

        return navController
    }

    // MARK: Editor

    func setupEditingAndPlayback() {

        guard let clip1Path = Bundle.main.path(forResource: "sample_clip1", ofType: "m4v") else {
            print("Failed to get clip1 from main bundle!"); return
        }
        let asset1 = AVURLAsset(url: URL(fileURLWithPath: clip1Path))
        
        guard let clip2Path = Bundle.main.path(forResource: "sample_clip2", ofType: "mov") else {
            print("Failed to get clip2 from main bundle!"); return
        }
        let asset2 = AVURLAsset(url: URL(fileURLWithPath: clip2Path))
        
        let dispatchGroup = DispatchGroup()
        let assetKeysToLoadAndTest: [String] = ["tracks", "duration", "composable"]

        loadAsset(asset1, withKeys:assetKeysToLoadAndTest, usingDispatchGroup:dispatchGroup)
        loadAsset(asset2, withKeys:assetKeysToLoadAndTest, usingDispatchGroup:dispatchGroup)

        dispatchGroup.notify(queue: DispatchQueue.main, execute: {
            // Wait until all the above clips have loaded before synchronizing with the editor.
            if self.clips.count > 1 {
                self.synchronizeWithEditor()
            }
        })
    }
    
    func loadAsset(_ asset: AVAsset, withKeys assetKeysToLoad: [String],
                   usingDispatchGroup dispatchGroup: DispatchGroup) {
        
        dispatchGroup.enter()
        asset.loadValuesAsynchronously(forKeys: assetKeysToLoad, completionHandler: {
            // First test whether the values of each of the keys we need have been successfully loaded.
            for item in assetKeysToLoad {
                var error: NSError?
                if asset.statusOfValue(forKey: item, error: &error) == AVKeyValueStatus.failed {
                    print("Key value loading failed for key:\(item) with error:\(error!)")
                    dispatchGroup.leave()
                    return
                }
            }
            if asset.isComposable == false {
                print("Asset is not composable.")
                dispatchGroup.leave()
                return
            }
            
            self.clips.append(asset)
            // This code assumes that both assets are atleast 5 seconds long.
            self.clipTimeRanges.append(CMTimeRange(start: CMTimeMakeWithSeconds(0, 1),
                                                   duration: CMTimeMakeWithSeconds(5, 1)))
            dispatchGroup.leave()
        })
    }

    func synchronizePlayerWithEditor() {
        
        guard let playerItem = editor.playerItem() else {
            print("APLSimpleEditor has no playerItem.")
            return
        }
        
        if self.playerItem != playerItem {

            if let currentPlayerItem = self.playerItem {
                currentPlayerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: currentPlayerItem)
            }
            
            self.playerItem = playerItem

            self.playerItem!.seekingWaitsForVideoCompositionRendering = true

            // Observe the player item "status" key to determine when it is ready to play.
            self.playerItem!.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status),
                                         options: [.new],
                                         context: &playerStatusObservationContext)
            
            /*
             When the player item has played to its end time we'll set a flag
             so that the next time the play method is issued the player will
             be reset to time zero first.
             */
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(_:)),
                name: .AVPlayerItemDidPlayToEndTime, object: self.playerItem)
            self.player.replaceCurrentItem(with: playerItem)
        }
    }
    
    func synchronizeWithEditor() {
        
        // Clips.
        synchronizeEditorClipsWithOurClips()
        synchronizeEditorClipTimeRangesWithOurClipTimeRanges()
        
        // Transitions.
        if transitionsEnabled {
            self.editor.transitionDuration = CMTimeMakeWithSeconds(transitionDuration, 600)
            self.editor.transitionType = transitionType
        } else {
            self.editor.transitionDuration = kCMTimeInvalid
        }
        
        // Build AVComposition and AVVideoComposition objects for playback.
        self.editor.buildCompositionObjectsForPlayback(true, overwriteExistingObjects: true)
        
        synchronizePlayerWithEditor()
    }
    
    func synchronizeEditorClipsWithOurClips() {

        var validClips = [AVAsset]()
        for item in self.clips {
            validClips.append(item)
        }
        guard let clips = validClips as? [AVURLAsset] else { return }
        editor.clips = clips
    }

    func synchronizeEditorClipTimeRangesWithOurClipTimeRanges() {

        var validClipTimeRanges = [CMTimeRange]()
        for item in self.clipTimeRanges {
            validClipTimeRanges.append(item)
        }
        self.editor.clipTimeRanges = validClipTimeRanges
    }

    // MARK: Utilities
    
    // Update the scrubber and time label periodically.

    func addTimeObserverToPlayer() {
        
        guard let currentPlayerItem = self.player.currentItem else { return }
        
        if currentPlayerItem.status != .readyToPlay { return }
        
        let duration: Double = CMTimeGetSeconds(playerItemDuration())
        
        if __inline_isfinited(duration) != 0 {
            
            let width = (Double(scrubber.bounds.width))
            var interval = 0.5 * duration.divided(by: width)
            
            // The time label needs to update at least once per second.
            if interval > 1.0 {
                interval = 1.0
            }

            let updateTime = CMTimeMakeWithSeconds(interval, Int32(NSEC_PER_SEC))
            timeObserver =
                self.player.addPeriodicTimeObserver(forInterval: updateTime, queue: DispatchQueue.main,
                                                    using: { [unowned self] _ in
                self.updateScrubber()
                self.updateTimeLabel()
            })
        }
    }
    
    func removeTimeObserverFromPlayer() {
        
        guard let timeObserver = self.timeObserver else { return }
        
        player.removeTimeObserver(timeObserver)
        self.timeObserver = nil
    }

    func playerItemDuration() -> CMTime {
        
        var itemDuration = kCMTimeInvalid
        
        guard let playerItem = self.player.currentItem else { return itemDuration }
        
        if playerItem.status == AVPlayerItemStatus.readyToPlay {
            itemDuration = playerItem.duration
        }
        
        return itemDuration
    }

    // MARK: - KVO Observation
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {

        // Make sure the this KVO callback was intended for this view controller.
        if context == &playerRateObservationContext {

            guard let newRate = change?[.newKey] as? Float,
                let oldRate = change?[.oldKey] as? Float else { return }
            if newRate != oldRate {
                playing = (newRate != 0) || (playRateToRestore != 0)

                updatePlayPauseButton()
                updateScrubber()
                updateTimeLabel()
            }
        } else if context == &playerStatusObservationContext {
            guard let playerItem = object as? AVPlayerItem else { return }
            if playerItem.status == .readyToPlay {
                /*
                 Once the AVPlayerItem becomes ready to play, i.e.
                 playerItem.status == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item.
                 */
                addTimeObserverToPlayer()
            } else if playerItem.status == .failed {
                if let error = playerItem.error {
                    reportError(error)
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    func updatePlayPauseButton() {

        let style = playing ?  UIBarButtonSystemItem.pause : UIBarButtonSystemItem.play
        let newPlayPauseButton = UIBarButtonItem(barButtonSystemItem: style, target: self,
                                                 action: #selector(togglePlayPause(_:)))
        
        guard var items = self.toolbar?.items else {
            return
        }
        
        if let indexOfFirstSuchElement = items.index(where: { $0 == playPauseButton }) {
            items[indexOfFirstSuchElement] = newPlayPauseButton
            playPauseButton = newPlayPauseButton
        }

        self.toolbar.setItems(items, animated: false)
}

    func updateTimeLabel() {

        var seconds = CMTimeGetSeconds(player.currentTime())
        if __inline_isfinited(seconds) <= 0 {
            seconds = 0
        }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad

        guard let formattedString = formatter.string(from: TimeInterval(seconds)) else { return }
        currentTimeLabel.text = formattedString
    }
    
    func updateScrubber() {
        
        let duration = CMTimeGetSeconds(playerItemDuration())
        if __inline_isfinited(duration) != 0 {
            let time = CMTimeGetSeconds(player.currentTime())
            scrubber.setValue(Float(time.divided(by: duration)), animated: true)
        } else {
            scrubber.setValue(0, animated: true)
        }
    }

    func updateProgress(_ timer: Timer) {

        guard let session = timer.userInfo as? AVAssetExportSession else { return }
        if session.status == AVAssetExportSessionStatus.exporting {
            exportProgressView?.progress = session.progress
        }
    }

    func reportError(_ error: Error) {

        DispatchQueue.main.async {
            let alertController = UIAlertController(title: error.localizedDescription,
                                                    message: error.localizedDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                    style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }

    // MARK: Playback

    @IBAction func togglePlayPause(_ sender: AnyObject) {

        playing = !playing
        if playing {
            if seekToZeroBeforePlaying {
                player.seek(to: kCMTimeZero)
                seekToZeroBeforePlaying = false
                updateScrubber()
            }
            player.play()
        } else {
            player.pause()
        }
    }
    
    @IBAction func beginScrubbing(_ sender: AnyObject) {

        seekToZeroBeforePlaying = false
        playRateToRestore = player.rate
        player.rate = 0
        
        removeTimeObserverFromPlayer()
    }
    
    @IBAction func scrub(_ sender: AnyObject) {
        
        lastScrubSliderValue = scrubber.value
        
        if !scrubInFlight {
            scrubToSliderValue(lastScrubSliderValue)
        }
    }
    
    func scrubToSliderValue(_ sliderValue: Float) {
        
        let duration: Float64 = CMTimeGetSeconds(playerItemDuration())
        
        if __inline_isfinited(duration) > 0 {
            
            guard let scrubber = self.scrubber else {
                return
            }
            let width = scrubber.bounds.width
            
            let time = duration.multiplied(by: Float64(sliderValue))
            let tolerance = 1 * duration.divided(by: Float64(width))
            
            scrubInFlight = true
            
            player.seek(to: CMTimeMakeWithSeconds(time, Int32(NSEC_PER_SEC)),
                        toleranceBefore: CMTimeMakeWithSeconds(tolerance, Int32(NSEC_PER_SEC)),
                        toleranceAfter: CMTimeMakeWithSeconds(tolerance, Int32(NSEC_PER_SEC)),
                        completionHandler: { (_) in
                            self.scrubInFlight = false
                            self.updateTimeLabel()
            })
        }
    }
    
    @IBAction func endScrubbing(_ sender: AnyObject) {

        if scrubInFlight {
            scrubToSliderValue(lastScrubSliderValue)
        }
        addTimeObserverToPlayer()
        
        player.rate = playRateToRestore
        playRateToRestore = 0
    }
    
    // Called when the player item has played to its end time.
    func playerItemDidReachEnd(_ notification: Notification) {

        // After the movie has played to its end time, seek back to time zero to play it again.
        seekToZeroBeforePlaying = true
    }
    
    @IBAction func handleTapGesture(_ tapGestureRecognizer: UITapGestureRecognizer) {

        toolbar.isHidden = !toolbar.isHidden
        currentTimeLabel.isHidden = !currentTimeLabel.isHidden
    }

    // MARK: Export

    @IBAction func exportToMovie(_ sender: AnyObject) {
        
        exportProgressView.isHidden = false
        
        player.pause()
        playPauseButton.isEnabled = false
        transitionButton.isEnabled = false
        scrubber.isEnabled = false
        exportButton.isEnabled = false
        
        editor.buildCompositionObjectsForPlayback(false, overwriteExistingObjects: false)
        
        // Get the assets to be used in the export operation.
        guard let theComposition = editor.composition, let theVideoComposition = editor.videoComposition else { return }

        // Use the APLExport object to perform the actual transcode of the assets.
        guard let exporter = APLExport(theComposition, videoComposition: theVideoComposition,
                                       presetName: AVAssetExportPresetMediumQuality, controller: self) else { return }

        // Transcode the assets.
        exporter.export()
    }

    func exportCompleted() {

        exportProgressView.isHidden = true
        currentTimeLabel.isHidden = false

        // Reset progress bar now that export has completed.
        exportProgressView.progress = 1
                
        player.play()
        playPauseButton.isEnabled = true
        transitionButton.isEnabled = true
        scrubber.isEnabled = true
        exportButton.isEnabled = true
    }

    // MARK: Transitions

    @IBAction func selectTransition(_ sender: AnyObject) {
        // Show the view controller as a popover (iPad) or as a modal view controller (iPhone / iPhone Plus).
        guard let contentVC =
            self.storyboard?.instantiateViewController(withIdentifier: "SetTransition") else { return }

        contentVC.edgesForExtendedLayout = UIRectEdge.all
        contentVC.modalPresentationStyle = UIModalPresentationStyle.popover
        guard let presentationController = contentVC.popoverPresentationController else { return }

        // Display popover from the UIButton (sender) as the anchor.
        presentationController.sourceRect = sender.frame
        guard let button = sender as? UIButton else { return }
        presentationController.sourceView = button.superview

        presentationController.permittedArrowDirections = .any

        /*
         Present content view controller in a compact screen so that it can be dismissed as a full screen
         view controller.
        */
        presentationController.delegate = self

        // Present the view controller modally.
        self.present(contentVC, animated: false) {
            // Done.
        }
    }

    // MARK: Gesture recognizer delegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        guard let touchView = touch.view else { return false }
        // Ignore touch on toolbar.
        if touchView != playerView { return false }
        
        return true
    }
    
    // MARK: APLTransitionTypePickerDelegate
    func transitionTypeController(_ controller: APLTransitionTypeController, transitionType: Int) {
        
        self.transitionType = transitionType
        
        // Let the editor know of the change in transition type.
        synchronizeWithEditor()
    }

    func transitionTypeControllerDismiss() {

        self.dismiss(animated: true, completion: nil)
    }
}

