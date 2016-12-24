/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	View controller containing a player view, collection view showing the AVQueuePlayer content and basic playback controls.
*/

import UIKit
import AVFoundation

/*
    KVO context used to differentiate KVO callbacks for this class versus other
    classes in its class hierarchy.
*/
private var playerViewControllerKVOContext = 0

class PlayerViewController: UIViewController, UICollectionViewDataSource {
    // MARK: Properties
    
    // Attempt load and test these asset keys before playing.
    static let assetKeysRequiredToPlay = [
        "playable",
        "hasProtectedContent"
    ]

    let player = AVQueuePlayer()

    var currentTime: Double {
        get {
            return CMTimeGetSeconds(player.currentTime())
        }
        
        set {
            let newTime = CMTimeMakeWithSeconds(newValue, 1)
            player.seek(to: newTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        }
    }
    
    var duration: Double {
        guard let currentItem = player.currentItem else { return 0.0 }
        
        return CMTimeGetSeconds(currentItem.duration)
    }
    
    var rate: Float {
        get {
            return player.rate
        }
        
        set {
            player.rate = newValue
        }
    }
    
    var playerLayer: AVPlayerLayer? {
        return playerView.playerLayer
    }
    
    /*
        A formatter for individual date components used to provide an appropriate
        value for the `startTimeLabel` and `durationLabel`.
    */
    let timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        
        return formatter
    }()
    
    /*
        A token obtained from calling `player`'s `addPeriodicTimeObserverForInterval(_:queue:usingBlock:)`
        method.
    */
    var timeObserverToken: Any?
    
    var assetTitlesAndThumbnails: [URL: (title: String, thumbnail: UIImage)] = [:]
    
    var loadedAssets = [String: AVURLAsset]()
    
    // MARK: IBOutlets
    
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var fastForwardButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var queueLabel: UILabel!
    @IBOutlet weak var playerView: PlayerView!

    // MARK: View Controller
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

        /*
            Update the UI when these player properties change.
        
            Use the context parameter to distinguish KVO for our particular observers 
            and not those destined for a subclass that also happens to be observing
            these properties.
        */
		addObserver(self, forKeyPath: #keyPath(PlayerViewController.player.currentItem.duration), options: [.new, .initial], context: &playerViewControllerKVOContext)
		addObserver(self, forKeyPath: #keyPath(PlayerViewController.player.rate), options: [.new, .initial], context: &playerViewControllerKVOContext)
		addObserver(self, forKeyPath: #keyPath(PlayerViewController.player.currentItem.status), options: [.new, .initial], context: &playerViewControllerKVOContext)
		addObserver(self, forKeyPath: #keyPath(PlayerViewController.player.currentItem), options: [.new, .initial], context: &playerViewControllerKVOContext)

        playerView.playerLayer.player = player

        /*
            Read the list of assets we'll be using from a JSON file.
        */
        let manifestURL = Bundle.main.url(forResource: "MediaManifest", withExtension: "json")!
        asynchronouslyLoadURLAssetsWithManifestURL(jsonURL: manifestURL)
        
        // Make sure we don't have a strong reference cycle by only capturing self as weak.
        let interval = CMTimeMake(1, 1)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [unowned self] time in
            let timeElapsed = Float(CMTimeGetSeconds(time))
            
            self.timeSlider.value = Float(timeElapsed)
            self.startTimeLabel.text = self.createTimeString(time: timeElapsed)
        }
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }

		player.pause()

		removeObserver(self, forKeyPath: #keyPath(PlayerViewController.player.currentItem.duration), context: &playerViewControllerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(PlayerViewController.player.rate), context: &playerViewControllerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(PlayerViewController.player.currentItem.status), context: &playerViewControllerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(PlayerViewController.player.currentItem), context: &playerViewControllerKVOContext)
	}
    
    // MARK: Asset Loading
    
    /*
        Prepare an AVAsset for use on a background thread. When the minimum set 
        of properties we require (`assetKeysRequiredToPlay`) are loaded then add
        the asset to the `assetTitlesAndThumbnails` dictionary. We'll use that 
        dictionary to populate the "Add Item" button popover.
    */
    func asynchronouslyLoadURLAsset(asset: AVURLAsset, title: String, thumbnailResourceName: String) {
        /*
            Using AVAsset now runs the risk of blocking the current thread (the
            main UI thread) whilst I/O happens to populate the properties. It's 
            prudent to defer our work until the properties we need have been loaded.
        */
        asset.loadValuesAsynchronously(forKeys: PlayerViewController.assetKeysRequiredToPlay) {

            /*
                The asset invokes its completion handler on an arbitrary queue.
                To avoid multiple threads using our internal state at the same time
                we'll elect to use the main thread at all times, let's dispatch
                our handler to the main queue.
            */
            DispatchQueue.main.async() {
                /*
                    This method is called when the `AVAsset` for our URL has 
                    completed the loading of the values of the specified array 
                    of keys.
                */
                
                /*
                    Test whether the values of each of the keys we need have been
                    successfully loaded.
                */
                for key in PlayerViewController.assetKeysRequiredToPlay {
                    var error: NSError?

					if asset.statusOfValue(forKey: key, error: &error) == .failed {
                        let stringFormat = NSLocalizedString("error.asset_%@_key_%@_failed.description", comment: "Can't use this AVAsset because one of it's keys failed to load")

                        let message = String.localizedStringWithFormat(stringFormat, title, key)

                        self.handleError(with: message, error: error)

                        return
                    }
                }

                // We can't play this asset.
                if !asset.isPlayable || asset.hasProtectedContent {
                    let stringFormat = NSLocalizedString("error.asset_%@_not_playable.description", comment: "Can't use this AVAsset because it isn't playable or has protected content")
                    
                    let message = String.localizedStringWithFormat(stringFormat, title)

                    self.handleError(with: message)

                    return
                }

                /*
                    We can play this asset. Create a new AVPlayerItem and make it
                    our player's current item.
                */
                self.loadedAssets[title] = asset

                let name = (thumbnailResourceName as NSString).deletingPathExtension
                let type = (thumbnailResourceName as NSString).pathExtension
                let path = Bundle.main.path(forResource: name, ofType: type)!

                let thumbnail = UIImage(contentsOfFile: path)!
                
                self.assetTitlesAndThumbnails[asset.url] = (title, thumbnail)
            }
        }
    }

    /*
        Read the asset URLs, titles and thumbnail resource names from a JSON manifest
        file - then load each asset.
    */
    func asynchronouslyLoadURLAssetsWithManifestURL(jsonURL: URL!) {
        var assetsJSON = [[String: AnyObject]]()

        if let jsonData = NSData(contentsOf: jsonURL as URL) {
            do {
				try assetsJSON = JSONSerialization.jsonObject(with: jsonData as Data, options: []) as! [[String: AnyObject]]
            }
            catch {
                let message = NSLocalizedString("error.json_parse_failed.description", comment: "Failed to parse the assets manifest JSON")

                handleError(with: message)
            }
        }
        else {
            let message = NSLocalizedString("error.json_open_failed.description", comment: "Failed to open the assets manifest JSON")
            
            handleError(with: message)
        }
    
        for assetJSON in assetsJSON {
            let mediaURL: URL

            if let resourceName = assetJSON["mediaResourceName"] as! String? {
                let name = (resourceName as NSString).deletingPathExtension
                let type = (resourceName as NSString).pathExtension
                mediaURL = Bundle.main.url(forResource: name, withExtension: type)!
            }
            else {
                let URLString = assetJSON["mediaURL"] as! String
                mediaURL = URL(string: URLString)!
            }
            
            let title = assetJSON["title"] as! String
            let thumbnailResourceName = assetJSON["thumbnailResourceName"] as! String

            let asset = AVURLAsset(url: mediaURL as URL, options: [:])
            asynchronouslyLoadURLAsset(asset: asset, title: title, thumbnailResourceName: thumbnailResourceName)
        }
    }

    // MARK: - IBActions

	@IBAction func playPauseButtonWasPressed(_ sender: UIButton) {
		if player.rate != 1.0 {
            // Not playing forward, so play.
			if currentTime == duration {
                // At end, so go back to beginning.
				currentTime = 0.0
			}

            player.play()
		}
        else {
            // Playing, so pause.
			player.pause()
		}
	}
	
	@IBAction func rewindButtonWasPressed(_ sender: UIButton) {
        // Rewind no faster than -2.0.
        rate = max(player.rate - 2.0, -2.0)
	}
	
	@IBAction func fastForwardButtonWasPressed(_ sender: UIButton) {
        // Fast forward no faster than 2.0.
        rate = min(player.rate + 2.0, 2.0)
	}
    
    @IBAction func timeSliderDidChange(_ sender: UISlider) {
        currentTime = Double(sender.value)
    }

    private func presentModalPopoverAlertController(alertController: UIAlertController, sender: UIButton) {
        alertController.modalPresentationStyle = .popover

        alertController.popoverPresentationController?.sourceView = sender
        alertController.popoverPresentationController?.sourceRect = sender.bounds
        alertController.popoverPresentationController?.permittedArrowDirections = .any

        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func addItemToQueueButtonPressed(_ sender: UIButton) {
        let alertTitle = NSLocalizedString("popover.title.addItem", comment: "Title of popover that adds items to the queue")
        
        let alertMessage = NSLocalizedString("popover.message.addItem", comment: "Message on popover that adds items to the queue")

        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .actionSheet)
        
        // Populate the sheet with the titles of the assets we have loaded.
        for (loadedAssetTitle, loadedAsset) in loadedAssets {
            let alertAction = UIAlertAction(title:loadedAssetTitle, style: .default) { [unowned self] alertAction in
                let oldItems = self.player.items()
                
                let newPlayerItem = AVPlayerItem(asset: loadedAsset)
                
                self.player.insert(newPlayerItem, after: nil)

                self.queueDidChangeWithOldPlayerItems(oldPlayerItems: oldItems, newPlayerItems: self.player.items())
            }

            alertController.addAction(alertAction)
        }

        let cancelActionTitle = NSLocalizedString("popover.title.cancel", comment: "Title of popover cancel action")

        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .cancel, handler: nil)
        
        alertController.addAction(cancelAction)

        presentModalPopoverAlertController(alertController: alertController, sender: sender)
    }

    @IBAction func clearQueueButtonWasPressed(_ sender: UIButton) {
        let alertTitle = NSLocalizedString("popover.title.clear", comment: "Title of popover that clears the queue")

        let alertMessage = NSLocalizedString("popover.message.clear", comment: "Message on popover that clears the queue")
        
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .actionSheet)

        let clearButtonTitle = NSLocalizedString("button.title.clear", comment: "Title on button to clear the queue")

        let clearQueueAction = UIAlertAction(title: clearButtonTitle, style: .destructive) { [unowned self] alertAction in
            let oldItems = self.player.items()

            self.player.removeAllItems()
            
            self.queueDidChangeWithOldPlayerItems(oldPlayerItems: oldItems, newPlayerItems: self.player.items())
        }
        
        alertController.addAction(clearQueueAction)
        
        let cancelActionTitle = NSLocalizedString("popover.title.cancel", comment: "Title of popover cancel action")

        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .cancel, handler: nil)
        
        alertController.addAction(cancelAction)

        presentModalPopoverAlertController(alertController: alertController, sender: sender)
    }
    
    // MARK: KVO Observation

    // Update our UI when player or `player.currentItem` changes.
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // Make sure the this KVO callback was intended for this view controller.
        guard context == &playerViewControllerKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        if keyPath == #keyPath(PlayerViewController.player.currentItem) {
            queueDidChangeWithOldPlayerItems(oldPlayerItems: [], newPlayerItems: player.items())
        }
        else if keyPath == #keyPath(PlayerViewController.player.currentItem.duration) {
            // Update `timeSlider` and enable / disable controls when `duration` > 0.0.

            /*
                Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when 
                `player.currentItem` is nil.
            */
            let newDuration: CMTime
            if let newDurationAsValue = change?[NSKeyValueChangeKey.newKey] as? NSValue {
                newDuration = newDurationAsValue.timeValue
            }
            else {
                newDuration = kCMTimeZero
            }

            let hasValidDuration = newDuration.isNumeric && newDuration.value != 0
            let newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0
            let currentTime = hasValidDuration ? Float(CMTimeGetSeconds(player.currentTime())) : 0.0
            
            timeSlider.maximumValue = Float(newDurationSeconds)

            timeSlider.value = currentTime
            
            rewindButton.isEnabled = hasValidDuration
            
            playPauseButton.isEnabled = hasValidDuration
            
            fastForwardButton.isEnabled = hasValidDuration
            
            timeSlider.isEnabled = hasValidDuration
            
            startTimeLabel.isEnabled = hasValidDuration
            startTimeLabel.text = createTimeString(time: currentTime)
            
            durationLabel.isEnabled = hasValidDuration
            durationLabel.text = createTimeString(time: Float(newDurationSeconds))
        }
        else if keyPath == #keyPath(PlayerViewController.player.rate) {
            // Update `playPauseButton` image.

            let newRate = (change?[NSKeyValueChangeKey.newKey] as! NSNumber).doubleValue
            
            let buttonImageName = newRate == 1.0 ? "PauseButton" : "PlayButton"
            
            let buttonImage = UIImage(named: buttonImageName)

            playPauseButton.setImage(buttonImage, for: .normal)
        }
        else if keyPath ==  #keyPath(PlayerViewController.player.currentItem.status) {
            // Display an error if status becomes `.Failed`.

            /*
                Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when
                `player.currentItem` is nil.
            */
            let newStatus: AVPlayerItemStatus

            if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                newStatus = AVPlayerItemStatus(rawValue: newStatusAsNumber.intValue)!
            }
            else {
                newStatus = .unknown
            }
            
            if newStatus == .failed {
                handleError(with: player.currentItem?.error?.localizedDescription, error: player.currentItem?.error)
            }
        }
	}

    /*
        Trigger KVO for anyone observing our properties affected by `player` and
        `player.currentItem`.
    */
    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        let affectedKeyPathsMappingByKey: [String: Set<String>] = [
            "duration":     [#keyPath(PlayerViewController.player.currentItem.duration)],
            "rate":         [#keyPath(PlayerViewController.player.rate)]
        ]
        
        return affectedKeyPathsMappingByKey[key] ?? super.keyPathsForValuesAffectingValue(forKey: key)
	}    
    
    /*
        `player.items` is not KVO observable so we need to call this function
        every time the queue changes.
    */
    private func queueDidChangeWithOldPlayerItems(oldPlayerItems: [AVPlayerItem], newPlayerItems: [AVPlayerItem]) {
        if newPlayerItems.isEmpty {
            queueLabel.text = NSLocalizedString("label.queue.empty", comment: "Queue is empty")
        }
        else {
            let stringFormat = NSLocalizedString("label.queue.%lu items", comment: "Queue of n item(s)")
            
            queueLabel.text = String.localizedStringWithFormat(stringFormat, newPlayerItems.count)
        }

        let isQueueEmpty = newPlayerItems.count == 0
        clearButton.isEnabled = !isQueueEmpty
    
        collectionView.reloadData()
    }

    // MARK: Error Handling

	func handleError(with message: String?, error: Error? = nil) {
        NSLog("Error occurred with message: \(message), error: \(error).")
    
        let alertTitle = NSLocalizedString("alert.error.title", comment: "Alert title for errors")
        
        let alertMessage = message ?? NSLocalizedString("error.default.description", comment: "Default error message when no NSError provided")

        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)

        let alertActionTitle = NSLocalizedString("alert.error.actions.OK", comment: "OK on error alert")
        let alertAction = UIAlertAction(title: alertActionTitle, style: .default, handler: nil)

        alert.addAction(alertAction)

        present(alert, animated: true, completion: nil)
	}


    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return player.items().count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath as IndexPath) as! QueuedItemCollectionViewCell
        
        let item = player.items()[indexPath.row]
        
        let urlAsset = item.asset as! AVURLAsset

        let titleAndThumbnail = assetTitlesAndThumbnails[urlAsset.url]!
        
        cell.label.text = titleAndThumbnail.title
        
        cell.backgroundView = UIImageView(image: titleAndThumbnail.thumbnail)
        
        return cell
    }
    
    // MARK: Convenience
    
    func createTimeString(time: Float) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))
        
        return timeRemainingFormatter.string(from: components as DateComponents)!
    }
}
