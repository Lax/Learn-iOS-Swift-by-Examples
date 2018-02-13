/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the ProxySettingsController class, which controls a view used to edit proxy settings.
*/

import UIKit
import NetworkExtension

/// A view controller object for a view that contains input fields used to define a HTTP proxy settings.
class ProxySettingsController: ConfigurationParametersViewController {

	// MARK: Properties

	/// A table view cell containing a switch that toggles Proxy Auto Configuration
	@IBOutlet weak var pacSwitchCell: SwitchCell!

	/// A table view cell containing a text input field where the user can enter the URL for a Proxy Auto Configuration script.
	@IBOutlet weak var pacURLCell: TextFieldCell!

	/// A table view cell that when tapped on allows the user to enter a Proxy Auto Configuration script.
	@IBOutlet weak var pacScriptCell: UITableViewCell!

	/// A table view cell that when tapped on allows the user to modify the static HTTP proxy settings.
	@IBOutlet weak var HTTPCell: UITableViewCell!

	/// A table view cell containing a switch that toggles the use of a static HTTP proxy.
	@IBOutlet weak var HTTPSwitchCell: SwitchCell!

	/// A table view cell that when tapped on allows the user to modify the static HTTPS proxy settings.
	@IBOutlet weak var HTTPSCell: UITableViewCell!

	/// A table view cell containing a switch that toggles the use of a static HTTPS proxy.
	@IBOutlet weak var HTTPSSwitchCell: SwitchCell!

	/// A table view cell containing a switch that toggles the exclusion of HTTP requests for "simple" (single-label) hosts from using the HTTP proxy settings.
	@IBOutlet weak var excludeSimpleCell: SwitchCell!

	/// A table view cell that when tapped on allows the user to define patterns for host names that will not use the HTTP proxy settings.
	@IBOutlet weak var exceptionsCell: UITableViewCell!

	/// A table view cell that when tapped on allows the user to define the domains of hosts that will use the HTTP proxy settings.
	@IBOutlet weak var matchDomainsCell: UITableViewCell!

	/// The VPN configuration containing the proxy settings.
	var targetConfiguration = NEVPNProtocol()

	// MARK: UIViewController

	/// Handle the event where the view is loaded into memory.
	override func viewDidLoad() {
		super.viewDidLoad()

		cells = [
			pacSwitchCell,
			HTTPSwitchCell,
			HTTPSSwitchCell,
			excludeSimpleCell,
			exceptionsCell,
			matchDomainsCell
		].flatMap { $0 }

		pacSwitchCell.dependentCells = [ pacURLCell, pacScriptCell ]
		pacSwitchCell.getIndexPath = {
			return self.getIndexPathOfCell(self.pacSwitchCell)
		}
		pacSwitchCell.valueChanged = {
			self.updateCellsWithDependentsOfCell(self.pacSwitchCell)
			self.targetConfiguration.proxySettings?.autoProxyConfigurationEnabled = self.pacSwitchCell.isOn
		}

		pacURLCell.valueChanged = {
			if let enteredText = self.pacURLCell.textField.text {
				self.targetConfiguration.proxySettings?.proxyAutoConfigurationURL = URL(string: enteredText)
			}
			else {
				self.targetConfiguration.proxySettings?.proxyAutoConfigurationURL = nil
			}
		}

		HTTPSwitchCell.dependentCells = [ HTTPCell ]
		HTTPSwitchCell.getIndexPath = {
			return self.getIndexPathOfCell(self.HTTPSwitchCell)
		}
		HTTPSwitchCell.valueChanged = {
			self.updateCellsWithDependentsOfCell(self.HTTPSwitchCell)
			self.targetConfiguration.proxySettings?.httpEnabled = self.HTTPSwitchCell.isOn
		}

		HTTPSSwitchCell.dependentCells = [ HTTPSCell ]
		HTTPSSwitchCell.getIndexPath = {
			return self.getIndexPathOfCell(self.HTTPSSwitchCell)
		}
		HTTPSSwitchCell.valueChanged = {
			self.updateCellsWithDependentsOfCell(self.HTTPSSwitchCell)
			self.targetConfiguration.proxySettings?.httpsEnabled = self.HTTPSSwitchCell.isOn
		}

		excludeSimpleCell.valueChanged = {
			self.targetConfiguration.proxySettings?.excludeSimpleHostnames = self.excludeSimpleCell.isOn
		}
	}

	/// Handle the event when the view is being displayed.
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		tableView.reloadData()

		pacSwitchCell.isOn = targetConfiguration.proxySettings?.autoProxyConfigurationEnabled ?? false
		pacURLCell.textField.text = targetConfiguration.proxySettings?.proxyAutoConfigurationURL?.absoluteString

		if let script = targetConfiguration.proxySettings?.proxyAutoConfigurationJavaScript {
			pacScriptCell.detailTextLabel?.text = script.isEmpty ? "Optional" : "..."
		}
		else {
			pacScriptCell.detailTextLabel?.text = "Optional"
		}

		HTTPSwitchCell.isOn = targetConfiguration.proxySettings?.httpEnabled ?? false
		if let server = targetConfiguration.proxySettings?.httpServer {
			HTTPCell.detailTextLabel?.text = "\(server.address):\(server.port)"
		}
		else {
			HTTPCell.detailTextLabel?.text = nil
		}

		HTTPSSwitchCell.isOn = targetConfiguration.proxySettings?.httpsEnabled ?? false
		if let server = targetConfiguration.proxySettings?.httpsServer {
			HTTPSCell.detailTextLabel?.text = "\(server.address):\(server.port)"
		}
		else {
			HTTPSCell.detailTextLabel?.text = nil
		}

		excludeSimpleCell.isOn = targetConfiguration.proxySettings?.excludeSimpleHostnames ?? false

		exceptionsCell.detailTextLabel?.text = self.getDescriptionForStringList(targetConfiguration.proxySettings?.exceptionList, itemDescription: "exception")

		matchDomainsCell.detailTextLabel?.text = self.getDescriptionForStringList(targetConfiguration.proxySettings?.matchDomains, itemDescription: "domain")
	}

	/// Set up the destination view controller for a segue away from this view controller.
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let identifier = segue.identifier else { return }

		switch identifier {
			case "edit-match-domains":
				// The user tapped on the "match domains" cell.
				guard let stringListController = segue.destination as? StringListController else { break }
				stringListController.setTargetStrings(targetConfiguration.proxySettings?.matchDomains, title: "Proxy Match Domains", addTitle: "Add a match domain...") { newStrings in
					self.targetConfiguration.proxySettings?.matchDomains = newStrings
				}

			case "edit-exceptions":
				// The user tapped on the "exceptions" cell.
				guard let stringListController = segue.destination as? StringListController else { break }
				stringListController.setTargetStrings(targetConfiguration.proxySettings?.exceptionList, title: "Proxy Exception Patterns", addTitle: "Add an exception pattern...") { newStrings in
					self.targetConfiguration.proxySettings?.exceptionList = newStrings
				}

			case "edit-https-proxy-server":
				// The user tapped on the "HTTPS server" cell.
				guard let proxyServerController = segue.destination as? ProxyServerAddEditController else { break }

				proxyServerController.setTargetServer(targetConfiguration.proxySettings?.httpsServer, title: "HTTPS Proxy Server") { newServer in
					self.targetConfiguration.proxySettings?.httpsServer = newServer
				}

			case "edit-http-proxy-server":
				// The user tapped on the "HTTP server" cell.
				guard let proxyServerController = segue.destination as? ProxyServerAddEditController else { break }

				proxyServerController.setTargetServer(targetConfiguration.proxySettings?.httpServer, title: "HTTP Proxy Server") { newServer in
					self.targetConfiguration.proxySettings?.httpServer = newServer
				}

			case "edit-pac-script":
				// The user tapped on the "proxy auto-configuration script" cell.
				guard let pacScriptController = segue.destination as? ProxyAutoConfigScriptController else { break }

				pacScriptController.scriptText?.text = targetConfiguration.proxySettings?.proxyAutoConfigurationJavaScript
				pacScriptController.saveScriptCallback = { newScript in
					if let script = newScript , !script.isEmpty {
						self.targetConfiguration.proxySettings?.proxyAutoConfigurationJavaScript = script
					}
					else {
						self.targetConfiguration.proxySettings?.proxyAutoConfigurationJavaScript = nil
					}
				}

			default:
				break
		}
	}

	// MARK: Interface

	/// Handle an unwind segue back to this view controller.
	@IBAction func handleUnwind(_ sender: UIStoryboardSegue) {
	}
}
