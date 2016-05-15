/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the DataExtension class. The DataExtension class is a sub-class of NEFilterDataProvider, and implements a network content filter.
*/

import NetworkExtension
import SimpleTunnelServices

/// A NEFilterDataProvider sub-class that implements a simple network content filter.
class DataExtension: NEFilterDataProvider {

	// MARK: Properties

	/// A record of where in a particular flow the filter is looking.
	var flowOffSetMapping = [NSURL: Int]()

	/// The list of flows that should be blocked after fetching new rules.
	var blockNeedRules = [String]()

	/// The list of flows that should be allowed after fetching new rules.
	var allowNeedRules = [String]()

	// MARK: NEFilterDataProvider

	/// Handle a new flow of data.
	override func handleNewFlow(flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
		var result = NEFilterNewFlowVerdict.allowVerdict()

		simpleTunnelLog("handleNewFlow called for flow: \(flow)")

		// Look for a matching rule in the current set of rules.
		let (ruleType, hostname, hostNameRule) = FilterUtilities.getRule(flow)

		switch ruleType {
			case .Block:
				simpleTunnelLog("\(hostname) is set to be blocked")
				result = NEFilterNewFlowVerdict.dropVerdict()

			case .Remediate:
				simpleTunnelLog("\(hostname) is set for remediation")
				if let remediationKey = hostNameRule["kRemediateKey"], let remediateButtonKey = hostNameRule["kRemediateButtonKey"] {
					result = NEFilterNewFlowVerdict.remediateVerdictWithRemediationURLMapKey(remediationKey as! String, remediationButtonTextMapKey: remediateButtonKey as! String)
				}
				else {
					result = NEFilterNewFlowVerdict.remediateVerdictWithRemediationURLMapKey("Remediate1", remediationButtonTextMapKey: "RemediateButton1")
				}

			case .Allow:
				simpleTunnelLog("\(hostname) is set to be Allowed")
				result = NEFilterNewFlowVerdict.allowVerdict()

			case .RedirectToSafeURL:
				simpleTunnelLog("\(hostname) is set to the redirected")
				if let redirectKey = hostNameRule["kRedirectKey"] {
					simpleTunnelLog("redirect key is \(redirectKey)")
					result = NEFilterNewFlowVerdict.URLAppendStringVerdictWithMapKey(redirectKey as! String)
				}
				else {
					simpleTunnelLog("Falling back to default redirect key")
					result = NEFilterNewFlowVerdict.URLAppendStringVerdictWithMapKey("SafeYes")
				}

			case .NeedMoreRulesAndBlock, .NeedMoreRulesAndAllow, .NeedMoreRulesFromDataAndAllow, .NeedMoreRulesFromDataAndBlock:
				simpleTunnelLog("Setting the need rules verdict")
				result = NEFilterNewFlowVerdict.needRulesVerdict()

			default:
				simpleTunnelLog("rule number \(ruleType) doesn't match with the current ruleset")
		}

		return result

	}

	/// Filter an inbound chunk of data.
	override func handleInboundDataFromFlow(flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes: NSData) -> NEFilterDataVerdict {
		var result = NEFilterDataVerdict.allowVerdict()
		simpleTunnelLog("handleInboundDataFromFlow called for flow \(flow)")

		// Look for a matching rule in the current set of rules.
		let (ruleType, hostname, hostNameRule) = FilterUtilities.getRule(flow)

		switch ruleType {
			case .Block:
				simpleTunnelLog("\(hostname) is set to be blocked")

			case .NeedMoreRulesAndBlock:
				simpleTunnelLog("\(hostname) is set to need rules and blocked")

			case .NeedMoreRulesAndAllow:
				simpleTunnelLog("\(hostname) is set to need rules and allow")

			case .NeedMoreRulesFromDataAndAllow:
				simpleTunnelLog("\(hostname) is set to need rules and let the data provider allow")
				if let hostnameIndex = allowNeedRules.indexOf(hostname) {
					allowNeedRules.removeAtIndex(hostnameIndex)
					simpleTunnelLog("Allowing \(hostname) since need rules response returned")
				}
				else {
					allowNeedRules.append(hostname)
					simpleTunnelLog("Need rules verdict set")
					result = NEFilterDataVerdict.needRulesVerdict()
				}

			case .NeedMoreRulesFromDataAndBlock:
				simpleTunnelLog("\(hostname) is set to need rules and let the data provider block")
				if let hostnameIndex = blockNeedRules.indexOf(hostname) {
					blockNeedRules.removeAtIndex(hostnameIndex)
					simpleTunnelLog("Blocking \(hostname) since need rules response returned")
					result = NEFilterDataVerdict.dropVerdict()
				}
				else {
					blockNeedRules.append(hostname)
					result = NEFilterDataVerdict.needRulesVerdict()
				}

			case .ExamineData:
				simpleTunnelLog("\(hostname) is set to check for more data")

			case .RedirectToSafeURL:
				simpleTunnelLog("\(hostname) is set for URL redirection")

			case .Remediate:
				simpleTunnelLog("\(hostname) is set for remediation")
				if let remediationKey = hostNameRule["kRemediationKey"] as? String {
					result = NEFilterDataVerdict.remediateVerdictWithRemediationURLMapKey(remediationKey, remediationButtonTextMapKey: remediationKey)
				}

			default:
				simpleTunnelLog("\(hostname) is set for unknown rule type")
		}

		return result
	}

	/// Handle the event where all of the inbound data for a flow has been filtered.
	override func handleInboundDataCompleteForFlow(flow: NEFilterFlow) -> NEFilterDataVerdict {
		var result = NEFilterDataVerdict.allowVerdict()
		simpleTunnelLog("handleInboundDataCompleteForFlow called for \(flow)")

		// Look for a matching rule in the current set of rules.
		let (ruleType, hostname, hostNameRule) = FilterUtilities.getRule(flow)

		switch ruleType {
			case .Block:
				simpleTunnelLog("\(hostname) is set to be blocked")

			case .NeedMoreRulesAndBlock:
				simpleTunnelLog("\(hostname) is set to need rules and blocked")

			case .NeedMoreRulesAndAllow:
				simpleTunnelLog("\(hostname) is set to need rules and allow")

			case .NeedMoreRulesFromDataAndAllow:
				simpleTunnelLog("\(hostname) is set to need rules and let the data provider allow")

			case .NeedMoreRulesFromDataAndBlock:
				simpleTunnelLog("\(hostname) is set to need rules and let the data provider block")

			case .ExamineData:
				simpleTunnelLog("\(hostname) is set to check for more data")
				if let dataComplete = hostNameRule["kDataComplete"]?.boolValue {
					result = dataComplete ? NEFilterDataVerdict.allowVerdict() : NEFilterDataVerdict.dropVerdict()
					simpleTunnelLog("\(result.description) for \(hostname)")
				}

			case .RedirectToSafeURL:
				simpleTunnelLog("\(hostname) is set for URL redirection")

			case .Remediate:
				simpleTunnelLog("\(hostname) is set for remediation")
				if let remediationKey = hostNameRule["kRemediationKey"] as? String {
					result = NEFilterDataVerdict.remediateVerdictWithRemediationURLMapKey(remediationKey, remediationButtonTextMapKey: remediationKey)
				}
			
			default:
				simpleTunnelLog("\(hostname) is set for unknonw rules")
		}
		
		return result
	}

	/// Filter an outbound chunk of data.
	override func handleOutboundDataFromFlow(flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes: NSData) -> NEFilterDataVerdict {
		var result = NEFilterDataVerdict.allowVerdict()
		simpleTunnelLog("handleOutboundDataFromFlow called for \(flow)")

		// Look for a matching rule in the current set of rules.
		let (ruleType, hostname, hostNameRule) = FilterUtilities.getRule(flow)

		switch ruleType {
			case .Block:
				simpleTunnelLog("\(hostname) is set to be blocked")
			case .NeedMoreRulesAndBlock:
				simpleTunnelLog("\(hostname) is set to need rules and blocked")

			case .NeedMoreRulesAndAllow:
				simpleTunnelLog("\(hostname) is set to need rules and allow")

			case .NeedMoreRulesFromDataAndAllow:
				simpleTunnelLog("\(hostname) is set to need rules and let the data provider allow")
				if let hostnameIndex = allowNeedRules.indexOf(hostname) {
					allowNeedRules.removeAtIndex(hostnameIndex)
					simpleTunnelLog("Allowing \(hostname) since need rules response returned")
					result = NEFilterDataVerdict.allowVerdict()
				}
				else {
					allowNeedRules.append(hostname)
					simpleTunnelLog("Need rules verdict set")
					result = NEFilterDataVerdict.needRulesVerdict()
				}

			case .NeedMoreRulesFromDataAndBlock:
				simpleTunnelLog("\(hostname) is set to need rules and let the data provider block")
				if let hostnameIndex = blockNeedRules.indexOf(hostname) {
					blockNeedRules.removeAtIndex(hostnameIndex)
					simpleTunnelLog("Blocking \(hostname) since need rules response returned")
					result = NEFilterDataVerdict.dropVerdict()
				}
				else {
					blockNeedRules.append(hostname)
					result = NEFilterDataVerdict.needRulesVerdict()
				}

			case .ExamineData:
				simpleTunnelLog("\(hostname) is set to check for more data")

			case .RedirectToSafeURL:
				simpleTunnelLog("\(hostname) is set for URL redirection")

			case .Remediate:
				simpleTunnelLog("\(hostname) is set for remediation")
				if let remediationKey = hostNameRule["kRemediationKey"] as! String? {
					return NEFilterDataVerdict.remediateVerdictWithRemediationURLMapKey(remediationKey, remediationButtonTextMapKey: remediationKey)
				}

			default:
				simpleTunnelLog("\(hostname) is set for unknonw rules")
		}

		return result
	}

	/// Handle the event where all of the outbound data for a flow has been filtered.
	override func handleOutboundDataCompleteForFlow(flow: NEFilterFlow) -> NEFilterDataVerdict {
		var result = NEFilterDataVerdict.allowVerdict()
		simpleTunnelLog("handleOutboundDataCompleteForFlow called for \(flow)")

		// Look for a matching rule in the current set of rules.
		let (ruleType, hostname, hostNameRule) = FilterUtilities.getRule(flow)

		switch ruleType {
			case .Block:
				simpleTunnelLog("\(hostname) is set to be blocked")

			case .NeedMoreRulesAndBlock:
				simpleTunnelLog("\(hostname) is set to need rules and blocked")

			case .NeedMoreRulesAndAllow:
				simpleTunnelLog("\(hostname) is set to need rules and allow")

			case .NeedMoreRulesFromDataAndAllow:
				simpleTunnelLog("\(hostname) is set to need rules and let the data provider allow")
				if let hostnameIndex = allowNeedRules.indexOf(hostname) {
					allowNeedRules.removeAtIndex(hostnameIndex)
					simpleTunnelLog("Allowing \(hostname) since need rules response returned")
					result = NEFilterDataVerdict.allowVerdict()
				}
				else {
					allowNeedRules.append(hostname)
					simpleTunnelLog("Need rules verdict set")
					result = NEFilterDataVerdict.needRulesVerdict()
				}

			case .NeedMoreRulesFromDataAndBlock:
				simpleTunnelLog("\(hostname) is set to need rules and let the data provider block")
				if let hostnameIndex = blockNeedRules.indexOf(hostname) {
					blockNeedRules.removeAtIndex(hostnameIndex)
					simpleTunnelLog("Blocking \(hostname) since need rules response returned")
					return NEFilterDataVerdict.dropVerdict()
				}
				else {
					blockNeedRules.append(hostname)
					result = NEFilterDataVerdict.needRulesVerdict()
				}

			case .ExamineData:
				simpleTunnelLog("\(hostname) is set to check for more data")
				if let maxPeekBytes = hostNameRule["kMaxPeekBytes"]?.integerValue,
					maxPassBytes = hostNameRule["kMaxPassBytes"]?.integerValue,
					peekInterval = hostNameRule["kPeekInterval"]?.integerValue,
					url = flow.URL,
					peekOffset = flowOffSetMapping[url]
				{
					simpleTunnelLog("peek offset is \(peekOffset)")
					let newPeekOffset = peekOffset + peekInterval

					flowOffSetMapping[url] = newPeekOffset

					simpleTunnelLog("new peek offset is \(newPeekOffset)")
					let dataPassBytes = ((maxPeekBytes >= 0 && maxPassBytes < peekOffset) ? maxPassBytes : peekOffset)
					let dataPeekBytes = ((maxPeekBytes >= 0 && maxPeekBytes < newPeekOffset) ? maxPeekBytes : newPeekOffset)
					result = NEFilterDataVerdict(passBytes: dataPassBytes, peekBytes: dataPeekBytes)
				}

			case .RedirectToSafeURL:
				simpleTunnelLog("\(hostname) is set for URL redirection")

			case .Remediate:
				simpleTunnelLog("\(hostname) is set for remediation")
				if let remediationKey = hostNameRule["kRemediationKey"] as? String {
					result = NEFilterDataVerdict.remediateVerdictWithRemediationURLMapKey(remediationKey, remediationButtonTextMapKey: remediationKey)
				}
			
			default:
				simpleTunnelLog("\(hostname) is set for unknonw rules")
		}

		return result
	}

	/// Handle the user tapping on the "Request Access" link in the block page.
	override func handleRemediationForFlow(flow: NEFilterFlow) -> NEFilterRemediationVerdict {
		simpleTunnelLog("handleRemediationForFlow called: Allow verdict")

		return NEFilterRemediationVerdict.allowVerdict()
	}
}
