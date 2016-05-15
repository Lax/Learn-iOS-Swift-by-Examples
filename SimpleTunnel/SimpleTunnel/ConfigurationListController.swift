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
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		// Re-load all of the configurations.
		reloadManagers()
	}

	// MARK: Interface

	/// Re-load all of the packet tunnel configurations from the Network Extension preferences
	func reloadManagers() {
		NETunnelProviderManager.loadAllFromPreferencesWithCompletionHandler() { newManagers, error in
			guard let vpnManagers = newManagers else { return }

			self.stopObservingStatus()
			self.managers = vpnManagers
			self.observeStatus()

			// If there are no configurations, automatically go into editing mode.
			if self.managers.count == 0 && !self.editing {
				self.setEditing(true, animated: false)
			}

			self.tableView.reloadData()
		}
	}

	/// Register for configuration change notifications.
	func observeStatus() {
		for (index, manager) in managers.enumerate() {
			NSNotificationCenter.defaultCenter().addObserverForName(NEVPNStatusDidChangeNotification, object: manager.connection, queue: NSOperationQueue.mainQueue(), usingBlock: { notification in
				self.tableView.reloadRowsAtIndexPaths([ NSIndexPath(forRow: index, inSection: 0) ], withRowAnimation: .Fade)
			})
		}
	}

	/// De-register for configuration change notifications.
	func stopObservingStatus() {
		for manager in managers {
			NSNotificationCenter.defaultCenter().removeObserver(self, name: NEVPNStatusDidChangeNotification, object: manager.connection)
		}
	}

	/// Unwind segue handler.
	@IBAction func handleUnwind(sender: UIStoryboardSegue) {
	}

	// MARK: ListViewController

	/// Set up the destination view controller of a segue away from this view controller.
	override func listSetupSegue(segue: UIStoryboardSegue, forItemAtIndex index: Int) {

		guard let identifier = segue.identifier else { return }

		switch identifier {
			case "start-new-configuration":
				// The user tapped on the "Add Configuration..." table row.
				guard let addEditController = segue.destinationViewController as? AddEditConfiguration else { break }

				addEditController.setTargetManager(nil, title: "Add Configuration")

			case "edit-configuration":
				// The user tapped on the disclosure button of a configuration while in editing mode.
				guard let addEditController = segue.destinationViewController as? AddEditConfiguration where index < managers.count else { break }

				addEditController.setTargetManager(managers[index], title: managers[index].localizedDescription)

			case "introspect-status":
				// The user tapped on a configuration while not in editing mode.
				guard let statusViewController = segue.destinationViewController as? StatusViewController where index < managers.count else { break }

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
	override func listTextForItemAtIndex(index: Int) -> String {
		return managers[index].localizedDescription ?? "NoName"
	}

	/// Returns the appropriate image for the configuration at the given index.
	override func listImageForItemAtIndex(index: Int) -> UIImage? {
		let manager = managers[index]

		guard manager.enabled else { return disabledImage }

		switch manager.connection.status {
			case .Invalid: fallthrough
			case .Disconnected: return disconnectedImage
			default: return notDisconnectedImage
		}
	}

	/// Returns UITableViewCellAccessoryType.DisclosureIndicator.
	override var listAccessoryType: UITableViewCellAccessoryType {
		return .DisclosureIndicator
	}

	/// Returns UITableViewCellAccessoryType.DetailButton.
	override var listEditingAccessoryType: UITableViewCellAccessoryType {
		return .DetailButton
	}

	/// Handle a user tap on the "Delete" button for a configuration.
	override func listRemoveItemAtIndex(index: Int) {

		// Remove the configuration from the Network Extension preferences.
		managers[index].removeFromPreferencesWithCompletionHandler {
			error in
			if let error = error {
				simpleTunnelLog("Failed to remove manager: \(error)")
			}
		}
		managers.removeAtIndex(index)
	}
}
