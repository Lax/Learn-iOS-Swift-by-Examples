/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the ConfigurationListController class, which is responsible for controlling a list of VPN configurations.
*/

import UIKit
import NetworkExtension
import SimpleTunnelServices

/// The view controller object for the list of packet tunnel configurations.
class ConfigurationListController: ListViewController {

	// MARK: Properties

	/// The image to display for configurations that are disabled.
	let disabledImage = UIImage(named: "GrayDot")

	/// The image to display for configurations that are enabled but are disconnected.
	let disconnectedImage = UIImage(named: "RedDot")

	/// The image to display for configurations that are active (or not disconnected).
	let notDisconnectedImage = UIImage(named: "GreenDot")

	/// A list of NEVPNManager objects for the packet tunnel configurations.
	var managers = [NEVPNManager]()

	// MARK: UIViewController

	/// Handle the event of the view loading into memory.
	override func viewDidLoad() {
		isAddEnabled = true
		super.viewDidLoad()
	}

	/// Handle the event of the view being displayed.
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		// Re-load all of the configurations.
		reloadManagers()
	}

	// MARK: Interface

	/// Re-load all of the packet tunnel configurations from the Network Extension preferences
	func reloadManagers() {
		NETunnelProviderManager.loadAllFromPreferences() { newManagers, error in
			guard let vpnManagers = newManagers else { return }

			self.stopObservingStatus()
			self.managers = vpnManagers
			self.observeStatus()

			// If there are no configurations, automatically go into editing mode.
			if self.managers.count == 0 && !self.isEditing {
				self.setEditing(true, animated: false)
			}

			self.tableView.reloadData()
		}
	}

	/// Register for configuration change notifications.
	func observeStatus() {
		for (index, manager) in managers.enumerated() {
			NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: manager.connection, queue: OperationQueue.main, using: { notification in
				self.tableView.reloadRows(at: [ IndexPath(row: index, section: 0) ], with: .fade)
			})
		}
	}

	/// De-register for configuration change notifications.
	func stopObservingStatus() {
		for manager in managers {
			NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NEVPNStatusDidChange, object: manager.connection)
		}
	}

	/// Unwind segue handler.
	@IBAction func handleUnwind(_ sender: UIStoryboardSegue) {
	}

	// MARK: ListViewController

	/// Set up the destination view controller of a segue away from this view controller.
	override func listSetupSegue(_ segue: UIStoryboardSegue, forItemAtIndex index: Int) {

		guard let identifier = segue.identifier else { return }

		switch identifier {
			case "start-new-configuration":
				// The user tapped on the "Add Configuration..." table row.
				guard let addEditController = segue.destination as? AddEditConfiguration else { break }

				addEditController.setTargetManager(nil, title: "Add Configuration")

			case "edit-configuration":
				// The user tapped on the disclosure button of a configuration while in editing mode.
				guard let addEditController = segue.destination as? AddEditConfiguration , index < managers.count else { break }

				addEditController.setTargetManager(managers[index], title: managers[index].localizedDescription)

			case "introspect-status":
				// The user tapped on a configuration while not in editing mode.
				guard let statusViewController = segue.destination as? StatusViewController , index < managers.count else { break }

				statusViewController.targetManager = managers[index]

			default:
				break
		}
	}

	/// The current number of configurations.
	override var listCount: Int {
		return managers.count
	}

	/// Returns the localized description of the configuration at the given index.
	override func listTextForItemAtIndex(_ index: Int) -> String {
		return managers[index].localizedDescription ?? "NoName"
	}

	/// Returns the appropriate image for the configuration at the given index.
	override func listImageForItemAtIndex(_ index: Int) -> UIImage? {
		let manager = managers[index]

		guard manager.isEnabled else { return disabledImage }

		switch manager.connection.status {
			case .invalid: fallthrough
			case .disconnected: return disconnectedImage
			default: return notDisconnectedImage
		}
	}

	/// Returns UITableViewCellAccessoryType.DisclosureIndicator.
	override var listAccessoryType: UITableViewCellAccessoryType {
		return .disclosureIndicator
	}

	/// Returns UITableViewCellAccessoryType.DetailButton.
	override var listEditingAccessoryType: UITableViewCellAccessoryType {
		return .detailButton
	}

	/// Handle a user tap on the "Delete" button for a configuration.
	override func listRemoveItemAtIndex(_ index: Int) {

		// Remove the configuration from the Network Extension preferences.
		managers[index].removeFromPreferences {
			error in
			if let error = error {
				simpleTunnelLog("Failed to remove manager: \(error)")
			}
		}
		managers.remove(at: index)
	}
}
