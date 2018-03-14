/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	`RemoteCommandManager` contains all the APIs calls to MPRemoteCommandCenter to enable and disable various remote control events.
 */

import Foundation
import MediaPlayer

class RemoteCommandManager: NSObject {
    
    // MARK: Properties
    
    /// Reference of `MPRemoteCommandCenter` used to configure and setup remote control events in the application.
    fileprivate let remoteCommandCenter = MPRemoteCommandCenter.shared()
    
    /// The instance of `AssetPlaybackManager` to use for responding to remote command events.
    let assetPlaybackManager: AssetPlaybackManager
    
    // MARK: Initialization.
    
    init(assetPlaybackManager: AssetPlaybackManager) {
        self.assetPlaybackManager = assetPlaybackManager
    }
    
    deinit {
        
        #if os(tvOS)
        activatePlaybackCommands(false)
        #endif
        
        activatePlaybackCommands(false)
        toggleNextTrackCommand(false)
        togglePreviousTrackCommand(false)
        toggleSkipForwardCommand(false)
        toggleSkipBackwardCommand(false)
        toggleSeekForwardCommand(false)
        toggleSeekBackwardCommand(false)
        toggleChangePlaybackPositionCommand(false)
        toggleLikeCommand(false)
        toggleDislikeCommand(false)
        toggleBookmarkCommand(false)
    }
    
    // MARK: MPRemoteCommand Activation/Deactivation Methods
    
    #if os(tvOS)
    func activateRemoteCommands(_ enable: Bool) {
        activatePlaybackCommands(enable)
        
        // To support Siri's "What did they say?" command you have to support the appropriate skip commands.  See the README for more information.
        toggleSkipForwardCommand(enable, interval: 15)
        toggleSkipBackwardCommand(enable, interval: 20)
    }
    #endif

    func activatePlaybackCommands(_ enable: Bool) {
        if enable {
            remoteCommandCenter.playCommand.addTarget(self, action: #selector(RemoteCommandManager.handlePlayCommandEvent(_:)))
            remoteCommandCenter.pauseCommand.addTarget(self, action: #selector(RemoteCommandManager.handlePauseCommandEvent(_:)))
            remoteCommandCenter.stopCommand.addTarget(self, action: #selector(RemoteCommandManager.handleStopCommandEvent(_:)))
            remoteCommandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(RemoteCommandManager.handleTogglePlayPauseCommandEvent(_:)))
            
        }
        else {
            remoteCommandCenter.playCommand.removeTarget(self, action: #selector(RemoteCommandManager.handlePlayCommandEvent(_:)))
            remoteCommandCenter.pauseCommand.removeTarget(self, action: #selector(RemoteCommandManager.handlePauseCommandEvent(_:)))
            remoteCommandCenter.stopCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleStopCommandEvent(_:)))
            remoteCommandCenter.togglePlayPauseCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleTogglePlayPauseCommandEvent(_:)))
        }
        
        remoteCommandCenter.playCommand.isEnabled = enable
        remoteCommandCenter.pauseCommand.isEnabled = enable
        remoteCommandCenter.stopCommand.isEnabled = enable
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = enable
    }
    
    func toggleNextTrackCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.nextTrackCommand.addTarget(self, action: #selector(RemoteCommandManager.handleNextTrackCommandEvent(_:)))
        }
        else {
            remoteCommandCenter.nextTrackCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleNextTrackCommandEvent(_:)))
        }
        
        remoteCommandCenter.nextTrackCommand.isEnabled = enable
    }
    
    func togglePreviousTrackCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.previousTrackCommand.addTarget(self, action: #selector(RemoteCommandManager.handlePreviousTrackCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.previousTrackCommand.removeTarget(self, action: #selector(RemoteCommandManager.handlePreviousTrackCommandEvent(event:)))
        }
        
        remoteCommandCenter.previousTrackCommand.isEnabled = enable
    }
    
    func toggleSkipForwardCommand(_ enable: Bool, interval: Int = 0) {
        if enable {
            remoteCommandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: interval)]
            remoteCommandCenter.skipForwardCommand.addTarget(self, action: #selector(RemoteCommandManager.handleSkipForwardCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.skipForwardCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleSkipForwardCommandEvent(event:)))
        }
        
        remoteCommandCenter.skipForwardCommand.isEnabled = enable
    }
    
    func toggleSkipBackwardCommand(_ enable: Bool, interval: Int = 0) {
        if enable {
            remoteCommandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: interval)]
            remoteCommandCenter.skipBackwardCommand.addTarget(self, action: #selector(RemoteCommandManager.handleSkipBackwardCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.skipBackwardCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleSkipBackwardCommandEvent(event:)))
        }
        
        remoteCommandCenter.skipBackwardCommand.isEnabled = enable
    }
    
    func toggleSeekForwardCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.seekForwardCommand.addTarget(self, action: #selector(RemoteCommandManager.handleSeekForwardCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.seekForwardCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleSeekForwardCommandEvent(event:)))
        }
        
        remoteCommandCenter.seekForwardCommand.isEnabled = enable
    }
    
    func toggleSeekBackwardCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.seekBackwardCommand.addTarget(self, action: #selector(RemoteCommandManager.handleSeekBackwardCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.seekBackwardCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleSeekBackwardCommandEvent(event:)))
        }
        
        remoteCommandCenter.seekBackwardCommand.isEnabled = enable
    }
    
    func toggleChangePlaybackPositionCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.changePlaybackPositionCommand.addTarget(self, action: #selector(RemoteCommandManager.handleChangePlaybackPositionCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.changePlaybackPositionCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleChangePlaybackPositionCommandEvent(event:)))
        }
        
        
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = enable
    }
    
    func toggleLikeCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.likeCommand.addTarget(self, action: #selector(RemoteCommandManager.handleLikeCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.likeCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleLikeCommandEvent(event:)))
        }
        
        remoteCommandCenter.likeCommand.isEnabled = enable
    }
    
    func toggleDislikeCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.dislikeCommand.addTarget(self, action: #selector(RemoteCommandManager.handleDislikeCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.dislikeCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleDislikeCommandEvent(event:)))
        }
        
        remoteCommandCenter.dislikeCommand.isEnabled = enable
    }
    
    func toggleBookmarkCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.bookmarkCommand.addTarget(self, action: #selector(RemoteCommandManager.handleBookmarkCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.bookmarkCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleBookmarkCommandEvent(event:)))
        }
        
        remoteCommandCenter.bookmarkCommand.isEnabled = enable
    }
    
    // MARK: MPRemoteCommand handler methods.
    
    // MARK: Playback Command Handlers
    func handlePauseCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        assetPlaybackManager.pause()
        
        return .success
    }
    
    func handlePlayCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        assetPlaybackManager.play()
        
        return .success
    }
    
    func handleStopCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        assetPlaybackManager.stop()
        
        return .success
    }
    
    func handleTogglePlayPauseCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        assetPlaybackManager.togglePlayPause()
        
        return .success
    }
    
    // MARK: Track Changing Command Handlers
    func handleNextTrackCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        if assetPlaybackManager.asset != nil {
            assetPlaybackManager.nextTrack()
            
            return .success
        }
        else {
            return .noSuchContent
        }
    }
    
    func handlePreviousTrackCommandEvent(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        if assetPlaybackManager.asset != nil {
            assetPlaybackManager.previousTrack()
            
            return .success
        }
        else {
            return .noSuchContent
        }
    }
    
    // MARK: Skip Interval Command Handlers
    func handleSkipForwardCommandEvent(event: MPSkipIntervalCommandEvent) -> MPRemoteCommandHandlerStatus {
        assetPlaybackManager.skipForward(event.interval)
        
        return .success
    }
    
    func handleSkipBackwardCommandEvent(event: MPSkipIntervalCommandEvent) -> MPRemoteCommandHandlerStatus {
        assetPlaybackManager.skipBackward(event.interval)
        
        return .success
    }
    
    // MARK: Seek Command Handlers
    func handleSeekForwardCommandEvent(event: MPSeekCommandEvent) -> MPRemoteCommandHandlerStatus {
        
        switch event.type {
            case .beginSeeking: assetPlaybackManager.beginFastForward()
            case .endSeeking: assetPlaybackManager.endRewindFastForward()
        }
        return .success
    }
    
    func handleSeekBackwardCommandEvent(event: MPSeekCommandEvent) -> MPRemoteCommandHandlerStatus {
        switch event.type {
            case .beginSeeking: assetPlaybackManager.beginRewind()
            case .endSeeking: assetPlaybackManager.endRewindFastForward()
        }
        return .success
    }
    
    func handleChangePlaybackPositionCommandEvent(event: MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus {
        assetPlaybackManager.seekTo(event.positionTime)
        
        return .success
    }
    
    // MARK: Feedback Command Handlers
    func handleLikeCommandEvent(event: MPFeedbackCommandEvent) -> MPRemoteCommandHandlerStatus {
        
        if assetPlaybackManager.asset != nil {
            print("Did recieve likeCommand for \(assetPlaybackManager.asset.assetName)")
            return .success
        }
        else {
            return .noSuchContent
        }
    }
    
    func handleDislikeCommandEvent(event: MPFeedbackCommandEvent) -> MPRemoteCommandHandlerStatus {
        
        if assetPlaybackManager.asset != nil {
            print("Did recieve dislikeCommand for \(assetPlaybackManager.asset.assetName)")
            return .success
        }
        else {
            return .noSuchContent
        }
    }
    
    func handleBookmarkCommandEvent(event: MPFeedbackCommandEvent) -> MPRemoteCommandHandlerStatus {
        
        if assetPlaybackManager.asset != nil {
            print("Did recieve bookmarkCommand for \(assetPlaybackManager.asset.assetName)")
            return .success
        }
        else {
            return .noSuchContent
        }
    }
}

// MARK: Convienence Category to make it easier to expose different types of remote command groups as the UITableViewDataSource in RemoteCommandListTableViewController.
extension RemoteCommandManager {
    
    }
