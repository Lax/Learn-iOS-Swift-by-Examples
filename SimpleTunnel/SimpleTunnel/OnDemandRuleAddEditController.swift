/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the OnDemandRuleAddEditController class, which controls a view that is used to create or edit a Connect On Demand rule.
*/

import UIKit
import NetworkExtension

// MARK: Extensions

/// Make NEOnDemandRuleAction convertible to a string
extension NEOnDemandRuleAction: CustomStringConvertible {
	public var description: String {
		switch self {
			case .connect: return "Connect"
			case .disconnect: return "Disconnect"
			case .ignore: return "Maintain"
			case .evaluateConnection: return "Evaluate Connection"
		}
	}
}

/// Make NEOnDemandRuleInterfaceType convertible to a string
extension NEOnDemandRuleInterfaceType: CustomStringConvertible {
	public var description: String {
		switch self {
			case .any: return "Any"
			case .wiFi: return "Wi-Fi"
			case .cellular: return "Cellular"
			default: return ""
		}
	}
}

/// A view controller object containing input fields used to create or edit a Connect On Demand rule.
class OnDemandRuleAddEditController: ConfigurationParametersViewController {

	// MARK: Properties

	/// A table view cell that when tapped allows the user to select the rule action.
	@IBOutlet weak var actionCell: UITableViewCell!

	/// A table view cell that when tapped allows the user to define the DNS Search Domains match condition.
	@IBOutlet weak var DNSSearchDomainsCell: UITableViewCell!

	/// A table view cell that when tapped allows the user to define the DNS Server match condition.
	@IBOutlet weak var DNSServersCell: UITableViewCell!

	/// A table view cell that when tapped allows the user to define the network interface type match condition.
	@IBOutlet weak var interfaceTypeCell: UITableViewCell!

	/// A table view cell that when tapped allows the user to define the SSID match condition.
	@IBOutlet weak var SSIDsCell: UITableViewCell!

	/// A table view cell that when tapped allows the user to define the URL probe match condition.
	@IBOutlet weak var URLProbeCell: TextFieldCell!

	/// A table view cell that when tapped allows the user to define the connection match rules.
	@IBOutlet weak var connectionRulesCell: UITableViewCell!

	/// The Connect On Demand rule being added or edited.
	var targetRule: NEOnDemandRule = NEOnDemandRuleEvaluateConnection()

	/// The block to execute when the user finishes editing the rule.
	var addRuleHandler: (NEOnDemandRule) -> Void = { rule in return }

	// MARK: UIViewController

	/// Handle the event when the view is loaded into memory.
	override func viewDidLoad() {
		super.viewDidLoad()

		// Set up the table cells.

		cells = [
			actionCell,
			DNSSearchDomainsCell,
			DNSServersCell,
			interfaceTypeCell,
			SSIDsCell,
			URLProbeCell
		].flatMap { $0 }

		URLProbeCell.valueChanged = {
			if let enteredText = self.URLProbeCell.textField.text {
				self.targetRule.probeURL = URL(string: enteredText)
			}
			else {
				self.targetRule.probeURL = nil
			}
		}
	}

	/// Handle the event when the view is being displayed.
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		tableView.reloadData()

		// Set the cell contents per the current rule settings.

		updateConnectionRulesCell()

		actionCell.detailTextLabel?.text = targetRule.action.description

		DNSSearchDomainsCell.detailTextLabel?.text = getDescriptionForStringList(targetRule.dnsSearchDomainMatch, itemDescription: "domain")

		DNSServersCell.detailTextLabel?.text = getDescriptionForStringList(targetRule.dnsServerAddressMatch, itemDescription: "server")

		interfaceTypeCell.detailTextLabel?.text = targetRule.interfaceTypeMatch.description

		SSIDsCell.detailTextLabel?.text = getDescriptionForStringList(targetRule.ssidMatch, itemDescription: "SSID")

		if let evaluateRule = targetRule as? NEOnDemandRuleEvaluateConnection {
			connectionRulesCell.detailTextLabel?.text = getDescriptionForListValue(evaluateRule.connectionRules, itemDescription: "rule", placeHolder: "Required")
		}

		URLProbeCell.textField.text = targetRule.probeURL?.absoluteString ?? nil
	}

	/// Set up the destination view controller of a segue away from this view controller.
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let identifier = segue.identifier else { return }

		switch identifier {
			case "edit-ssids":
				// The user tapped on the SSIDs cell.
				guard let stringListController = segue.destination as? StringListController else { break }

				stringListController.setTargetStrings(targetRule.ssidMatch, title: "Match SSIDs", addTitle: "Add a SSID...") { newSSIDs in
					self.targetRule.ssidMatch = newSSIDs
				}

			case "edit-interface-type-match":
				// The user tapped on the Interface Type cell.
				guard let enumController = segue.destination as? EnumPickerController else { break }

				let enumValues: [NEOnDemandRuleInterfaceType] = [ .any, .wiFi, .cellular ],
					stringValues = enumValues.flatMap { $0.description },
					currentSelection = enumValues.index { $0 == targetRule.interfaceTypeMatch }

				enumController.setValues(stringValues, title: "Interface Type", currentSelection: currentSelection) { newRow in
					self.targetRule.interfaceTypeMatch = enumValues[newRow]
				}

			case "edit-dns-servers":
				// The user tapped on the DNS Servers cell.
				guard let stringListController = segue.destination as? StringListController else { break }

				stringListController.setTargetStrings(targetRule.dnsServerAddressMatch, title: "Match DNS Servers", addTitle: "Add a server address...") { newAddresses in
					self.targetRule.dnsServerAddressMatch = newAddresses
				}

			case "edit-dns-search-domains":
				// The user tapped on the DNS Search Domains cell.
				guard let stringListController = segue.destination as? StringListController else { break }

				stringListController.setTargetStrings(targetRule.dnsSearchDomainMatch, title: "Match DNS Search Domains", addTitle: "Add a search domain...") { newStrings in
					self.targetRule.dnsSearchDomainMatch = newStrings
				}

			case "edit-on-demand-action":
				// The user tapped on the Action cell.
				guard let enumController = segue.destination as? EnumPickerController else { break }

				let enumValues: [NEOnDemandRuleAction] = [ .evaluateConnection, .disconnect, .connect, .ignore ],
					stringValues = enumValues.flatMap { $0.description },
					currentSelection = enumValues.index { $0 == targetRule.action }

				enumController.setValues(stringValues, title: "Action", currentSelection: currentSelection) { newRow in
					self.changeTargetRuleType(enumValues[newRow])
				}

			case "edit-connection-rules":
				// The user tapped on the Connection Rules cell.
				guard let connRuleListController = segue.destination as? ConnectionRuleListController,
					let rule = targetRule as? NEOnDemandRuleEvaluateConnection
					else { break }

				if rule.connectionRules == nil {
					rule.connectionRules = []
				}

				connRuleListController.targetRule = rule

			default:
				break
		}
	}

	/// Set the target rule to add or edit, the title of the view, and the block to execute when the user is finished editing the rule.
	func setTargetRule(_ rule: NEOnDemandRule?, title: String, saveRuleHandler: @escaping (NEOnDemandRule) -> Void) {
		if let newRule = rule {
			// Edit a copy of the given rule.
			targetRule = newRule.copy() as! NEOnDemandRule
		} else {
			targetRule = NEOnDemandRuleEvaluateConnection()
		}
		navigationItem.title = title
		addRuleHandler = saveRuleHandler
	}

	/// Set the target rule to a new rule with all the same match conditions as the current target rule, but with a different action.
	func changeTargetRuleType(_ newAction: NEOnDemandRuleAction) {
		guard targetRule.action != newAction else { return }
		let newRule: NEOnDemandRule

		switch newAction {
			case .evaluateConnection:
				newRule = NEOnDemandRuleEvaluateConnection()

			case .connect:
				newRule = NEOnDemandRuleConnect()

			case .disconnect:
				newRule = NEOnDemandRuleDisconnect()

			case .ignore:
				newRule = NEOnDemandRuleIgnore()
		}

		newRule.dnsSearchDomainMatch = targetRule.dnsSearchDomainMatch
		newRule.dnsServerAddressMatch = targetRule.dnsServerAddressMatch
		newRule.interfaceTypeMatch = targetRule.interfaceTypeMatch
		newRule.ssidMatch = targetRule.ssidMatch
		newRule.probeURL = targetRule.probeURL

		targetRule = newRule

		updateConnectionRulesCell()
	}

	/// Show or hide the connection rules cell based on the action of the target rule.
	func updateConnectionRulesCell() {
		guard let actionIndexPath = self.getIndexPathOfCell(actionCell) else { return }

		if let rulesIndexPath = self.getIndexPathOfCell(connectionRulesCell) {
			// The connection rules cell is being displayed. If the action is not "Evaluate Connection", then remove the connection rules cell.
			if targetRule.action != .evaluateConnection {
				cells.remove(at: (rulesIndexPath as NSIndexPath).row)
				self.tableView.deleteRows(at: [ rulesIndexPath ], with: .bottom)
			}
		} else {
			// The connection rules cell is not being displayed. If the action is "Evaluate Connection", then insert the connection rules cell.
			if targetRule.action == .evaluateConnection {
				cells.insert(connectionRulesCell, at: (actionIndexPath as NSIndexPath).row + 1)
				let indexPaths = [ IndexPath(row: (actionIndexPath as NSIndexPath).row + 1, section: (actionIndexPath as NSIndexPath).section) ]
				self.tableView.insertRows(at: indexPaths, with: .bottom)
			}
		}
	}

	/// Handle the user tapping on the "Done" button.
	@IBAction func saveTargetRule(_ sender: AnyObject) {
		addRuleHandler(targetRule)

		// Transition back to the Connect On Demand rule list view.
		self.performSegue(withIdentifier: "save-on-demand-rule", sender: sender)
	}
}
