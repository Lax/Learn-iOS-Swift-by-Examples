/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the ConnectionRuleListController class, which controls a list of Connect On Demand connection rules.
*/

import UIKit
import NetworkExtension

/// A view controller object for a view that displays a editable list of Evaluate Connection rules.
class ConnectionRuleListController: ListViewController {

	// MARK: Properties

	/// The Connect On Demand rule containing the connection rules being displayed.
	var targetRule = NEOnDemandRuleEvaluateConnection()

	/// The number of connection rules.
	override var listCount: Int {
		return targetRule.connectionRules?.count ?? 0
	}

	/// Returns UITableViewCellAccessoryType.DetailButton.
	override var listAccessoryType: UITableViewCellAccessoryType {
		return .detailButton
	}

	/// Returns UITableViewCellAccessoryType.DetailButton.
	override var listEditingAccessoryType: UITableViewCellAccessoryType {
		return .detailButton
	}

	/// The text to display in the "add a new item" table cell.
	override var listAddButtonText: String {
		return "Add Connection Rule..."
	}

	// MARK: UIViewController

	/// Handle the event where the view is loaded into memory.
	override func viewDidLoad() {
		isAddEnabled = true
		isAlwaysEditing = true
		super.viewDidLoad()
	}

	// MARK: ListViewController

	/// Set up the destination view controller for a segue triggered by the user tapping on a cell.
	override func listSetupSegue(_ segue: UIStoryboardSegue, forItemAtIndex index: Int) {
		guard let identifier = segue.identifier,
			let ruleAddEditController = segue.destination as? ConnectionRuleAddEditController
			else { return }

		switch identifier {
			case "edit-connection-rule":
				// The user tapped on a rule in the connection rule list.
				guard let connectionRule = targetRule.connectionRules?[index] else { break }
				ruleAddEditController.setTargetRule(connectionRule, title: "Connection Rule") { newRule in
					self.targetRule.connectionRules?[index] = newRule
				}

			case "add-connection-rule":
				// The user tapped on the "add a new rule" cell.
				ruleAddEditController.setTargetRule(nil, title: "Add Connection Rule") { newRule in
					self.targetRule.connectionRules?.append(newRule)
				}

			default:
				break
		}
	}

	/// Return the description of the rule at the given index in the list.
	override func listTextForItemAtIndex(_ index: Int) -> String {
		return targetRule.connectionRules?[index].action.description ?? ""
	}

	/// Remove the rule at the given index in the list.
	override func listRemoveItemAtIndex(_ index: Int) {
		targetRule.connectionRules?.remove(at: index)
	}

	// MARK: Interface

	/// Handle an unwind segue back to this view controller.
	@IBAction func handleUnwind(_ sender: UIStoryboardSegue) {
	}
}
