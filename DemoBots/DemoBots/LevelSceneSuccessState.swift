/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used by `LevelScene` to indicate that the player completed a level successfully.
*/

import SpriteKit
import GameplayKit

class LevelSceneSuccessState: LevelSceneOverlayState {
    // MARK: Properties
    
    override var overlaySceneFileName: String {
        return "SuccessScene"
    }
    
    // MARK: GKState Life Cycle
    
    override func didEnterWithPreviousState(previousState: GKState?) {
        super.didEnterWithPreviousState(previousState)
        
        if let inputComponent = levelScene.playerBot.componentForClass(InputComponent.self) {
            inputComponent.isEnabled = false
        }
        
        // Begin preloading the next scene in preparation for the user to advance.
        levelScene.sceneManager.prepareSceneWithSceneIdentifier(.NextLevel)
    }
    
    override func isValidNextState(stateClass: AnyClass) -> Bool {
        return false
    }
}
