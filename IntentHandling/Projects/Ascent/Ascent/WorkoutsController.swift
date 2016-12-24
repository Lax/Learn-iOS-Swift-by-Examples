/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that lists the most recent workouts.
*/

import UIKit
import AscentFramework

class WorkoutsController: UITableViewController {
    
    private var observerObject: NSObjectProtocol!
    
    private var workoutHistory = WorkoutHistory.load() {
        didSet {
            guard oldValue != workoutHistory && isViewLoaded else { return }
            tableView.reloadData()
        }
    }
    
    // MARK: Initialization
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Add a notification handler for when the application becomes active.
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(forName: .UIApplicationDidBecomeActive, object: nil, queue: nil) { _ in
            self.workoutHistory = WorkoutHistory.load()
        }
    }
    
    deinit {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(observerObject)
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workoutHistory.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WorkoutCell.reuseIdentifier, for: indexPath) as? WorkoutCell else { fatalError("Unable to dequeue a WorkoutCell") }
        
        let workout = self.workout(at: indexPath)
        
        cell.climbDescriptionLabel.text = workout.climbDescription
        cell.goalDescriptionLabel.text = workout.goalDescription
        cell.stateLabel.text = workout.stateDescription
        
        // Allow the user to select any active workouts.
        cell.selectionStyle = workout.state == .ended ? .none : .default
        
        return cell
    }

    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Determine the actions to show in an action sheet for the selected workout.
        let workout = self.workout(at: indexPath)
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        switch workout.state {
            case .active:
                let action = UIAlertAction(title: "Pause Workout", style: .default) { _ in
                    self.workoutHistory.pauseActiveWorkout()
                }
                alertController.addAction(action)
            
            case .paused:
                let action = UIAlertAction(title: "Resume Workout", style: .default) { _ in
                    self.workoutHistory.pauseActiveWorkout()
                }
                alertController.addAction(action)
            
            case .ended:
                return
        }

        alertController.addAction(UIAlertAction(title: "End Workout", style: .default) { _ in
            self.workoutHistory.endActiveWorkout()
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in })

        // Present the configured action sheet.
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: UIResponder
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        super.restoreUserActivityState(activity)

        // Check this is an activity we can handle.
        guard let activityType = activity.ascentActivityType else { return }
        
        switch activityType {
            case .start(let workout):
                workoutHistory.start(newWorkout: workout)
                
            case .endWorkout, .cancelWorkout:
                workoutHistory.endActiveWorkout()
                
            case .pauseWorkout:
                workoutHistory.pauseActiveWorkout()
                
            case .resumeWorkout:
                workoutHistory.resumeActiveWorkout()
        }
    }
    
    // MARK: Convenience
    
    private func workout(at indexPath: IndexPath) -> Workout {
        let reversedWorkouts = workoutHistory.reversed()
        return reversedWorkouts[indexPath.row]
    }
}



class WorkoutCell: UITableViewCell {
    static let reuseIdentifier = "WorkoutCell"
    
    @IBOutlet weak var climbDescriptionLabel: UILabel!

    @IBOutlet weak var goalDescriptionLabel: UILabel!
    
    @IBOutlet weak var stateLabel: UILabel!
}
