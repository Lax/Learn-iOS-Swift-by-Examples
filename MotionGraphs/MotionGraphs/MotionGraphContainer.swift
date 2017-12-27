/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Defines a protocol that the view controllers conform to and provides helper methods for updating labels.
 */

import CoreMotion
import UIKit
import simd

protocol MotionGraphContainer {
    
    var motionManager: CMMotionManager? { get set }
    
    var updateIntervalLabel: UILabel! { get }
    
    var updateIntervalSlider: UISlider! { get }
    
    var updateIntervalFormatter: MeasurementFormatter { get }
    
    var valueLabels: [UILabel]! { get }
    
    func startUpdates()
    
    func stopUpdates()
}

extension MotionGraphContainer {
    private var sortedLabels: [UILabel] {
        return valueLabels.sorted { $0.center.y < $1.center.y }
    }
    
    func setValueLabels(rollPitchYaw: double3) {
        let sortedLabels = self.sortedLabels
        sortedLabels[0].text = String(format: "Roll: %+6.4f", rollPitchYaw[0])
        sortedLabels[1].text = String(format: "Pitch: %+6.4f", rollPitchYaw[1])
        sortedLabels[2].text = String(format: "Yaw: %+6.4f", rollPitchYaw[2])
    }
    
    func setValueLabels(xyz: double3) {
        let sortedLabels = self.sortedLabels
        sortedLabels[0].text = String(format: "x: %+6.4f", xyz[0])
        sortedLabels[1].text = String(format: "y: %+6.4f", xyz[1])
        sortedLabels[2].text = String(format: "z: %+6.4f", xyz[2])
    }
    
    var formattedUpdateInterval: String {
        updateIntervalFormatter.numberFormatter.minimumFractionDigits = 3
        updateIntervalFormatter.numberFormatter.maximumFractionDigits = 3
        
        let updateInterval = Measurement(value: Double(updateIntervalSlider.value), unit: UnitDuration.seconds)
        return updateIntervalFormatter.string(from: updateInterval)
    }
}
