/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used by `SceneLoader` to indicate that all of the resources for the scene are available.
*/

import GameplayKit

class SceneLoaderResourcesAvailableState: GKState {
    // MARK: Properties
    
    unowned let sceneLoader: SceneLoader
    
    // MARK: Initialization
    
    init(sceneLoader: SceneLoader) {
        self.sceneLoader = sceneLoader
    }
    
    // MARK: GKState Life Cycle
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
            case is SceneLoaderInitialState.Type, is SceneLoaderPreparingResourcesState.Type:
                return true
            
            default:
                return false
        }
    }
    
}
