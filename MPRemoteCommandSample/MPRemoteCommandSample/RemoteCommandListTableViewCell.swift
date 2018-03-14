/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	`RemoteCommandListTableViewCell` is a `UITableViewCell` subclass that responds to the user toggling a specific `MPRemoteCommand` as enabled/disabled.
 */

import UIKit

class RemoteCommandListTableViewCell: UITableViewCell {
    
    // MARK: Types
    
    /// The reuse identifier to use for retrieving this cell.
    static let reuseIdentifier = "RemoteCommandListTableViewCellIdentifier"
    
    // MARK: Properties
    
    /// The delegate that is used to respond to target-action calls.
    var delegate: RemoteCommandListTableViewCellDelegate?

    /// The `UILabel` for displaying the name of the command.
    @IBOutlet weak var commandTitleLabel: UILabel!

    // MARK: Target-Action Method
    
    @IBAction func userDidToggleSwitch(_ sender: UISwitch) {
        delegate?.remoteCommandListTableViewCell(self, didToggleTo: sender.isOn)
    }
}

/// `RemoteCommandListTableViewCellDelegate` provides a common interface for `RemoteCommandListTableViewCell` to provide callbacks to its `delegate`.
protocol RemoteCommandListTableViewCellDelegate {
    
    /// This is called when the `UISwitch` in a `RemoteCommandListTableViewCell` is toggled.
    func remoteCommandListTableViewCell(_ cell: RemoteCommandListTableViewCell, didToggleTo enabled: Bool)
}
