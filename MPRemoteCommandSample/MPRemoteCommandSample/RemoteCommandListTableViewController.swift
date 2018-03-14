/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	`RemoteCommandListTableViewController` is a `UITableViewController` subclass that lists all the supported MPRemoteCommands that are available to enable/disable.
 */

import UIKit

class RemoteCommandListTableViewController: UITableViewController, RemoteCommandListTableViewCellDelegate {
    
    // MARK: Properties
    
    /// The instance of `RemoteCommandDataSource` to use for responding to `UITableViewDataSource` delegate callbacks.
    var remoteCommandDataSource: RemoteCommandDataSource!

    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Configure"

        tableView.estimatedRowHeight = 75
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    // MARK: UITableViewDataSource Protocol Methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return remoteCommandDataSource.numberOfRemoteCommandSections()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return remoteCommandDataSource.numberOfItemsInSection(section)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return remoteCommandDataSource.titleForSection(section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RemoteCommandListTableViewCell.reuseIdentifier, for: indexPath)

        if let cell = cell as? RemoteCommandListTableViewCell {
            cell.delegate = self
            cell.commandTitleLabel.text = remoteCommandDataSource.titleStringForCommand(at: indexPath.section, row: indexPath.row)
        }

        return cell
    }
    
    // MARK: RemoteCommandListTableViewCellDelegate Protocol Method
    
    func remoteCommandListTableViewCell(_ cell: RemoteCommandListTableViewCell, didToggleTo enabled: Bool) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        remoteCommandDataSource.toggleCommandHandler(with: indexPath.section, row: indexPath.row, enable: enabled)
    }
}
