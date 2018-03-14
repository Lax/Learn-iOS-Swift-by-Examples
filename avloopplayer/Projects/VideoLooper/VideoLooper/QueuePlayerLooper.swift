/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	An object that uses AVQueuePlayer to loop a video.
*/

import AVFoundation

class QueuePlayerLooper : NSObject, Looper {
    // MARK: Types

    private struct ObserverContexts {
        static var playerStatus = 0
        
        static var playerStatusKey = "status"
        
        static var currentItem = 0
        
        static var currentItemKey = "currentItem"

        static var currentItemStatus = 0
        
        static var currentItemStatusKey = "currentItem.status"
        
        static var urlAssetDurationKey = "duration"
        
        static var urlAssetPlayableKey = "playable"
    }

    // MARK: Properties

    private var player: AVQueuePlayer?

    private var playerLayer: AVPlayerLayer?

    private var isObserving = false

    private var numberOfTimesPlayed = 0

    private let numberOfTimesToPlay: Int

    private let videoURL: URL

    // MARK: Looper

    required init(videoURL: URL, loopCount: Int) {
        self.videoURL = videoURL
        self.numberOfTimesToPlay = loopCount

        super.init()
    }

    func start(in parentLayer: CALayer) {
        stop()

        player = AVQueuePlayer()
        playerLayer = AVPlayerLayer(player: player)

        guard let playerLayer = playerLayer else { fatalError("Error creating player layer") }
        playerLayer.frame = parentLayer.bounds
        parentLayer.addSublayer(playerLayer)

        let videoAsset = AVURLAsset(url: videoURL)

        videoAsset.loadValuesAsynchronously(forKeys: [ObserverContexts.urlAssetDurationKey, ObserverContexts.urlAssetPlayableKey]) {
            /*
                The asset invokes its completion handler on an arbitrary queue
                when loading is complete. Because we want to access our AVQueuePlayer
                in our ensuing set-up, we must dispatch our handler to the main
                queue.
            */
            DispatchQueue.main.async(execute: {
                var durationError: NSError?
                let durationStatus = videoAsset.statusOfValue(forKey: ObserverContexts.urlAssetDurationKey, error: &durationError)
                guard durationStatus == .loaded else { fatalError("Failed to load duration property with error: \(durationError)") }

                var playableError: NSError?
                let playableStatus = videoAsset.statusOfValue(forKey: ObserverContexts.urlAssetPlayableKey, error: &playableError)
                guard playableStatus == .loaded else { fatalError("Failed to read playable duration property with error: \(playableError)") }

                guard videoAsset.isPlayable else {
                    print("Can't loop since asset is not playable")
                    return
                }

                guard CMTimeCompare(videoAsset.duration, CMTime(value:1, timescale:100)) >= 0 else {
                    print("Can't loop since asset duration too short. Duration is(\(CMTimeGetSeconds(videoAsset.duration)) seconds")
                    return
                }

                /*
                 Based on the duration of the asset, we decide the number of player 
                 items to add to demonstrate gapless playback of the same asset.
                 */
                let numberOfPlayerItems = (Int)(1.0 / CMTimeGetSeconds(videoAsset.duration)) + 2

                for _ in 1...numberOfPlayerItems {
                    let loopItem = AVPlayerItem(asset: videoAsset)
                    self.player?.insert(loopItem, after: nil)
                }

                self.startObserving()
                self.numberOfTimesPlayed = 0
                self.player?.play()
            })
        }
    }

    func stop() {
        player?.pause()
        stopObserving()

        player?.removeAllItems()
        player = nil

        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }

    // MARK: Convenience

    private func startObserving() {
        guard let player = player, !isObserving else { return }

        player.addObserver(self, forKeyPath: ObserverContexts.playerStatusKey, options: .new, context: &ObserverContexts.playerStatus)
        player.addObserver(self, forKeyPath: ObserverContexts.currentItemKey, options: .old, context: &ObserverContexts.currentItem)
        player.addObserver(self, forKeyPath: ObserverContexts.currentItemStatusKey, options: .new, context: &ObserverContexts.currentItemStatus)

        isObserving = true
    }

    private func stopObserving() {
        guard let player = player, isObserving else { return }

        player.removeObserver(self, forKeyPath: ObserverContexts.playerStatusKey, context: &ObserverContexts.playerStatus)
        player.removeObserver(self, forKeyPath: ObserverContexts.currentItemKey, context: &ObserverContexts.currentItem)
        player.removeObserver(self, forKeyPath: ObserverContexts.currentItemStatusKey, context: &ObserverContexts.currentItemStatus)

        isObserving = false
    }

    // MARK: KVO

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &ObserverContexts.playerStatus {
            guard let newPlayerStatus = change?[.newKey] as? AVPlayerStatus else { return }

            if newPlayerStatus == AVPlayerStatus.failed {
                print("End looping since player has failed with error: \(player?.error)")
                stop()
            }
        }
        else if context == &ObserverContexts.currentItem {
            guard let player = player else { return }

            if player.items().isEmpty {
                print("Play queue emptied out due to bad player item. End looping")
                stop()
            }
            else {
                // If `loopCount` has been set, check if looping needs to stop.
                if numberOfTimesToPlay > 0 {
                    numberOfTimesPlayed = numberOfTimesPlayed + 1

                    if numberOfTimesPlayed >= numberOfTimesToPlay {
                        print("Looped \(numberOfTimesToPlay) times. Stopping.");
                        stop()
                    }
                }

                /*
                    Append the previous current item to the player's queue. An initial
                    change from a nil currentItem yields NSNull here. Check to make
                    sure the class is AVPlayerItem before appending it to the end
                    of the queue.
                */
                if let itemRemoved = change?[.oldKey] as? AVPlayerItem {
                    itemRemoved.seek(to: kCMTimeZero)

                    stopObserving()
                    player.insert(itemRemoved, after: nil)
                    startObserving()
                }
            }
        }
        else if context == &ObserverContexts.currentItemStatus {
            guard let newPlayerItemStatus = change?[.newKey] as? AVPlayerItemStatus else { return }

            if newPlayerItemStatus == .failed {
                print("End looping since player item has failed with error: \(player?.currentItem?.error)")
                stop()
            }
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
