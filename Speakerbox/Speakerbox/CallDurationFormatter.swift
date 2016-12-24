/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Utility wrapper of NSDateComponentsFormatter for formatting call durations into strings
*/

import Foundation

final class CallDurationFormatter {

    private let dateFormatter: DateComponentsFormatter

    init() {
        dateFormatter = DateComponentsFormatter()
        dateFormatter.unitsStyle = .positional
        dateFormatter.allowedUnits = [.minute, .second]
        dateFormatter.zeroFormattingBehavior = .pad
    }

    // MARK: API

    func format(dateComponents: DateComponents) -> String? {
        return dateFormatter.string(from: dateComponents)
    }

    func format(timeInterval: TimeInterval) -> String? {
        return dateFormatter.string(from: timeInterval)
    }

}
