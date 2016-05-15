/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The state of the `PlayerBot`'s beam when not in use.
*/

import SpriteKit
import GameplayKit

class BeamIdleState: GKState {
    // MARK: Properties
    
    unowned var beamComponent: BeamComponent
    
    // MARK: Initializers
    
    required init(beamComponent: BeamComponent) {
        self.beamComponent = beamComponent
    }
    
    // MARK: GKState life cycle
    
    override func updateWithDeltaTime(seconds: NSTimeInterval) {
        super.updateWithDeltaTime(seconds)
        
        // If the beam has been triggered, enter `BeamFiringState`.
        if beamComponent.isTriggered {
            stateMachine?.enterState(BeamFiringState.self)
        }
    }
    
    override func isValidNextState(stateClass: AnyClass) -> Bool {
        return stateClass is BeamFiringState.Type
    }
}
