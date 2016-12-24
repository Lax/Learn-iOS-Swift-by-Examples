/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A struct that wraps saving and restoring `Workout`s from shared user defaults.
*/

import Foundation

public struct WorkoutHistory {
    
    var workouts: [Workout]
    
    public var count: Int {
        return workouts.count
    }
    
    public subscript(index: Int) -> Workout {
        get {
            return workouts[index]
        }
        
        set(newValue) {
            workouts[index] = newValue
        }
    }
    
    public var last: Workout? {
        return workouts.last
    }

    // MARK: Initialization
    
    private init(workouts: [Workout]) {
        self.workouts = workouts
    }

    // MARK: Load and save
    
    public static func load() -> WorkoutHistory {
        var workouts = [Workout]()
        let defaults = WorkoutHistory.makeUserDefaults()
        
        if let savedWorkouts = defaults.object(forKey: "workouts") as? [[String: AnyObject]] {
            for dictionary in savedWorkouts {
                if let workout = Workout(dictionaryRepresentation: dictionary) {
                    workouts.append(workout)
                }
            }
        }
        
        return WorkoutHistory(workouts: workouts)
    }
    
    func save() {
        let workoutDictionaries: [[String: AnyObject]] = workouts.map { $0.dictionaryRepresentation }
        let defaults = WorkoutHistory.makeUserDefaults()
        
        defaults.set(workoutDictionaries as AnyObject, forKey: "workouts")
    }
    
    // MARK: Convenience
    
    private static func makeUserDefaults() -> UserDefaults {
        guard let defaults = UserDefaults(suiteName: "group.com.example.apple-samplecode.Ascent") else { fatalError("Unable to create user defaults object") }
        return defaults
    }
}


extension WorkoutHistory: Sequence {
    public typealias Iterator = AnyIterator<Workout>
    
    public func makeIterator() -> Iterator {
        var index = 0
        
        return Iterator {
            guard index < self.workouts.count else { return nil }
            
            let workout = self.workouts[index]
            index += 1
            
            return workout
        }
    }
}



extension WorkoutHistory: Equatable {}

public func ==(lhs: WorkoutHistory, rhs: WorkoutHistory) -> Bool {
    return lhs.workouts == rhs.workouts
}
