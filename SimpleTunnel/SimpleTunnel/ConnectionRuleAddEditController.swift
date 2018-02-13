/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the ConnectionRuleAddEditController class, which controls a view that is used to add or edit a Connect On Demand connection rule.
*/

import UIKit
import NetworkExtension

// MARK: Extensions

/// Make NEEvaluateConnectionRuleAction convertible to a string.
extension NEEvaluateConnectionRuleAction: CustomStringConvertible {
	public var description: String {
		switch self {
			case .connectIfNeeded: return "Connect If Needed"
			case .neverConnect: return "Never Connect"
		}
	}
}

/// A view controller object for a view that contains input fields used to define a Evaluate Connection rule.
class ConnectionRuleAddEditController: ConfigurationParametersViewController {

	// MARK: Properties

	/// A table cell that when tapped allows the user to select the action for the rule.
	@IBOutlet weak var actionCell: UITableViewCell!

	/// A table cell that when tapped allows the user to set the DNS Domains match condition for the rule.
	@IBOutlet weak var domainsCell: UITableViewCell!

	/// A table cell that when tapped allows the user to set the DNS Servers to be used when the rule matches.
	@IBOutlet weak var requiredDNSCell: UITableViewCell!

	/// A table cell that contains a text field where the user inputs the rule's probe URL.
	@IBOutlet weak var requiredURLProbeCell: TextFieldCell!

	/// The connection rule being edited or added.
	var targetRule = NEEvaluateConnectionRule(matchDomains: [], andAction: .connectIfNeeded)

	/// A block to execute when the user is finished editing the connection rule.
	var addRuleHandler: (NEEvaluateConnectionRule) -> Void = { rule in return }

	// MARK: UIViewController

	/// Handle the event when the view is loaded into memory.
	override func viewDidLoad() {
		super.viewDidLoad()

		cells = [
			actionCell,
			domainsCell,
			requiredDNSCell,
			requiredURLProbeCell
		].flatMap { $0 }

		requiredURLProbeCell.valueChanged = {
			if let enteredText = self.requiredURLProbeCell.textField.text {
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

		actionCell.detailTextLabel?.text = targetRule.action.description

		domainsCell.detailTextLabel?.text = getDescriptionForStringList(targetRule.matchDomains, itemDescription: "domain", placeHolder: "Required")

		requiredDNSCell.detailTextLabel?.text = getDescriptionForStringList(targetRule.useDNSServers, itemDescription: "server")

		requiredURLProbeCell.textField.text = targetRule.probeURL?.absoluteString ?? nil
	}

	/// Set up the destination view controller for a segue away from this view controller.
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let identifier = segue.identifier else { return }

		switch identifier {
			case "edit-use-dns-servers":
				// The user tapped on the Use DNS Servers table cell.
				guard let stringListController = segue.destination as? StringListController else { break }

				stringListController.setTargetStrings(targetRule.useDNSServers, title: "Use DNS Servers", addTitle: "Add a server address...") { newAddresses in
					self.targetRule.useDNSServers = newAddresses
				}

			case "edit-connection-rule-action":
				// The user tapped on the Action table cell.
				guard let enumController = segue.destination as? EnumPickerController else { break }

				let enumValues: [NEEvaluateConnectionRuleAction] = [ .connectIfNeeded, .neverConnect, ],
					stringValues = enumValues.flatMap { $0.description },
					currentSelection = enumValues.index { $0 == targetRule.action }

				enumController.setValues(stringValues, title: "Action", currentSelection: currentSelection) { newRow in
					let newAction = enumValues[newRow]
					guard self.targetRule.action != newAction else { return }

					let newRule = NEEvaluateConnectionRule(matchDomains: self.targetRule.matchDomains, andAction: newAction)
					newRule.useDNSServers = self.targetRule.useDNSServers
					newRule.probeURL = self.targetRule.probeURL

					self.targetRule = newRule
				}

			case "edit-connection-rule-match-domains":
				// The user tapped on the Match Domains table cell.
				guard let stringListController = segue.destination as? StringListController else { break }

				stringListController.setTargetStrings(targetRule.matchDomains, title: "Match Domains", addTitle: "Add a domain...") { newStrings in
					let newRule = NEEvaluateConnectionRule(matchDomains: newStrings, andAction: self.targetRule.action)
					newRule.useDNSServers = self.targetRule.useDNSServers
					newRule.probeURL = self.targetRule.probeURL
					self.targetRule = newRule
				}

			default:
				break
		}
	}

	// MARK: Interface

	/// Set the target connection rule, the title of the view, and the block to execute when the user if finished editing the rule.
	func setTargetRule(_ rule: NEEvaluateConnectionRule?, title: String, saveHandler: @escaping (NEEvaluateConnectionRule) -> Void) {
		if let newRule = rule {
			targetRule = newRule
		} else {
			targetRule = NEEvaluateConnectionRule(matchDomains: [], andAction: .connectIfNeeded)
		}
		navigationItem.title = title
		addRuleHandler = saveHandler
	}

	/// Handle the user tapping on the "Done" button.
	@IBAction func saveTargetRule(_ sender: AnyObject) {
		addRuleHandler(targetRule)
		performSegue(withIdentifier: "save-connection-rule", sender: sender)
	}
}
