//
//  RemoteCommandDataSource.swift
//  MPRemoteCommandSample
//
//  Created by Bilal S. Sayed Ahmad on 10/17/16.
//
//

import Foundation

class RemoteCommandDataSource: NSObject {
    
    let remoteCommandManager: RemoteCommandManager
    
    init(remoteCommandManager: RemoteCommandManager) {
        self.remoteCommandManager = remoteCommandManager
    }
    
    /// Enumeration of the different sections of the UITableView.
    private enum commandSection: Int {
        case trackChanging, skipInterval, seek, feedback
        
        func sectionTitle() -> String {
            switch self {
            case .trackChanging: return "Track Changing Commands"
            case .skipInterval: return "Skip Interval Commands"
            case .seek: return "Seek Commands"
            case .feedback: return "Feedback Commands"
            }
        }
    }
    
    /// Enumeration of the various commands supported by `MPRemoteCommandCenter`.
    private enum command {
        case nextTrack, previousTrack, skipForward, skipBackward, seekForward, seekBackward, changePlaybackPosition, like, dislike, bookmark
        
        init?(_ section: Int, row: Int) {
            guard let section = commandSection(rawValue: section) else { return nil }
            
            switch section {
            case .trackChanging:
                if row == 0 {
                    self = .nextTrack
                }
                else {
                    self = .previousTrack
                }
            case .skipInterval:
                if row == 0 {
                    self = .skipForward
                }
                else {
                    self = .skipBackward
                }
            case .seek:
                if row == 0 {
                    self = .seekForward
                }
                else if row == 1 {
                    self = .seekBackward
                }
                else {
                    self = .changePlaybackPosition
                }
            case .feedback:
                if row == 0 {
                    self = .like
                }
                else if row == 1 {
                    self = .dislike
                }
                else {
                    self = .bookmark
                }
            }
        }
        
        func commandTitle() -> String {
            switch self {
            case .nextTrack: return "Next Track Command"
            case .previousTrack: return "Previous Track Command"
            case .skipForward: return "Skip Forward Command"
            case .skipBackward: return "Skip Backward Command"
            case .seekForward: return "Seek Forward Command"
            case .seekBackward: return "Seek Backward Command"
            case .changePlaybackPosition: return "Change Playback Position Command"
            case .like: return "Like Command"
            case .dislike: return "Dislike Command"
            case .bookmark: return "Bookmark Command"
            }
        }
    }
    
    func numberOfRemoteCommandSections() -> Int {
        #if os(iOS)
            return 4
        #else
            return 3
        #endif
    }
    
    func titleForSection(_ section: Int) -> String {
        guard let commandSection = commandSection(rawValue: section) else { return "Invalid Section" }
        
        return commandSection.sectionTitle()
    }
    
    func titleStringForCommand(at section: Int, row: Int) -> String {
        guard let remoteCommand = command(section, row: row) else { return "Invalid Command" }
        
        return remoteCommand.commandTitle()
    }
    
    func numberOfItemsInSection(_ section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return 2
        case 2: return 3
        case 3: return 3
        default: return 0
        }
    }
    
    func toggleCommandHandler(with section: Int, row: Int, enable: Bool) {
        guard let remoteCommand = command(section, row: row) else { return }
        
        switch remoteCommand {
        case .nextTrack: remoteCommandManager.toggleNextTrackCommand(enable)
        case .previousTrack: remoteCommandManager.togglePreviousTrackCommand(enable)
        case .skipForward: remoteCommandManager.toggleSkipForwardCommand(enable, interval: 15)
        case .skipBackward: remoteCommandManager.toggleSkipBackwardCommand(enable, interval: 20)
        case .seekForward: remoteCommandManager.toggleSeekForwardCommand(enable)
        case .seekBackward: remoteCommandManager.toggleSeekBackwardCommand(enable)
        case .changePlaybackPosition: remoteCommandManager.toggleChangePlaybackPositionCommand(enable)
        case .like: remoteCommandManager.toggleLikeCommand(enable)
        case .dislike: remoteCommandManager.toggleDislikeCommand(enable)
        case .bookmark: remoteCommandManager.toggleBookmarkCommand(enable)
        }
    }
}
