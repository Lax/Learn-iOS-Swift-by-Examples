/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	`RemoteCommandView` is a `NSView` subclass that responds to the user toggling a specific `MPRemoteCommand` as enabled/disabled.
 */

import Cocoa

class RemoteCommandView: NSView {
    
    // MARK: Types
    
    /// The reuse identifier to use for retrieving this view.
    static let reuseIdentifier = "RemoteCommandViewIdentifier"
    
    // MARK: Properties
    
    /// The `NSButton` that is used for toggling an `MPRemoteCommand` as enabled or disabled.
    @IBOutlet weak var button: NSButton!
    
    /// The delegate that is used to respond to target-action calls.
    var delegate: RemoteCommandViewDelegate?
    
    // MARK: Target-Action
    
    @IBAction func userDidToggleCheckButton(_ sender: NSButton) {
        delegate?.remoteCommandView(self, didToggleTo: sender.state == NSOffState ? false : true)
    }
}

/// `RemoteCommandViewDelegate` provides a common interface for `RemoteCommandView` to provide callbacks to its `delegate`.
protocol RemoteCommandViewDelegate {
    
    /// This is called when the `NSButton` in a `RemoteCommandView` is clicked to reflect a change in state.
    func remoteCommandView(_ cell: RemoteCommandView, didToggleTo enabled: Bool)
}
