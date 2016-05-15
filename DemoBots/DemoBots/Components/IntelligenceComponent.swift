/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `GKComponent` that provides a `GKStateMachine` for entities to use in determining their actions.
*/

import SpriteKit
import GameplayKit

class IntelligenceComponent: GKComponent {
    
    // MARK: Properties
    
    let stateMachine: GKStateMachine
    
    let initialStateClass: AnyClass
    
    // MARK: Initializers
    
    init(states: [GKState]) {
        stateMachine = GKStateMachine(states: states)
        initialStateClass = states.first!.dynamicType
    }
    
    // MARK: GKComponent Life Cycle

    override func updateWithDeltaTime(seconds: NSTimeInterval) {
        super.updateWithDeltaTime(seconds)

        stateMachine.updateWithDeltaTime(seconds)
    }
    
    // MARK: Actions
    
    func enterInitialState() {
        stateMachine.enterState(initialStateClass)
    }
}
