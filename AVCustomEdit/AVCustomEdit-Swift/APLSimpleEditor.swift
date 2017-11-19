/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Simple editor sets up an AVMutableComposition using supplied clips and time ranges. It also sets up an
  AVVideoComposition to perform custom compositor rendering.
 */

import Foundation
import CoreMedia
import AVFoundation

class APLSimpleEditor: NSObject, AVVideoCompositionValidationHandling {

    /// The movie clips in the composition.
    var clips = [AVURLAsset]()
    /// The movie clip time ranges.
    var clipTimeRanges = [CMTimeRange]()

    /// The currently selected transition.
    var transitionType = TransitionType.diagonalWipe.rawValue
    /// The duration of the transition.
    var transitionDuration: CMTime?

    /// The composition into which the tracks from the different media assets will added.
    var composition: AVMutableComposition?
    /// A video composition that describes the number and IDs of video tracks that are to be used in order to produce a composed video frame.
    var videoComposition: AVMutableVideoComposition?

    /// The time range in which the clips should pass through.
    private lazy var passThroughTimeRanges: [CMTimeRange] = self.initTimeRanges()
    /// The transition time range for the clips.
    private lazy var transitionTimeRanges: [CMTimeRange] = self.initTimeRanges()

    func initTimeRanges() -> [CMTimeRange] {
        let time = CMTimeMake(0, 0)
        return Array(repeating: CMTimeRangeMake(time, time), count: clips.count)
    }

    func buildComposition(compositionVideoTracks: inout [AVMutableCompositionTrack],
                          _ compositionAudioTracks: inout [AVMutableCompositionTrack]) {
        var alternatingIndex = 0
        var nextClipStartTime = kCMTimeZero

        // Make transitionDuration no greater than half the shortest clip duration.
        guard var transitionDuration = self.transitionDuration else {
            return
        }
        
        // Make transitionDuration no greater than half the shortest clip duration.
        for clipTimeRange in clipTimeRanges {
            
            var halfClipDuration = clipTimeRange.duration
            // You can halve a rational by doubling its denominator.
            halfClipDuration.timescale *= 2
            transitionDuration = CMTimeMinimum(transitionDuration, halfClipDuration)
        }

        let clipsCount = clips.count
        for i in 0..<clipsCount {
            
            alternatingIndex = i % 2 // Alternating targets: 0, 1, 0, 1, ...
            let asset = clips[i]
            var timeRangeInAsset: CMTimeRange
            if i < clipTimeRanges.count {
                timeRangeInAsset = clipTimeRanges[i]
            } else {
                timeRangeInAsset = CMTimeRangeMake(kCMTimeZero, asset.duration)
            }
            
            do {
                let clipVideoTrack = asset.tracks(withMediaType: AVMediaTypeVideo)[0]
                try compositionVideoTracks[alternatingIndex].insertTimeRange(timeRangeInAsset,
                                                                             of: clipVideoTrack, at: nextClipStartTime)
                
                let clipAudioTrack = asset.tracks(withMediaType: AVMediaTypeAudio)[0]
                try compositionAudioTracks[alternatingIndex].insertTimeRange(timeRangeInAsset,
                                                                             of: clipAudioTrack, at: nextClipStartTime)
            } catch {
                print("An error occurred inserting a time range of the source track into the composition.")
            }
            
            /*
             Remember the time range in which this clip should pass through.
             First clip ends with a transition.
             Second clip begins with a transition.
             Exclude that transition from the pass through time ranges.
             */
            passThroughTimeRanges[i] = CMTimeRangeMake(nextClipStartTime, timeRangeInAsset.duration)
            if i > 0 {
                passThroughTimeRanges[i].start = CMTimeAdd(passThroughTimeRanges[i].start, transitionDuration)
                passThroughTimeRanges[i].duration = CMTimeSubtract(passThroughTimeRanges[i].duration, transitionDuration)
            }
            if i + 1 < clipsCount {
                passThroughTimeRanges[i].duration = CMTimeSubtract(passThroughTimeRanges[i].duration, transitionDuration)
            }
            
            /*
             The end of this clip will overlap the start of the next by transitionDuration.
             (Note: this arithmetic falls apart if timeRangeInAsset.duration < 2 * transitionDuration.)
             */
            nextClipStartTime = CMTimeAdd(nextClipStartTime, timeRangeInAsset.duration)
            nextClipStartTime = CMTimeSubtract(nextClipStartTime, transitionDuration)
            
            // Remember the time range for the transition to the next item.
            if i + 1 < clipsCount {
                transitionTimeRanges[i] = CMTimeRangeMake(nextClipStartTime, transitionDuration)
            }
        }
    }

    func makeTransitionInstructions(videoComposition: AVMutableVideoComposition,
                                    compositionVideoTracks: [AVMutableCompositionTrack]) -> [Any] {
        var alternatingIndex = 0

        // Set up the video composition to perform cross dissolve or diagonal wipe transitions between clips.
        var instructions = [Any]()

        // Cycle between "pass through A", "transition from A to B", "pass through B".
        for i in 0..<clips.count {
            alternatingIndex = i % 2 // Alternating targets.

            if videoComposition.customVideoCompositorClass != nil {
                let videoInstruction =
                    APLCustomVideoCompositionInstruction(thePassthroughTrackID:
                        compositionVideoTracks[alternatingIndex].trackID,
                                                         forTimeRange: passThroughTimeRanges[i])
                instructions.append(videoInstruction)
            } else {
                // Pass through clip i.
                let passThroughInstruction = AVMutableVideoCompositionInstruction()
                passThroughInstruction.timeRange = passThroughTimeRanges[i]
                let passThroughLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTracks[alternatingIndex])
                passThroughInstruction.layerInstructions = [passThroughLayer]
                instructions.append(passThroughInstruction)
            }

            if i + 1 < clips.count {
                // Add transition from clip i to clip i+1.
                if videoComposition.customVideoCompositorClass != nil {
                    let videoInstruction =
                        APLCustomVideoCompositionInstruction(theSourceTrackIDs:
                            [NSNumber(value:compositionVideoTracks[0].trackID),
                             NSNumber(value:compositionVideoTracks[1].trackID)],
                                                             forTimeRange: transitionTimeRanges[i])
                    if alternatingIndex == 0 {
                        // First track -> Foreground track while compositing.
                        videoInstruction.foregroundTrackID = compositionVideoTracks[alternatingIndex].trackID
                        // Second track -> Background track while compositing.
                        videoInstruction.backgroundTrackID =
                            compositionVideoTracks[1 - alternatingIndex].trackID
                    }

                    instructions.append(videoInstruction)
                } else {
                    let transitionInstruction = AVMutableVideoCompositionInstruction()
                    transitionInstruction.timeRange = transitionTimeRanges[i]
                    let fromLayer =
                        AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTracks[alternatingIndex])
                    let toLayer =
                        AVMutableVideoCompositionLayerInstruction(assetTrack:compositionVideoTracks[1 - alternatingIndex])
                    transitionInstruction.layerInstructions = [fromLayer, toLayer]
                    instructions.append(transitionInstruction)
                }
            }
        }

        return instructions
    }
    
    func buildTransitionComposition(_ composition: AVMutableComposition, andVideoComposition videoComposition: AVMutableVideoComposition) {

        // Add two video tracks and two audio tracks.
        var compositionVideoTracks =
            [composition.addMutableTrack(withMediaType: AVMediaTypeVideo,
                                         preferredTrackID: kCMPersistentTrackID_Invalid),
             composition.addMutableTrack(withMediaType: AVMediaTypeVideo,
                                         preferredTrackID: kCMPersistentTrackID_Invalid)]
        var compositionAudioTracks =
            [composition.addMutableTrack(withMediaType: AVMediaTypeAudio,
                                         preferredTrackID: kCMPersistentTrackID_Invalid),
             composition.addMutableTrack(withMediaType: AVMediaTypeAudio,
                                         preferredTrackID: kCMPersistentTrackID_Invalid)]

        buildComposition(compositionVideoTracks: &compositionVideoTracks, &compositionAudioTracks)

        let instructions = makeTransitionInstructions(videoComposition: videoComposition,
                                                      compositionVideoTracks: compositionVideoTracks)

        guard let newInstructions = instructions as? [AVVideoCompositionInstructionProtocol] else {
            videoComposition.instructions = []
            return
        }

        videoComposition.instructions = newInstructions
    }
    
    func buildCompositionObjectsForPlayback(_ forPlayback: Bool, overwriteExistingObjects: Bool) {

        // Proceed only if the composition objects have not already been created.
        if self.composition != nil && !overwriteExistingObjects { return }
        if self.videoComposition != nil && !overwriteExistingObjects { return }

        guard !clips.isEmpty else { return }

        // Use the naturalSize of the first video track.
        let videoTracks = clips[0].tracks(withMediaType: AVMediaTypeVideo)
        let videoSize = videoTracks[0].naturalSize
            
        let composition = AVMutableComposition()
            
        composition.naturalSize = videoSize

        /*
         With transitions:
         Place clips into alternating video & audio tracks in composition, overlapped by transitionDuration.
         Set up the video composition to cycle between "pass through A", "transition from A to B", "pass through B".
        */
        let videoComposition = AVMutableVideoComposition()

        if self.transitionType == TransitionType.diagonalWipe.rawValue {
            videoComposition.customVideoCompositorClass = APLDiagonalWipeCompositor.self
        } else {
            videoComposition.customVideoCompositorClass = APLCrossDissolveCompositor.self
        }

        // Every videoComposition needs these properties to be set:
        videoComposition.frameDuration = CMTimeMake(1, 30) // 30 fps.
        videoComposition.renderSize = videoSize

        buildTransitionComposition(composition, andVideoComposition: videoComposition)

        self.composition = composition
        self.videoComposition = videoComposition
    }

    func playerItem() -> AVPlayerItem? {

        guard let theComposition = self.composition, let theVideoComposition = self.videoComposition else { return nil }

        let playerItem = AVPlayerItem(asset: theComposition)
        playerItem.videoComposition = theVideoComposition

        return playerItem
    }
}
