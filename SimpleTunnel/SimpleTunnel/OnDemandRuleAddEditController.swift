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
			case .Connect: return "Connect"
			case .Disconnect: return "Disconnect"
			case .Ignore: return "Maintain"
			case .EvaluateConnection: return "Evaluate Connection"
		}
	}
}

/// Make NEOnDemandRuleInterfaceType convertible to a string
extension NEOnDemandRuleInterfaceType: CustomStringConvertible {
	public var description: String {
		switch self {
			case .Any: return "Any"
			case .WiFi: return "Wi-Fi"
			case .Cellular: return "Cellular"
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
	var addRuleHandler: NEOnDemandRule -> Void = { rule in return }

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
				self.targetRule.probeURL = NSURL(string: enteredText)
			}
			else {
				self.targetRule.probeURL = nil
			}
		}
	}

	/// Handle the event when the view is being displayed.
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		tableView.reloadData()

		// Set the cell contents per the current rule settings.

		updateConnectionRulesCell()

		actionCell.detailTextLabel?.text = targetRule.action.description

		DNSSearchDomainsCell.detailTextLabel?.text = getDescriptionForStringList(targetRule.DNSSearchDomainMatch, itemDescription: "domain")

		DNSServersCell.detailTextLabel?.text = getDescriptionForStringList(targetRule.DNSServerAddressMatch, itemDescription: "server")

		interfaceTypeCell.detailTextLabel?.text = targetRule.interfaceTypeMatch.description

		SSIDsCell.detailTextLabel?.text = getDescriptionForStringList(targetRule.SSIDMatch, itemDescription: "SSID")

		if let evaluateRule = targetRule as? NEOnDemandRuleEvaluateConnection {
			connectionRulesCell.detailTextLabel?.text = getDescriptionForListValue(evaluateRule.connectionRules, itemDescription: "rule", placeHolder: "Required")
		}

		URLProbeCell.textField.text = targetRule.probeURL?.absoluteString ?? nil
	}

	/// Set up the destination view controller of a segue away from this view controller.
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		guard let identifier = segue.identifier else { return }

		switch identifier {
			case "edit-ssids":
				// The user tapped on the SSIDs cell.
				guard let stringListController = segue.destinationViewController as? StringListController else { break }

				stringListController.setTargetStrings(targetRule.SSIDMatch, title: "Match SSIDs", addTitle: "Add a SSID...") { newSSIDs in
					self.targetRule.SSIDMatch = newSSIDs
				}

			case "edit-interface-type-match":
				// The user tapped on the Interface Type cell.
				guard let enumController = segue.destinationViewController as? EnumPickerController else { break }

				let enumValues: [NEOnDemandRuleInterfaceType] = [ .Any, .WiFi, .Cellular ],
					stringValues = enumValues.flatMap { $0.description },
					currentSelection = enumValues.indexOf { $0 == targetRule.interfaceTypeMatch }

				enumController.setValues(stringValues, title: "Interface Type", currentSelection: currentSelection) { newRow in
					self.targetRule.interfaceTypeMatch = enumValues[newRow]
				}

			case "edit-dns-servers":
				// The user tapped on the DNS Servers cell.
				guard let stringListController = segue.destinationViewController as? StringListController else { break }

				stringListController.setTargetStrings(targetRule.DNSServerAddressMatch, title: "Match DNS Servers", addTitle: "Add a server address...") { newAddresses in
					self.targetRule.DNSServerAddressMatch = newAddresses
				}

			case "edit-dns-search-domains":
				// The user tapped on the DNS Search Domains cell.
				guard let stringListController = segue.destinationViewController as? StringListController else { break }

				stringListController.setTargetStrings(targetRule.DNSSearchDomainMatch, title: "Match DNS Search Domains", addTitle: "Add a search domain...") { newStrings in
					self.targetRule.DNSSearchDomainMatch = newStrings
				}

			case "edit-on-demand-action":
				// The user tapped on the Action cell.
				guard let enumController = segue.destinationViewController as? EnumPickerController else { break }

				let enumValues: [NEOnDemandRuleAction] = [ .EvaluateConnection, .Disconnect, .Connect, .Ignore ],
					stringValues = enumValues.flatMap { $0.description },
					currentSelection = enumValues.indexOf { $0 == targetRule.action }

				enumController.setValues(stringValues, title: "Action", currentSelection: currentSelection) { newRow in
					self.changeTargetRuleType(enumValues[newRow])
				}

			case "edit-connection-rules":
				// The user tapped on the Connection Rules cell.
				guard let connRuleListController = segue.destinationViewController as? ConnectionRuleListController,
					rule = targetRule as? NEOnDemandRuleEvaluateConnection
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
	func setTargetRule(rule: NEOnDemandRule?, title: String, saveRuleHandler: (NEOnDemandRule) -> Void) {
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
	func changeTargetRuleType(newAction: NEOnDemandRuleAction) {
		guard targetRule.action != newAction else { return }
		let newRule: NEOnDemandRule

		switch newAction {
			case .EvaluateConnection:
				newRule = NEOnDemandRuleEvaluateConnection()

			case .Connect:
				newRule = NEOnDemandRuleConnect()

			case .Disconnect:
				newRule = NEOnDemandRuleDisconnect()

			case .Ignore:
				newRule = NEOnDemandRuleIgnore()
		}

		newRule.DNSSearchDomainMatch = targetRule.DNSSearchDomainMatch
		newRule.DNSServerAddressMatch = targetRule.DNSServerAddressMatch
		newRule.interfaceTypeMatch = targetRule.interfaceTypeMatch
		newRule.SSIDMatch = targetRule.SSIDMatch
		newRule.probeURL = targetRule.probeURL

		targetRule = newRule

		updateConnectionRulesCell()
	}

	/// Show or hide the connection rules cell based on the action of the target rule.
	func updateConnectionRulesCell() {
		guard let actionIndexPath = self.getIndexPathOfCell(actionCell) else { return }

		if let rulesIndexPath = self.getIndexPathOfCell(connectionRulesCell) {
			// The connection rules cell is being displayed. If the action is not "Evaluate Connection", then remove the connection rules cell.
			if targetRule.action != .EvaluateConnection {
				cells.removeAtIndex(rulesIndexPath.row)
				self.tableView.deleteRowsAtIndexPaths([ rulesIndexPath ], withRowAnimation: .Bottom)
			}
		} else {
			// The connection rules cell is not being displayed. If the action is "Evaluate Connection", then insert the connection rules cell.
			if targetRule.action == .EvaluateConnection {
				cells.insert(connectionRulesCell, atIndex: actionIndexPath.row + 1)
				let indexPaths = [ NSIndexPath(forRow: actionIndexPath.row + 1, inSection: actionIndexPath.section) ]
				self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Bottom)
			}
		}
	}

	/// Handle the user tapping on the "Done" button.
	@IBAction func saveTargetRule(sender: AnyObject) {
		addRuleHandler(targetRule)

		// Transition back to the Connect On Demand rule list view.
		self.performSegueWithIdentifier("save-on-demand-rule", sender: sender)
	}
}
