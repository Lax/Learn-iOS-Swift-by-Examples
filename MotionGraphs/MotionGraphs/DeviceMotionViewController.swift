/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller to display output from the motion sensor.
 */

import UIKit
import CoreMotion
import simd

class DeviceMotionViewController: UIViewController, MotionGraphContainer {
    
    // MARK: Properties
    
    @IBOutlet var graphSelector: UISegmentedControl!
    
    @IBOutlet var graphsContainer: UIView!
    
    private var selectedDeviceMotion: DeviceMotion {
        return DeviceMotion(rawValue: graphSelector.selectedSegmentIndex)!
    }
    
    private var graphViews: [GraphView] = []

    // MARK: MotionGraphContainer properties
    
    var motionManager: CMMotionManager?

    @IBOutlet weak var updateIntervalLabel: UILabel!
    
    @IBOutlet weak var updateIntervalSlider: UISlider!
    
    let updateIntervalFormatter = MeasurementFormatter()
    
    @IBOutlet var valueLabels: [UILabel]!
    
    // MARK: UIViewController overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create graph views for each graph type.
        graphViews = DeviceMotion.allTypes.map { type in
            return GraphView(frame: graphsContainer.bounds)
        }
        
        // Add the graph views to the container view.
        for graphView in graphViews {
            graphsContainer.addSubview(graphView)
            graphView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
    }
    
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
    
    @IBAction func graphSelectorChanged(_ sender: UISegmentedControl) {
        showGraph(selectedDeviceMotion)
    }
    
    // MARK: MotionGraphContainer implementation
    
    func startUpdates() {
        guard let motionManager = motionManager, motionManager.isDeviceMotionAvailable else { return }
        
        showGraph(selectedDeviceMotion)
        updateIntervalLabel.text = formattedUpdateInterval
        
        motionManager.deviceMotionUpdateInterval = TimeInterval(updateIntervalSlider.value)
        motionManager.showsDeviceMovementDisplay = true
        
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { deviceMotion, error in
            guard let deviceMotion = deviceMotion else { return }
            
            let attitude = double3([deviceMotion.attitude.roll, deviceMotion.attitude.pitch, deviceMotion.attitude.yaw])
            let rotationRate = double3([deviceMotion.rotationRate.x, deviceMotion.rotationRate.y, deviceMotion.rotationRate.z])
            let gravity = double3([deviceMotion.gravity.x, deviceMotion.gravity.y, deviceMotion.gravity.z])
            let userAcceleration = double3([deviceMotion.userAcceleration.x, deviceMotion.userAcceleration.y, deviceMotion.userAcceleration.z])
            
            self.graphView(for: .attitude).add(attitude)
            self.graphView(for: .rotationRate).add(rotationRate)
            self.graphView(for: .gravity).add(gravity)
            self.graphView(for: .userAcceleration).add(userAcceleration)
            
            // Update the labels with data for the currently selected device motion.
            switch self.selectedDeviceMotion {
            case .attitude:
                self.setValueLabels(rollPitchYaw: attitude)
                
            case .rotationRate:
                self.setValueLabels(xyz: rotationRate)
                
            case .gravity:
                self.setValueLabels(xyz: gravity)
                
            case .userAcceleration:
                self.setValueLabels(xyz: userAcceleration)
            }
        }
    }

    func stopUpdates() {
        guard let motionManager = motionManager, motionManager.isDeviceMotionActive else { return }

        motionManager.stopDeviceMotionUpdates()
    }
    
    // MARK: Convenience
    
    private func graphView(for motionType: DeviceMotion) -> GraphView {
        let index = motionType.rawValue
        return graphViews[index]
    }
    
    private func showGraph(_ motionType: DeviceMotion) {
        let selectedGraphIndex = motionType.rawValue
        
        for (index, graph) in graphViews.enumerated() {
            graph.isHidden = index != selectedGraphIndex
        }
    }
}


fileprivate enum DeviceMotion: Int {
    case attitude, rotationRate, gravity, userAcceleration
    
    static let allTypes: [DeviceMotion] = [.attitude, .rotationRate, .gravity, .userAcceleration]
}
