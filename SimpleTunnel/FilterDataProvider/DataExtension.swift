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
	var flowOffSetMapping = [URL: Int]()

	/// The list of flows that should be blocked after fetching new rules.
	var blockNeedRules = [String]()

	/// The list of flows that should be allowed after fetching new rules.
	var allowNeedRules = [String]()

	// MARK: NEFilterDataProvider

	/// Handle a new flow of data.
	override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
		var result = NEFilterNewFlowVerdict.allow()

		simpleTunnelLog("handleNewFlow called for flow: \(flow)")

		// Look for a matching rule in the current set of rules.
		let (ruleType, hostname, hostNameRule) = FilterUtilities.getRule(flow)

		switch ruleType {
			case .block:
				simpleTunnelLog("\(hostname) is set to be blocked")
				result = NEFilterNewFlowVerdict.drop()

			case .remediate:
				simpleTunnelLog("\(hostname) is set for remediation")
				if let remediationKey = hostNameRule["kRemediateKey"], let remediateButtonKey = hostNameRule["kRemediateButtonKey"] {
					result = NEFilterNewFlowVerdict.remediateVerdict(withRemediationURLMapKey: remediationKey as! String, remediationButtonTextMapKey: remediateButtonKey as! String)
				}
				else {
					result = NEFilterNewFlowVerdict.remediateVerdict(withRemediationURLMapKey: "Remediate1", remediationButtonTextMapKey: "RemediateButton1")
				}

			case .allow:
				simpleTunnelLog("\(hostname) is set to be Allowed")
				result = NEFilterNewFlowVerdict.allow()

			case .redirectToSafeURL:
				simpleTunnelLog("\(hostname) is set to the redirected")
				if let redirectKey = hostNameRule["kRedirectKey"] {
					simpleTunnelLog("redirect key is \(redirectKey)")
					result = NEFilterNewFlowVerdict.urlAppendStringVerdict(withMapKey: redirectKey as! String)
				}
				else {
					simpleTunnelLog("Falling back to default redirect key")
					result = NEFilterNewFlowVerdict.urlAppendStringVerdict(withMapKey: "SafeYes")
				}

			case .needMoreRulesAndBlock, .needMoreRulesAndAllow, .needMoreRulesFromDataAndAllow, .needMoreRulesFromDataAndBlock:
				simpleTunnelLog("Setting the need rules verdict")
				result = NEFilterNewFlowVerdict.needRules()

			default:
				simpleTunnelLog("rule number \(ruleType) doesn't match with the current ruleset")
		}

		return result

	}

	/// Filter an inbound chunk of data.
	override func handleInboundData(from flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes: Data) -> NEFilterDataVerdict {
		var result = NEFilterDataVerdict.allow()
		simpleTunnelLog("handleInboundDataFromFlow called for flow \(flow)")

		// Look for a matching rule in the current set of rules.
		let (ruleType, hostname, hostNameRule) = FilterUtilities.getRule(flow)

		switch ruleType {
			case .block:
				simpleTunnelLog("\(hostname) is set to be blocked")

			case .needMoreRulesAndBlock:
				simpleTunnelLog("\(hostname) is set to need rules and blocked")

			case .needMoreRulesAndAllow:
				simpleTunnelLog("\(hostname) is set to need rules and allow")

			case .needMoreRulesFromDataAndAllow:
				simpleTunnelLog("\(hostname) is set to need rules and let the data provider allow")
				if let hostnameIndex = allowNeedRules.index(of: hostname) {
					allowNeedRules.remove(at: hostnameIndex)
					simpleTunnelLog("Allowing \(hostname) since need rules response returned")
				}
				else {
					allowNeedRules.append(hostname)
					simpleTunnelLog("Need rules verdict set")
					result = NEFilterDataVerdict.needRules()
				}

			case .needMoreRulesFromDataAndBlock:
				simpleTunnelLog("\(hostname) is set to need rules and let the data provider block")
				if let hostnameIndex = blockNeedRules.index(of: hostname) {
					blockNeedRules.remove(at: hostnameIndex)
					simpleTunnelLog("Blocking \(hostname) since need rules response returned")
					result = NEFilterDataVerdict.drop()
				}
				else {
					blockNeedRules.append(hostname)
					result = NEFilterDataVerdict.needRules()
				}

			case .examineData:
				simpleTunnelLog("\(hostname) is set to check for more data")

			case .redirectToSafeURL:
				simpleTunnelLog("\(hostname) is set for URL redirection")

			case .remediate:
				simpleTunnelLog("\(hostname) is set for remediation")
				if let remediationKey = hostNameRule["kRemediationKey"] as? String {
					result = NEFilterDataVerdict.remediateVerdict(withRemediationURLMapKey: remediationKey, remediationButtonTextMapKey: remediationKey)
				}

			default:
				simpleTunnelLog("\(hostname) is set for unknown rule type")
		}

		return result
	}

	/// Handle the event where all of the inbound data for a flow has been filtered.
	override func handleInboundDataComplete(for flow: NEFilterFlow) -> NEFilterDataVerdict {
		var result = NEFilterDataVerdict.allow()
		simpleTunnelLog("handleInboundDataCompleteForFlow called for \(flow)")

		// Look for a matching rule in the current set of rules.
		let (ruleType, hostname, hostNameRule) = FilterUtilities.getRule(flow)

		switch ruleType {
			case .block:
				simpleTunnelLog("\(hostname) is set to be blocked")

			case .needMoreRulesAndBlock:
				simpleTunnelLog("\(hostname) is set to need rules and blocked")

			case .needMoreRulesAndAllow:
				simpleTunnelLog("\(hostname) is set to need rules and allow")

			case .needMoreRulesFromDataAndAllow:
				simpleTunnelLog("\(hostname) is set to need rules and let the data provider allow")

			case .needMoreRulesFromDataAndBlock:
				simpleTunnelLog("\(hostname) is set to need rules and let the data provider block")

			case .examineData:
				simpleTunnelLog("\(hostname) is set to check for more data")
				if let dataComplete = hostNameRule["kDataComplete"]?.boolValue {
					result = dataComplete ? NEFilterDataVerdict.allow() : NEFilterDataVerdict.drop()
					simpleTunnelLog("\(result.description) for \(hostname)")
				}

			case .redirectToSafeURL:
				simpleTunnelLog("\(hostname) is set for URL redirection")

			case .remediate:
				simpleTunnelLog("\(hostname) is set for remediation")
				if let remediationKey = hostNameRule["kRemediationKey"] as? String {
					result = NEFilterDataVerdict.remediateVerdict(withRemediationURLMapKey: remediationKey, remediationButtonTextMapKey: remediationKey)
				}
			
			default:
				simpleTunnelLog("\(hostname) is set for unknonw rules")
		}
		
		return result
	}

	/// Filter an outbound chunk of data.
	override func handleOutboundData(from flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes: Data) -> NEFilterDataVerdict {
		var result = NEFilterDataVerdict.allow()
		simpleTunnelLog("handleOutboundDataFromFlow called for \(flow)")

		// Look for a matching rule in the current set of rules.
		let (ruleType, hostname, hostNameRule) = FilterUtilities.getRule(flow)

		switch ruleType {
			case .block:
				simpleTunnelLog("\(hostname) is set to be blocked")
			case .needMoreRulesAndBlock:
				simpleTunnelLog("\(hostname) is set to need rules and blocked")

			case .needMoreRulesAndAllow:
				simpleTunnelLog("\(hostname) is set to need rules and allow")

			case .needMoreRulesFromDataAndAllow:
				simpleTunnelLog("\(hostname) is set to need rules and let the data provider allow")
				if let hostnameIndex = allowNeedRules.index(of: hostname) {
					allowNeedRules.remove(at: hostnameIndex)
					simpleTunnelLog("Allowing \(hostname) since need rules response returned")
					result = NEFilterDataVerdict.allow()
				}
				else {
					allowNeedRules.append(hostname)
					simpleTunnelLog("Need rules verdict set")
					result = NEFilterDataVerdict.needRules()
				}

			case .needMoreRulesFromDataAndBlock:
				simpleTunnelLog("\(hostname) is set to need rules and let the data provider block")
				if let hostnameIndex = blockNeedRules.index(of: hostname) {
					blockNeedRules.remove(at: hostnameIndex)
					simpleTunnelLog("Blocking \(hostname) since need rules response returned")
					result = NEFilterDataVerdict.drop()
				}
				else {
					blockNeedRules.append(hostname)
					result = NEFilterDataVerdict.needRules()
				}

			case .examineData:
				simpleTunnelLog("\(hostname) is set to check for more data")

			case .redirectToSafeURL:
				simpleTunnelLog("\(hostname) is set for URL redirection")

			case .remediate:
				simpleTunnelLog("\(hostname) is set for remediation")
				if let remediationKey = hostNameRule["kRemediationKey"] as! String? {
					return NEFilterDataVerdict.remediateVerdict(withRemediationURLMapKey: remediationKey, remediationButtonTextMapKey: remediationKey)
				}

			default:
				simpleTunnelLog("\(hostname) is set for unknonw rules")
		}

		return result
	}

	/// Handle the event where all of the outbound data for a flow has been filtered.
	override func handleOutboundDataComplete(for flow: NEFilterFlow) -> NEFilterDataVerdict {
		var result = NEFilterDataVerdict.allow()
		simpleTunnelLog("handleOutboundDataCompleteForFlow called for \(flow)")

		// Look for a matching rule in the current set of rules.
		let (ruleType, hostname, hostNameRule) = FilterUtilities.getRule(flow)

		switch ruleType {
			case .block:
				simpleTunnelLog("\(hostname) is set to be blocked")

			case .needMoreRulesAndBlock:
				simpleTunnelLog("\(hostname) is set to need rules and blocked")

			case .needMoreRulesAndAllow:
				simpleTunnelLog("\(hostname) is set to need rules and allow")

			case .needMoreRulesFromDataAndAllow:
				simpleTunnelLog("\(hostname) is set to need rules and let the data provider allow")
				if let hostnameIndex = allowNeedRules.index(of: hostname) {
					allowNeedRules.remove(at: hostnameIndex)
					simpleTunnelLog("Allowing \(hostname) since need rules response returned")
					result = NEFilterDataVerdict.allow()
				}
				else {
					allowNeedRules.append(hostname)
					simpleTunnelLog("Need rules verdict set")
					result = NEFilterDataVerdict.needRules()
				}

			case .needMoreRulesFromDataAndBlock:
				simpleTunnelLog("\(hostname) is set to need rules and let the data provider block")
				if let hostnameIndex = blockNeedRules.index(of: hostname) {
					blockNeedRules.remove(at: hostnameIndex)
					simpleTunnelLog("Blocking \(hostname) since need rules response returned")
					return NEFilterDataVerdict.drop()
				}
				else {
					blockNeedRules.append(hostname)
					result = NEFilterDataVerdict.needRules()
				}

			case .examineData:
				simpleTunnelLog("\(hostname) is set to check for more data")
				if let maxPeekBytes = (hostNameRule["kMaxPeekBytes"] as! NSNumber?)?.intValue,
					let maxPassBytes = (hostNameRule["kMaxPassBytes"] as! NSNumber?)?.intValue,
					let peekInterval = (hostNameRule["kPeekInterval"] as! NSNumber?)?.intValue,
					let url = flow.url,
					let peekOffset = flowOffSetMapping[url]
				{
					simpleTunnelLog("peek offset is \(peekOffset)")
					let newPeekOffset = peekOffset + peekInterval

					flowOffSetMapping[url] = newPeekOffset

					simpleTunnelLog("new peek offset is \(newPeekOffset)")
					let dataPassBytes = ((maxPeekBytes >= 0 && maxPassBytes < peekOffset) ? maxPassBytes : peekOffset)
					let dataPeekBytes = ((maxPeekBytes >= 0 && maxPeekBytes < newPeekOffset) ? maxPeekBytes : newPeekOffset)
					result = NEFilterDataVerdict(passBytes: dataPassBytes, peekBytes: dataPeekBytes)
				}

			case .redirectToSafeURL:
				simpleTunnelLog("\(hostname) is set for URL redirection")

			case .remediate:
				simpleTunnelLog("\(hostname) is set for remediation")
				if let remediationKey = hostNameRule["kRemediationKey"] as? String {
					result = NEFilterDataVerdict.remediateVerdict(withRemediationURLMapKey: remediationKey, remediationButtonTextMapKey: remediationKey)
				}
			
			default:
				simpleTunnelLog("\(hostname) is set for unknonw rules")
		}

		return result
	}

	/// Handle the user tapping on the "Request Access" link in the block page.
	override func handleRemediation(for flow: NEFilterFlow) -> NEFilterRemediationVerdict {
		simpleTunnelLog("handleRemediationForFlow called: Allow verdict")

		return NEFilterRemediationVerdict.allow()
	}
}
