/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the ContentFilterController class, which controls a view used to start and stop a content filter, and display current filtering rules.
*/

import UIKit
import NetworkExtension
import SimpleTunnelServices

/// A view controller object for a view that displays Content Filter configuration and rules.
class ContentFilterController: UITableViewController {

	// MARK: Properties

	/// A table view cell that contains the status of the filter.
	@IBOutlet weak var statusCell: SwitchCell!

	/// A table view cell that contains the 
	@IBOutlet weak var rulesServerCell: TextFieldCell!

	/// A variable to pass as the context to addObserver()
	var rulesContext = 0

	/// The current list of filtering rules
	var currentRules = [(String, String)]()

	// MARK: Initializers

	deinit {
		var context = self
		FilterUtilities.defaults?.removeObserver(self, forKeyPath: "rules", context:&context)
	}

	// MARK: UIViewController

	/// Handle the event where the view is loaded into memory.
	override func viewDidLoad() {
		FilterUtilities.defaults?.addObserver(self, forKeyPath: "rules", options: NSKeyValueObservingOptions.Initial, context:&rulesContext)

		statusCell.valueChanged = {
			if self.statusCell.isOn && NEFilterManager.sharedManager().providerConfiguration == nil {
				let newConfiguration = NEFilterProviderConfiguration()
				newConfiguration.username = "TestUser"
				newConfiguration.organization = "Acme Inc."
				newConfiguration.filterBrowsers = true
				newConfiguration.filterSockets = true
				newConfiguration.serverAddress = self.rulesServerCell.textField.text ?? "my.great.filter.server"
				NEFilterManager.sharedManager().providerConfiguration = newConfiguration
			}
			NEFilterManager.sharedManager().enabled = self.statusCell.isOn
			NEFilterManager.sharedManager().saveToPreferencesWithCompletionHandler { error in
				if let saveError = error {
					simpleTunnelLog("Failed to save the filter configuration: \(saveError)")
					self.statusCell.isOn = false
					return
				}
				self.rulesServerCell.textField.text = NEFilterManager.sharedManager().providerConfiguration?.serverAddress
				FilterUtilities.defaults?.setValue(NEFilterManager.sharedManager().providerConfiguration?.serverAddress, forKey: "serverAddress")
			}
		}

		rulesServerCell.valueChanged = {
			guard let serverIPAddress = self.rulesServerCell.textField.text where !serverIPAddress.isEmpty else { return }

			NEFilterManager.sharedManager().providerConfiguration?.serverAddress = serverIPAddress
			NEFilterManager.sharedManager().saveToPreferencesWithCompletionHandler { error in
				if let saveError = error {
					simpleTunnelLog("Failed to save the filter configuration: \(saveError)")
					return
				}

				FilterUtilities.defaults?.setValue(serverIPAddress, forKey: "serverAddress")
			}
		}
	}

	/// Handle the event where the view is loaded into memory.
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		NEFilterManager.sharedManager().loadFromPreferencesWithCompletionHandler { error in
			if let loadError = error {
				simpleTunnelLog("Failed to load the filter configuration: \(loadError)")
				self.statusCell.isOn = false
				return
			}

			self.statusCell.isOn = NEFilterManager.sharedManager().enabled
			self.rulesServerCell.textField.text = NEFilterManager.sharedManager().providerConfiguration?.serverAddress

			self.reloadRules()
		}
	}

	// MARK: NSObject

	/// Handle changes to the rules
	override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		if context == &rulesContext && keyPath == "rules" {
			reloadRules()
		} else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
		}
	}

	// MARK: UITableViewDataSource

	/// Return the number of sections to display.
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return !currentRules.isEmpty ? 2 : 1
	}

	/// Return the number of rows in a section.
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
			case 0: return 2
			case 1: return currentRules.count
			default: return 0
		}
	}

	/// Return the cell for given index path.
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		if indexPath.section == 0 {
			return indexPath.row == 0 ? statusCell : rulesServerCell
		}
		else if let cell = tableView.dequeueReusableCellWithIdentifier("rule-cell") {
			let (hostString, actionString) = currentRules[indexPath.row]
			cell.textLabel?.text = hostString
			cell.detailTextLabel?.text = actionString
			return cell
		}
		else {
			return UITableViewCell()
		}
	}

	/// Return the title for a section in the table.
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return section == 1 ? "Current Rules" : nil
	}

	// MARK: Interface

	/// Re-load the current filerting rules from the defaults.
	func reloadRules() {
		currentRules = [(String, String)]()

		guard let rules = FilterUtilities.defaults?.objectForKey("rules") as? [String : [String : AnyObject]] else { return }

		for (hostname, ruleInfo) in rules {
			guard let ruleActionNum = ruleInfo["kRule"] as? Int,
				ruleAction = FilterRuleAction(rawValue: ruleActionNum)
				else { continue }

			currentRules.append((hostname as String, ruleAction.description))
		}
		tableView.reloadData()
	}

	/// Download a new set of filtering rules from the server.
	@IBAction func fetchRulesButtonTouchUpInside(sender: UIButton) {
		FilterUtilities.fetchRulesFromServer(NEFilterManager.sharedManager().providerConfiguration?.serverAddress)
		reloadRules()
	}

}
