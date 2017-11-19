/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Helper functions and methods for working with dates.
 */

import Foundation

func getDate(daysAgo days: Double = 0, hoursAgo hours: Double = 0, minutesAgo minutes: Double = 0, secondsAgo seconds: Double = 0) -> Date {
    let hoursPerDay: Double = 24
    let hoursMeasurement = Measurement(value: (days * hoursPerDay) + hours, unit: UnitDuration.hours)
    let minutesMeasurement = Measurement(value: minutes, unit: UnitDuration.minutes)
    let secondsMeasurement = Measurement(value: seconds, unit: UnitDuration.seconds)
    let totalMeasurement = hoursMeasurement + minutesMeasurement + secondsMeasurement
    let totalTimeInterval = totalMeasurement.converted(to: UnitDuration.seconds).value
    return Date() - totalTimeInterval
}

extension Date {
    func timeAgoString() -> String? {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self, to: Date())
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        
        if components.year != nil, components.year != 0 {
            formatter.allowedUnits = .year
        }
        else if components.month != nil, components.month != 0 {
            formatter.allowedUnits = .month
        }
        else if components.day != nil, components.day != 0 {
            formatter.allowedUnits = .day
        }
        else if components.hour != nil, components.hour != 0 {
            formatter.allowedUnits = .hour
        }
        else if components.minute != nil, components.minute != 0 {
            formatter.allowedUnits = .minute
        }
        else {
            formatter.allowedUnits = .second
        }
        
        guard let timeString = formatter.string(from: components) else {
            return nil
        }
        return String(format: NSLocalizedString("%@ ago", comment: "Format string for relative time ago"), timeString)
    }
}
