/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the AddEditConfiguration class, which is responsible for controlling a view used to create or edit a VPN configuration.
*/

import UIKit
import NetworkExtension
import Security
import SimpleTunnelServices

/// A view controller object for a table view containing input fields used to specify configuration parameters for a VPN configuration.
class AddEditConfiguration: ConfigurationParametersViewController {

	// MARK: Properties

	/// A table view cell containing the text field where the name of the configuration is entered.
	@IBOutlet weak var nameCell: TextFieldCell!

	/// A table view cell containing the text field where the server address of the configuration is entered.
	@IBOutlet weak var serverAddressCell: TextFieldCell!

	/// A table view cell containing the text field where the username of the configuration is entered.
	@IBOutlet weak var usernameCell: TextFieldCell!

	/// A table view cell containing the text field where the password of the configuration is entered.
	@IBOutlet weak var passwordCell: TextFieldCell!

	/// A table view cell containing a switch used to enable and disable Connect On Demand for the configuration.
	@IBOutlet weak var onDemandCell: SwitchCell!

	/// A table view cell containing a switch used to enable and disable proxy settings for the configuration.
	@IBOutlet weak var proxiesCell: SwitchCell!

	/// A table view cell containing a switch used to enable and disable Disconnect On Sleep for the configuration.
	@IBOutlet weak var disconnectOnSleepCell: SwitchCell!

	/// A table view cell that when tapped transitions the app to a view where the Connect On Demand rules are managed.
	@IBOutlet weak var onDemandRulesCell: UITableViewCell!

	/// A table view cell that when tapped transitions the app to a view where the proxy settings are managed.
	@IBOutlet weak var proxySettingsCell: UITableViewCell!

	/// The NEVPNManager object corresponding to the configuration being added or edited.
	var targetManager: NEVPNManager = NEVPNManager.sharedManager()

	// MARK: UIViewController

	/// Handle the event of the view being loaded into memory.
	override func viewDidLoad() {
		super.viewDidLoad()

		// Set up the table view cells

		cells = [
			nameCell,
			serverAddressCell,
			usernameCell,
			passwordCell,
			onDemandCell,
			proxiesCell,
			disconnectOnSleepCell
		].flatMap { $0 }

		// The switch in proxiesCell controls the display of proxySettingsCell
		proxiesCell.dependentCells = [ proxySettingsCell ]
		proxiesCell.getIndexPath = {
			return self.getIndexPathOfCell(self.proxiesCell)
		}
		proxiesCell.valueChanged = {
			self.updateCellsWithDependentsOfCell(self.proxiesCell)
		}

		// The switch in onDemandCell controls the display of onDemandRulesCell
		onDemandCell.dependentCells = [ onDemandRulesCell ]
		onDemandCell.getIndexPath = {
			return self.getIndexPathOfCell(self.onDemandCell)
		}
		onDemandCell.valueChanged = {
			self.updateCellsWithDependentsOfCell(self.onDemandCell)
			self.targetManager.onDemandEnabled = self.onDemandCell.isOn
		}

		disconnectOnSleepCell.valueChanged = {
			self.targetManager.protocolConfiguration?.disconnectOnSleep = self.disconnectOnSleepCell.isOn
		}

		nameCell.valueChanged = {
			self.targetManager.localizedDescription = self.nameCell.textField.text
		}

		serverAddressCell.valueChanged = {
			self.targetManager.protocolConfiguration?.serverAddress = self.serverAddressCell.textField.text
		}

		usernameCell.valueChanged = {
			self.targetManager.protocolConfiguration?.username = self.usernameCell.textField.text
		}
	}

	/// Handle the event of the view being displayed.
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		tableView.reloadData()

		// Set the text fields and switches per the settings in the configuration.

		nameCell.textField.text = targetManager.localizedDescription
		serverAddressCell.textField.text = targetManager.protocolConfiguration?.serverAddress
		usernameCell.textField.text = targetManager.protocolConfiguration?.username

		if let passRef = targetManager.protocolConfiguration?.passwordReference {
			passwordCell.textField.text = getPasswordWithPersistentReference(passRef)
		}
		else {
			passwordCell.textField.text = nil
		}

		disconnectOnSleepCell.isOn = targetManager.protocolConfiguration?.disconnectOnSleep ?? false

		onDemandCell.isOn = targetManager.onDemandEnabled

		onDemandRulesCell.detailTextLabel?.text = getDescriptionForListValue(targetManager.onDemandRules, itemDescription: "rule")

		proxiesCell.isOn = targetManager.protocolConfiguration?.proxySettings != nil
	}

	/// Set up the destination view controller of a segue away from this view controller.
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		guard let identifier = segue.identifier else { return }

		switch identifier {
			case "edit-proxy-settings":
				// The user tapped on the proxy settings cell.
				guard let controller = segue.destinationViewController as? ProxySettingsController else { break }
				if targetManager.protocolConfiguration?.proxySettings == nil {
					targetManager.protocolConfiguration?.proxySettings = NEProxySettings()
				}
				controller.targetConfiguration = targetManager.protocolConfiguration ?? NETunnelProviderProtocol()

			case "edit-on-demand-rules":
				// The user tapped on the Connect On Demand rules cell.
				guard let controller = segue.destinationViewController as? OnDemandRuleListController else { break }
				controller.targetManager = targetManager

			default:
				break
		}
	}

	// MARK: Interface

	/// Set the target configuration and the title to display in the view.
	func setTargetManager(manager: NEVPNManager?, title: String?) {
		if let newManager = manager {
			// A manager was given, so an existing configuration is being edited.
			targetManager = newManager
		}
		else {
			// No manager was given, create a new configuration.
			let newManager = NETunnelProviderManager()
			newManager.protocolConfiguration = NETunnelProviderProtocol()
			newManager.localizedDescription = "Demo VPN"
			newManager.protocolConfiguration?.serverAddress = "TunnelServer"
			targetManager = newManager
		}
		navigationItem.title = title
	}

	/// Save the configuration to the Network Extension preferences.
	@IBAction func saveTargetManager(sender: AnyObject) {
		if !proxiesCell.isOn {
			targetManager.protocolConfiguration?.proxySettings = nil
		}
		targetManager.saveToPreferencesWithCompletionHandler { error in
			if let saveError = error {
				simpleTunnelLog("Failed to save the configuration: \(saveError)")
				return
			}

			// Transition back to the configuration list view.
			self.performSegueWithIdentifier("save-configuration", sender: sender)
		}
	}

	/// Save a password in the keychain.
	func savePassword(password: String, inKeychainItem: NSData?) -> NSData? {
		guard let passwordData = password.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) else { return nil }
		var status = errSecSuccess

		if let persistentReference = inKeychainItem {
			// A persistent reference was given, update the corresponding keychain item.
			let query: [NSObject: AnyObject] = [
				kSecValuePersistentRef : persistentReference,
				kSecReturnAttributes : kCFBooleanTrue
			]
			var result: AnyObject?

			// Get the current attributes for the item.
			status = SecItemCopyMatching(query, &result)

			if let attributes = result as? [NSObject: AnyObject] where status == errSecSuccess {
				// Update the attributes with the new data.
				var updateQuery = [NSObject: AnyObject]()
				updateQuery[kSecClass] = kSecClassGenericPassword
				updateQuery[kSecAttrService] = attributes[kSecAttrService]

				var newAttributes = attributes
				newAttributes[kSecValueData] = passwordData

				status = SecItemUpdate(updateQuery, newAttributes)
				if status == errSecSuccess {
					return persistentReference
				}
			}
		}

		if inKeychainItem == nil || status != errSecSuccess {
			// No persistent reference was provided, or the update failed. Add a new keychain item.

			let attributes: [NSObject: AnyObject] = [
				kSecAttrService : NSUUID().UUIDString,
				kSecValueData : passwordData,
				kSecAttrAccessible : kSecAttrAccessibleAlways,
				kSecClass : kSecClassGenericPassword,
				kSecReturnPersistentRef : kCFBooleanTrue
			]

			var result: AnyObject?
			status = SecItemAdd(attributes, &result)

			if let newPersistentReference = result as? NSData where status == errSecSuccess {
				return newPersistentReference
			}
		}
		return nil
	}

	/// Remove a password from the keychain.
	func removePasswordWithPersistentReference(persistentReference: NSData) {
		let query: [NSObject: AnyObject] = [
			kSecClass : kSecClassGenericPassword,
			kSecValuePersistentRef : persistentReference
		]

		let status = SecItemDelete(query)
		if status != errSecSuccess {
			simpleTunnelLog("Failed to delete a password: \(status)")
		}
	}

	/// Get a password from the keychain.
	func getPasswordWithPersistentReference(persistentReference: NSData) -> String? {
		var result: String?
		let query: [NSObject: AnyObject] = [
			kSecClass : kSecClassGenericPassword,
			kSecReturnData : kCFBooleanTrue,
			kSecValuePersistentRef : persistentReference
		]

		var returnValue: AnyObject?
		let status = SecItemCopyMatching(query, &returnValue)

		if let passwordData = returnValue as? NSData where status == errSecSuccess {
			result = NSString(data: passwordData, encoding: NSUTF8StringEncoding) as? String
		}
		return result
	}
}
