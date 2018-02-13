/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the ProxyServerAddEditController class, which controls a view used to create or edit a proxy server configuration.
*/

import UIKit
import NetworkExtension

/// A view controller object for a view that contains input fields used to define HTTP proxy server settings.
class ProxyServerAddEditController: ConfigurationParametersViewController {

	// MARK: Properties

	/// A table view cell containing a text input field where the user enters the proxy server address.
	@IBOutlet weak var addressCell: TextFieldCell!

	/// A table view cell containing a text input field where the user enters the proxy server port number.
	@IBOutlet weak var portCell: TextFieldCell!

	/// A table view cell containing a text input field where the user enters the username portion of the proxy credential.
	@IBOutlet weak var usernameCell: TextFieldCell!

	/// A table view cell containing a text input field where the user enters the password portion of the proxy credential.
	@IBOutlet weak var passwordCell: TextFieldCell!

	/// A table view cell containing a switch that toggles authentication for the proxy server.
	@IBOutlet weak var authenticationSwitchCell: SwitchCell!

	/// The NEProxyServer object containing the proxy server settings.
	var targetServer = NEProxyServer(address: "", port: 0)

	/// The block to call when the user taps on the "Done" button.
	var saveChangesCallback: (NEProxyServer) -> Void = { server in return }

	// MARK: UIViewController

	/// Handle the event where the view is loaded into memory.
	override func viewDidLoad() {
		super.viewDidLoad()

		cells = [
			addressCell,
			portCell,
			authenticationSwitchCell
		].flatMap { $0 }

		authenticationSwitchCell.dependentCells = [ usernameCell, passwordCell ]
		authenticationSwitchCell.getIndexPath = {
			return self.getIndexPathOfCell(self.authenticationSwitchCell)
		}
		authenticationSwitchCell.valueChanged = {
			self.updateCellsWithDependentsOfCell(self.authenticationSwitchCell)
			self.targetServer.authenticationRequired = self.authenticationSwitchCell.isOn
		}
	}

	/// Handle the event when the view is being displayed.
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		tableView.reloadData()

		addressCell.textField.text = !targetServer.address.isEmpty ? targetServer.address : nil
		portCell.textField.text = targetServer.port > 0 ? String(targetServer.port) : nil
		passwordCell.textField.text = targetServer.password
		usernameCell.textField.text = targetServer.username
		authenticationSwitchCell.isOn = targetServer.authenticationRequired
	}

	// MARK: Interface

	/// Set the NEProxyServer object to modify, the title of the view, and a block to call when the user is done modify the proxy server settings.
	func setTargetServer(_ server: NEProxyServer?, title: String, saveHandler: @escaping (NEProxyServer) -> Void) {
		targetServer = server ?? NEProxyServer(address: "", port: 0)
		navigationItem.title = title
		saveChangesCallback = saveHandler
	}

	/// Gather all of the inputs from the user and call saveChangesCallback. This function is called when the user taps on the "Done" button.
	@IBAction func saveProxyServer(_ sender: AnyObject) {
		guard let address = addressCell.textField.text,
			let portString = portCell.textField.text,
			let port = Int(portString)
			, !address.isEmpty && !portString.isEmpty
			else { return }

		let result = NEProxyServer(address: address, port: port)
		result.username = usernameCell.textField.text
		result.password = passwordCell.textField.text
		result.authenticationRequired = authenticationSwitchCell.isOn
		saveChangesCallback(result)
		// Go back to the main proxy settings view.
		performSegue(withIdentifier: "save-proxy-server-settings", sender: sender)
	}
}
