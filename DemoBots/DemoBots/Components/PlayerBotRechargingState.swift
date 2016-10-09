/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used to represent the player when immobilized by `TaskBot` attacks.
*/

import SpriteKit
import GameplayKit

class PlayerBotRechargingState: GKState {
    // MARK: Properties
    
    unowned var entity: PlayerBot
    
    /// The amount of time the `PlayerBot` has been in the "recharging" state.
    var elapsedTime: TimeInterval = 0.0
    
    /// The `AnimationComponent` associated with the `entity`.
    var animationComponent: AnimationComponent {
        guard let animationComponent = entity.component(ofType: AnimationComponent.self) else { fatalError("A PlayerBotRechargingState's entity must have an AnimationComponent.") }
        return animationComponent
    }
    
    /// The `ChargeComponent` associated with the `entity`.
    var chargeComponent: ChargeComponent {
        guard let chargeComponent = entity.component(ofType: ChargeComponent.self) else { fatalError("A PlayerBotRechargingState's entity must have a ChargeComponent.") }
        return chargeComponent
    }
    
    // MARK: Initializers
    
    required init(entity: PlayerBot) {
        self.entity = entity
    }
    
    // MARK: GKState life cycle
    
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        
        // Reset the recharge duration when entering this state.
        elapsedTime = 0.0
        
        // Request the "inactive" animation for the `PlayerBot`.
        animationComponent.requestedAnimationState = .inactive
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        
        // Update the elapsed recharge duration.
        elapsedTime += seconds

        /**
            There is a delay from when the `PlayerBot` enters this state to when it begins to recharge.
            Do nothing if the `PlayerBot` hasn't been in this state long enough.
        */
        if elapsedTime < GameplayConfiguration.PlayerBot.rechargeDelayWhenInactive { return }

        // `chargeComponent` is a computed property. Declare a local version so we don't compute it multiple times.
        let chargeComponent = self.chargeComponent

        // Add charge to the `PlayerBot`.
        let amountToRecharge = GameplayConfiguration.PlayerBot.rechargeAmountPerSecond * seconds
        chargeComponent.addCharge(chargeToAdd: amountToRecharge)
        
        // If the `PlayerBot` is fully charged it can become player controlled again.
        if chargeComponent.isFullyCharged {
            entity.isPoweredDown = false
            stateMachine?.enter(PlayerBotPlayerControlledState.self)
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is PlayerBotPlayerControlledState.Type
    }
}
