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
		FilterUtilities.defaults?.addObserver(self, forKeyPath: "rules", options: NSKeyValueObservingOptions.initial, context:&rulesContext)

		statusCell.valueChanged = {
			if self.statusCell.isOn && NEFilterManager.shared().providerConfiguration == nil {
				let newConfiguration = NEFilterProviderConfiguration()
				newConfiguration.username = "TestUser"
				newConfiguration.organization = "Acme Inc."
				newConfiguration.filterBrowsers = true
				newConfiguration.filterSockets = true
				newConfiguration.serverAddress = self.rulesServerCell.textField.text ?? "my.great.filter.server"
				NEFilterManager.shared().providerConfiguration = newConfiguration
			}
			NEFilterManager.shared().isEnabled = self.statusCell.isOn
			NEFilterManager.shared().saveToPreferences { error in
				if let saveError = error {
					simpleTunnelLog("Failed to save the filter configuration: \(saveError)")
					self.statusCell.isOn = false
					return
				}
				self.rulesServerCell.textField.text = NEFilterManager.shared().providerConfiguration?.serverAddress
				FilterUtilities.defaults?.setValue(NEFilterManager.shared().providerConfiguration?.serverAddress, forKey: "serverAddress")
			}
		}

		rulesServerCell.valueChanged = {
			guard let serverIPAddress = self.rulesServerCell.textField.text , !serverIPAddress.isEmpty else { return }

			NEFilterManager.shared().providerConfiguration?.serverAddress = serverIPAddress
			NEFilterManager.shared().saveToPreferences { error in
				if let saveError = error {
					simpleTunnelLog("Failed to save the filter configuration: \(saveError)")
					return
				}

				FilterUtilities.defaults?.setValue(serverIPAddress, forKey: "serverAddress")
			}
		}
	}

	/// Handle the event where the view is loaded into memory.
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		NEFilterManager.shared().loadFromPreferences { error in
			if let loadError = error {
				simpleTunnelLog("Failed to load the filter configuration: \(loadError)")
				self.statusCell.isOn = false
				return
			}

			self.statusCell.isOn = NEFilterManager.shared().isEnabled
			self.rulesServerCell.textField.text = NEFilterManager.shared().providerConfiguration?.serverAddress

			self.reloadRules()
		}
	}

	// MARK: NSObject

	/// Handle changes to the rules
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if context == &rulesContext && keyPath == "rules" {
			reloadRules()
		} else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}

	// MARK: UITableViewDataSource

	/// Return the number of sections to display.
	override func numberOfSections(in tableView: UITableView) -> Int {
		return !currentRules.isEmpty ? 2 : 1
	}

	/// Return the number of rows in a section.
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
			case 0: return 2
			case 1: return currentRules.count
			default: return 0
		}
	}

	/// Return the cell for given index path.
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if (indexPath as NSIndexPath).section == 0 {
			return (indexPath as NSIndexPath).row == 0 ? statusCell : rulesServerCell
		}
		else if let cell = tableView.dequeueReusableCell(withIdentifier: "rule-cell") {
			let (hostString, actionString) = currentRules[(indexPath as NSIndexPath).row]
			cell.textLabel?.text = hostString
			cell.detailTextLabel?.text = actionString
			return cell
		}
		else {
			return UITableViewCell()
		}
	}

	/// Return the title for a section in the table.
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return section == 1 ? "Current Rules" : nil
	}

	// MARK: Interface

	/// Re-load the current filerting rules from the defaults.
	func reloadRules() {
		currentRules = [(String, String)]()

		guard let rules = FilterUtilities.defaults?.object(forKey: "rules") as? [String : [String : AnyObject]] else { return }

		for (hostname, ruleInfo) in rules {
			guard let ruleActionNum = ruleInfo["kRule"] as? Int,
				let ruleAction = FilterRuleAction(rawValue: ruleActionNum)
				else { continue }

			currentRules.append((hostname as String, ruleAction.description))
		}
		tableView.reloadData()
	}

	/// Download a new set of filtering rules from the server.
	@IBAction func fetchRulesButtonTouchUpInside(_ sender: UIButton) {
		FilterUtilities.fetchRulesFromServer(NEFilterManager.shared().providerConfiguration?.serverAddress)
		reloadRules()
	}

}
