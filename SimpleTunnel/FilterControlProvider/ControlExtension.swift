/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the ControlExtension class. The ControlExtension class is a sub-class of NEFilterControlProvider, and is responsible for downloading content filter rules from a web service.
*/

import NetworkExtension
import Foundation
import SimpleTunnelServices

/// A NEFitlerControlProvider sub-class that implements logic for downloading rules from a web server.
class ControlExtension : NEFilterControlProvider {

	// MARK: Properties

	/// The default rules, in the event that 
	let defaultRules: [String: [String: AnyObject]] = [
		"www.apple.com" : [
			"kRule" : FilterRuleAction.Block.rawValue,
			"kRemediationKey" : "Remediate1"
		]
	]

	/// An integer to use as the context for key-value observing.
	var observerContext = 0

	// MARK: Interface

	/// Update the filter based on changes to the configuration
	func updateFromConfiguration() {
		guard let serverAddress = filterConfiguration.serverAddress else { return }

		FilterUtilities.defaults?.setValue(defaultRules, forKey: "rules")
		FilterUtilities.fetchRulesFromServer(filterConfiguration.serverAddress)

		let remediationURL = "https://\(serverAddress)/remediate/?url=\(NEFilterProviderRemediationURLFlowURLHostname)&organization=\(NEFilterProviderRemediationURLOrganization)&username=\(NEFilterProviderRemediationURLUsername)"

		simpleTunnelLog("Remediation url is \(remediationURL)")

		remediationMap =
			[
				NEFilterProviderRemediationMapRemediationURLs : [ "Remediate1" : remediationURL ],
				NEFilterProviderRemediationMapRemediationButtonTexts :
					[
						"RemediateButton1" : "Request Access",
						"RemediateButton2" : "\"<script>alert('wooo hoooooo');</script>",
						"RemediateButton3" : "Request Access 3",
				]
			]

		self.URLAppendStringMap = [ "SafeYes" : "safe=yes", "Adult" : "adult=yes"]

		simpleTunnelLog("Remediation map set")
	}

	// MARK: Initializers

	override init() {
		super.init()
		updateFromConfiguration()

		FilterUtilities.defaults?.setValue(defaultRules, forKey: "rules")
		FilterUtilities.fetchRulesFromServer(self.filterConfiguration.serverAddress)

		self.addObserver(self, forKeyPath: "filterConfiguration", options: [.Initial, .New], context: &observerContext)
	}

	// MARK: NSObject

	/// Observe changes to the configuration.
	override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		if keyPath == "filterConfiguration" && context == &observerContext {
			simpleTunnelLog("configuration changed")
			updateFromConfiguration()
		} else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
		}
	}

	// MARK: NEFilterControlProvider

	/// Handle a new flow of network data
	override func handleNewFlow(flow: NEFilterFlow, completionHandler: (NEFilterControlVerdict) -> Void) {
		simpleTunnelLog("Handle new flow called")
		var controlVerdict = NEFilterControlVerdict.updateRules()
		let (ruleType, hostname, _) = FilterUtilities.getRule(flow)

		switch ruleType {
			case .NeedMoreRulesAndAllow:
				simpleTunnelLog("\(hostname) is set to be Allowed")
				controlVerdict = NEFilterControlVerdict.allowVerdictWithUpdateRules(false)

			case .NeedMoreRulesAndBlock:
				simpleTunnelLog("\(hostname) is set to be blocked")
				controlVerdict = NEFilterControlVerdict.dropVerdictWithUpdateRules(false)
			
			default:
				simpleTunnelLog("\(hostname) is not set for need more rules")
		}

		completionHandler(controlVerdict)
	}
}
