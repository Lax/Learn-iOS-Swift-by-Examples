/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller to display output from the accelerometer.
 */

import UIKit
import CoreMotion
import simd

class AccelerometerViewController: UIViewController, MotionGraphContainer {
    
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
        guard let motionManager = motionManager, motionManager.isAccelerometerAvailable else { return }
        
        updateIntervalLabel.text = formattedUpdateInterval
        
        motionManager.accelerometerUpdateInterval = TimeInterval(updateIntervalSlider.value)
        motionManager.showsDeviceMovementDisplay = true
        
        motionManager.startAccelerometerUpdates(to: .main) { accelerometerData, error in
            guard let accelerometerData = accelerometerData else { return }
            
            let acceleration: double3 = [accelerometerData.acceleration.x, accelerometerData.acceleration.y, accelerometerData.acceleration.z]
            self.graphView.add(acceleration)
            self.setValueLabels(xyz: acceleration)
        }
    }
    
    func stopUpdates() {
        guard let motionManager = motionManager, motionManager.isAccelerometerAvailable else { return }
        
        motionManager.stopAccelerometerUpdates()
    }
}
