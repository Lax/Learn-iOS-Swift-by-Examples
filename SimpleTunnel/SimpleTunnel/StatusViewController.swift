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
        	case .Disconnected: return "Disconnected"
        	case .Invalid: return "Invalid"
        	case .Connected: return "Connected"
        	case .Connecting: return "Connecting"
        	case .Disconnecting: return "Disconnecting"
        	case .Reasserting: return "Reconnecting"
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
	var targetManager = NEVPNManager.sharedManager()

	// MARK: UIViewController

	/// Handle the event where the view is being displayed.
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		// Initialize the UI
		enabledSwitch.on = targetManager.enabled
		startStopToggle.on = (targetManager.connection.status != .Disconnected && targetManager.connection.status != .Invalid)
		statusLabel.text = targetManager.connection.status.description
		navigationItem.title = targetManager.localizedDescription

		// Register to be notified of changes in the status.
		NSNotificationCenter.defaultCenter().addObserverForName(NEVPNStatusDidChangeNotification, object: targetManager.connection, queue: NSOperationQueue.mainQueue(), usingBlock: { notification in
			self.statusLabel.text = self.targetManager.connection.status.description
			self.startStopToggle.on = (self.targetManager.connection.status != .Disconnected && self.targetManager.connection.status != .Disconnecting && self.targetManager.connection.status != .Invalid)
		})

		// Disable the start/stop toggle if the configuration is not enabled.
		startStopToggle.enabled = enabledSwitch.on

		// Send a simple IPC message to the provider, handle the response.
		if let session = targetManager.connection as? NETunnelProviderSession,
			message = "Hello Provider".dataUsingEncoding(NSUTF8StringEncoding)
			where targetManager.connection.status != .Invalid
		{
			do {
				try session.sendProviderMessage(message) { response in
					if response != nil {
						let responseString = NSString(data: response!, encoding: NSUTF8StringEncoding)
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
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)

		// Stop watching for status change notifications.
		NSNotificationCenter.defaultCenter().removeObserver(self, name: NEVPNStatusDidChangeNotification, object: targetManager.connection)
	}

	/// Handle the user toggling the "enabled" switch.
	@IBAction func enabledToggled(sender: AnyObject) {
		targetManager.enabled = enabledSwitch.on
		targetManager.saveToPreferencesWithCompletionHandler { error in
			guard error == nil else {
				self.enabledSwitch.on = self.targetManager.enabled
				self.startStopToggle.enabled = self.enabledSwitch.on
				return
			}
			
			self.targetManager.loadFromPreferencesWithCompletionHandler { error in
				self.enabledSwitch.on = self.targetManager.enabled
				self.startStopToggle.enabled = self.enabledSwitch.on
			}
		}
	}

	/// Handle the user toggling the "VPN" switch.
	@IBAction func startStopToggled(sender: AnyObject) {
		if targetManager.connection.status == .Disconnected || targetManager.connection.status == .Invalid {
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
