/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the StatusViewController class, which controls a view used to start and stop a VPN connection, and display the status of the VPN connection.
*/

import UIKit
import NetworkExtension
import SimpleTunnelServices

// MARK: Extensions

/// Make NEVPNStatus convertible to a string
extension NEVPNStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        	case .disconnected: return "Disconnected"
        	case .invalid: return "Invalid"
        	case .connected: return "Connected"
        	case .connecting: return "Connecting"
        	case .disconnecting: return "Disconnecting"
        	case .reasserting: return "Reconnecting"
        }
    }
}

/// A view controller object for a view that displays VPN status information and allows the user to start and stop the VPN.
class StatusViewController: UITableViewController {

	// MARK: Properties

	/// A switch that toggles the enabled state of the VPN configuration.
	@IBOutlet weak var enabledSwitch: UISwitch!

	/// A switch that starts and stops the VPN.
	@IBOutlet weak var startStopToggle: UISwitch!

	/// A label that contains the current status of the VPN.
	@IBOutlet weak var statusLabel: UILabel!

	/// The target VPN configuration.
	var targetManager = NEVPNManager.shared()

	// MARK: UIViewController

	/// Handle the event where the view is being displayed.
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		// Initialize the UI
		enabledSwitch.isOn = targetManager.isEnabled
		startStopToggle.isOn = (targetManager.connection.status != .disconnected && targetManager.connection.status != .invalid)
		statusLabel.text = targetManager.connection.status.description
		navigationItem.title = targetManager.localizedDescription

		// Register to be notified of changes in the status.
		NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: targetManager.connection, queue: OperationQueue.main, using: { notification in
			self.statusLabel.text = self.targetManager.connection.status.description
			self.startStopToggle.isOn = (self.targetManager.connection.status != .disconnected && self.targetManager.connection.status != .disconnecting && self.targetManager.connection.status != .invalid)
		})

		// Disable the start/stop toggle if the configuration is not enabled.
		startStopToggle.isEnabled = enabledSwitch.isOn

		// Send a simple IPC message to the provider, handle the response.
		if let session = targetManager.connection as? NETunnelProviderSession,
			let message = "Hello Provider".data(using: String.Encoding.utf8)
			, targetManager.connection.status != .invalid
		{
			do {
				try session.sendProviderMessage(message) { response in
					if response != nil {
						let responseString = NSString(data: response!, encoding: String.Encoding.utf8.rawValue)
						simpleTunnelLog("Received response from the provider: \(responseString)")
					} else {
						simpleTunnelLog("Got a nil response from the provider")
					}
				}
			} catch {
				simpleTunnelLog("Failed to send a message to the provider")
			}
		}
	}

	/// Handle the event where the view is being hidden.
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		// Stop watching for status change notifications.
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NEVPNStatusDidChange, object: targetManager.connection)
	}

	/// Handle the user toggling the "enabled" switch.
	@IBAction func enabledToggled(_ sender: AnyObject) {
		targetManager.isEnabled = enabledSwitch.isOn
		targetManager.saveToPreferences { error in
			guard error == nil else {
				self.enabledSwitch.isOn = self.targetManager.isEnabled
				self.startStopToggle.isEnabled = self.enabledSwitch.isOn
				return
			}
			
			self.targetManager.loadFromPreferences { error in
				self.enabledSwitch.isOn = self.targetManager.isEnabled
				self.startStopToggle.isEnabled = self.enabledSwitch.isOn
			}
		}
	}

	/// Handle the user toggling the "VPN" switch.
	@IBAction func startStopToggled(_ sender: AnyObject) {
		if targetManager.connection.status == .disconnected || targetManager.connection.status == .invalid {
			do {
				try targetManager.connection.startVPNTunnel()
			}
			catch {
				simpleTunnelLog("Failed to start the VPN: \(error)")
			}
		}
		else {
			targetManager.connection.stopVPNTunnel()
		}
	}
}
