/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller to display output from the gyroscope.
 */

import UIKit
import CoreMotion
import simd

class GyroscopeViewController: UIViewController, MotionGraphContainer {
    // MARK: Properties
    
    @IBOutlet weak var graphView: GraphView!
    
    // MARK: MotionGraphContainer properties
    
    var motionManager: CMMotionManager?
    
    @IBOutlet weak var updateIntervalLabel: UILabel!
    
    @IBOutlet weak var updateIntervalSlider: UISlider!
    
    let updateIntervalFormatter = MeasurementFormatter()
    
    @IBOutlet var valueLabels: [UILabel]!
    
    // MARK: UIViewController overrides
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startUpdates()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        stopUpdates()
    }
    
    // MARK: Interface Builder actions
    
    @IBAction func intervalSliderChanged(_ sender: UISlider) {
        startUpdates()
    }
    
    // MARK: MotionGraphContainer implementation
    
    func startUpdates() {
        guard let motionManager = motionManager, motionManager.isGyroAvailable else { return }
        
        updateIntervalLabel.text = formattedUpdateInterval
        
        motionManager.gyroUpdateInterval = TimeInterval(updateIntervalSlider.value)
        motionManager.showsDeviceMovementDisplay = true
        
        motionManager.startGyroUpdates(to: .main) { gyroData, error in
            guard let gyroData = gyroData else { return }
            
            let rotationRate: double3 = [gyroData.rotationRate.x, gyroData.rotationRate.y, gyroData.rotationRate.z]
            self.graphView.add(rotationRate)
            self.setValueLabels(xyz: rotationRate)
        }
    }
    
    func stopUpdates() {
        guard let motionManager = motionManager, motionManager.isAccelerometerAvailable else { return }
        
        motionManager.stopGyroUpdates()
    }
}
