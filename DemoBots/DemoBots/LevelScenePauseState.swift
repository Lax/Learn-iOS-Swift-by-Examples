/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used by `LevelScene` to provide appropriate UI via an overlay scene when the game is paused.
*/

import SpriteKit
import GameplayKit

class LevelScenePauseState: LevelSceneOverlayState {
    // MARK: Properties

    override var overlaySceneFileName: String {
        return "PauseScene"
    }
    
    // MARK: GKState Life Cycle
    
    override func didEnterWithPreviousState(previousState: GKState?) {
        super.didEnterWithPreviousState(previousState)
        
        levelScene.worldNode.paused = true
    }
    
    override func isValidNextState(stateClass: AnyClass) -> Bool {
        return stateClass is LevelSceneActiveState.Type
    }

    override func willExitWithNextState(nextState: GKState) {
        super.willExitWithNextState(nextState)
        
        levelScene.worldNode.paused = false
    }
}
