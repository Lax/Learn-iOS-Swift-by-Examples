/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the FilterUtilities class. FilterUtilities objects contain functions and data that is used by both the SimpleTunnel UI and the SimpleTunnel content filter providers.
*/

import Foundation
import NetworkExtension

/// Content Filter actions.
public enum FilterRuleAction : Int, CustomStringConvertible {
	case Block = 1
	case Allow = 2
	case NeedMoreRulesAndBlock = 3
	case NeedMoreRulesAndAllow = 4
	case NeedMoreRulesFromDataAndBlock = 5
	case NeedMoreRulesFromDataAndAllow = 6
	case ExamineData = 7
	case RedirectToSafeURL = 8
	case Remediate = 9

	public var description: String {
		switch self {
		case .Block: return "Block"
		case .ExamineData: return "Examine Data"
		case .NeedMoreRulesAndAllow: return "Ask for more rules, then allow"
		case .NeedMoreRulesAndBlock: return "Ask for more rules, then block"
		case .NeedMoreRulesFromDataAndAllow: return "Ask for more rules, examine data, then allow"
		case .NeedMoreRulesFromDataAndBlock: return "Ask for more rules, examine data, then block"
		case .RedirectToSafeURL: return "Redirect"
		case .Remediate: return "Remediate"
		case .Allow: return "Allow"
		}
	}
}

/// A class containing utility properties and functions for Content Filtering.
public class FilterUtilities {

	// MARK: Properties

	/// A reference to the SimpleTunnel user defaults.
	public static let defaults = NSUserDefaults(suiteName: "group.com.example.apple-samplecode.SimpleTunnel")

	// MARK: Initializers

	/// Get rule parameters for a flow from the SimpleTunnel user defaults.
	public class func getRule(flow: NEFilterFlow) -> (FilterRuleAction, String, [String: AnyObject]) {
		let hostname = FilterUtilities.getFlowHostname(flow)

		guard !hostname.isEmpty else { return (.Allow, hostname, [:]) }

		guard let hostNameRule = defaults?.objectForKey("rules")?.objectForKey(hostname) as? [String: AnyObject] else {
			simpleTunnelLog("\(hostname) is set for NO RULES")
			return (.Allow, hostname, [:])
		}

		guard let ruleTypeInt = hostNameRule["kRule"] as? Int,
			ruleType = FilterRuleAction(rawValue: ruleTypeInt)
			else { return (.Allow, hostname, [:]) }

		return (ruleType, hostname, hostNameRule)
	}

	/// Get the hostname from a browser flow.
	public class func getFlowHostname(flow: NEFilterFlow) -> String {
		guard let browserFlow : NEFilterBrowserFlow = flow as? NEFilterBrowserFlow,
			url = browserFlow.URL,
			hostname = url.host
			where flow is NEFilterBrowserFlow
			else { return "" }
		return hostname
	}

	/// Download a fresh set of rules from the rules server.
	public class func fetchRulesFromServer(serverAddress: String?) {
		simpleTunnelLog("fetch rules called")

		guard serverAddress != nil else { return }
		simpleTunnelLog("Fetching rules from \(serverAddress)")

		guard let infoURL = NSURL(string: "http://\(serverAddress!)/rules/") else { return }
		simpleTunnelLog("Rules url is \(infoURL)")

		let content: String
		do {
			content = try String(contentsOfURL: infoURL, encoding: NSUTF8StringEncoding)
		}
		catch {
			simpleTunnelLog("Failed to fetch the rules from \(infoURL)")
			return
		}

		let contentArray = content.componentsSeparatedByString("<br/>")
		simpleTunnelLog("Content array is \(contentArray)")
		var urlRules = [String: [String: AnyObject]]()

		for rule in contentArray {
			if rule.isEmpty {
				continue
			}
			let ruleArray = rule.componentsSeparatedByString(" ")

			guard !ruleArray.isEmpty else { continue }

			var redirectKey = "SafeYes"
			var remediateKey = "Remediate1"
			var remediateButtonKey = "RemediateButton1"
			var actionString = "9"

			let urlString = ruleArray[0]
			let ruleArrayCount = ruleArray.count

			if ruleArrayCount > 1 {
				actionString = ruleArray[1]
			}
			if ruleArrayCount > 2 {
				redirectKey = ruleArray[2]
			}
			if ruleArrayCount > 3 {
				remediateKey = ruleArray[3]
			}
			if ruleArrayCount > 4 {
				remediateButtonKey = ruleArray[4]
			}


			urlRules[urlString] = [
				"kRule" : actionString,
				"kRedirectKey" : redirectKey,
				"kRemediateKey" : remediateKey,
				"kRemediateButtonKey" : remediateButtonKey,
			]
		}
		defaults?.setValue(urlRules, forKey:"rules")
	}
}
