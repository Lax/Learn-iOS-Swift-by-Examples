/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Interface controller for the workout summary screen.
 */

import WatchKit
import Foundation
import HealthKit

class SummaryInterfaceController: WKInterfaceController {
    // MARK: Properties
    var workout: HKWorkout?
    
    // MARK: IB Outlets
    
    @IBOutlet var workoutLabel: WKInterfaceLabel!
    
    @IBOutlet var durationLabel: WKInterfaceLabel!
    
    @IBOutlet var caloriesLabel: WKInterfaceLabel!
    
    @IBOutlet var distanceLabel: WKInterfaceLabel!
    
    // MARK: Interface Controller Overrides
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        workout = context as? HKWorkout
        
        setTitle("Summary")
    }
    
    override func willActivate() {
        super.willActivate()
        
        guard let workout = workout else { return }
        
        workoutLabel.setText("\(format(activityType: workout.workoutActivityType))")
        caloriesLabel.setText(format(energy: workout.totalEnergyBurned!))
        distanceLabel.setText(format(distance: workout.totalDistance!))

        let duration = computeDurationOfWorkout(withEvents: workout.workoutEvents, startDate: workout.startDate, endDate: workout.endDate)
        durationLabel.setText(format(duration: duration))
    }
    
    @IBAction func didTapDoneButton() {
        WKInterfaceController.reloadRootControllers(withNames: ["ConfigurationInterfaceController"], contexts: nil)
    }
}
