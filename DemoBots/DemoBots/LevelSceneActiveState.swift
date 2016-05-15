/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used by `LevelScene` to indicate that the game is actively being played. This state updates the current time of the level's countdown timer.
*/

import SpriteKit
import GameplayKit

class LevelSceneActiveState: GKState {
    // MARK: Properties
    
    unowned let levelScene: LevelScene
    
    var timeRemaining: NSTimeInterval = 0.0
    
    /*
        A formatter for individual date components used to provide an appropriate
        display value for the timer.
    */
    let timeRemainingFormatter: NSDateComponentsFormatter = {
        let formatter = NSDateComponentsFormatter()
        formatter.zeroFormattingBehavior = .Pad
        formatter.allowedUnits = [.Minute, .Second]
        
        return formatter
    }()
    
    // The formatted string representing the time remaining.
    var timeRemainingString: String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, timeRemaining))
        
        return timeRemainingFormatter.stringFromDateComponents(components)!
    }
    
    // MARK: Initializers
    
    init(levelScene: LevelScene) {
        self.levelScene = levelScene
        
        timeRemaining = levelScene.levelConfiguration.timeLimit
    }
    
    // MARK: GKState Life Cycle
    
    override func didEnterWithPreviousState(previousState: GKState?) {
        super.didEnterWithPreviousState(previousState)

        levelScene.timerNode.text = timeRemainingString
    }
    
    override func updateWithDeltaTime(seconds: NSTimeInterval) {
        super.updateWithDeltaTime(seconds)
        
        // Subtract the elapsed time from the remaining time.
        timeRemaining -= seconds
        
        // Update the displayed time remaining.
        levelScene.timerNode.text = timeRemainingString
        
        // Check if the `levelScene` contains any bad `TaskBot`s.
        let allTaskBotsAreGood = !levelScene.entities.contains { entity in
            if let taskBot = entity as? TaskBot {
                return !taskBot.isGood
            }
            
            return false
        }
        
        if allTaskBotsAreGood {
            // If all the TaskBots are good, the player has completed the level.
            stateMachine?.enterState(LevelSceneSuccessState.self)
        }
        else if timeRemaining <= 0.0 {
            // If there is no time remaining, the player has failed to complete the level.
            stateMachine?.enterState(LevelSceneFailState.self)
        }
    }
    
    override func isValidNextState(stateClass: AnyClass) -> Bool {
        switch stateClass {
            case is LevelScenePauseState.Type, is LevelSceneFailState.Type, is LevelSceneSuccessState.Type:
                return true
                
            default:
                return false
        }
    }
}
