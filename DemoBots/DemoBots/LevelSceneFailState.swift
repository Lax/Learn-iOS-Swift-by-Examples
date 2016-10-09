/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used by `LevelScene` to indicate that the player failed to complete a level.
*/

import SpriteKit
import GameplayKit

class LevelSceneFailState: LevelSceneOverlayState {
    // MARK: Properties
    
    override var overlaySceneFileName: String {
        return "FailScene"
    }

    // MARK: GKState Life Cycle
    
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        if let inputComponent = levelScene.playerBot.component(ofType: InputComponent.self) {
            inputComponent.isEnabled = false
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return false
    }
}
