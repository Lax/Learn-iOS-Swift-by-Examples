/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used to represent the player at level start when being 'beamed' into the level.
*/

import SpriteKit
import GameplayKit

class PlayerBotAppearState: GKState {
    // MARK: Properties
    
    unowned var entity: PlayerBot
    
    /// The amount of time the `PlayerBot` has been in the "appear" state.
    var elapsedTime: TimeInterval = 0.0
    
    /// The `AnimationComponent` associated with the `entity`.
    var animationComponent: AnimationComponent {
        guard let animationComponent = entity.component(ofType: AnimationComponent.self) else { fatalError("A PlayerBotAppearState's entity must have an AnimationComponent.") }
        return animationComponent
    }
    
    /// The `RenderComponent` associated with the `entity`.
    var renderComponent: RenderComponent {
        guard let renderComponent = entity.component(ofType: RenderComponent.self) else { fatalError("A PlayerBotAppearState's entity must have an RenderComponent.") }
        return renderComponent
    }
    
    /// The `OrientationComponent` associated with the `entity`.
    var orientationComponent: OrientationComponent {
        guard let orientationComponent = entity.component(ofType: OrientationComponent.self) else { fatalError("A PlayerBotAppearState's entity must have an OrientationComponent.") }
        return orientationComponent
    }
    
    /// The `InputComponent` associated with the `entity`.
    var inputComponent: InputComponent {
        guard let inputComponent = entity.component(ofType: InputComponent.self) else { fatalError("A PlayerBotAppearState's entity must have an InputComponent.") }
        return inputComponent
    }
    
    /// The `SKSpriteNode` used to show the player animating into the scene.
    var node = SKSpriteNode()
    
    // MARK: Initializers
    
    required init(entity: PlayerBot) {
        self.entity = entity
    }
    
    // MARK: GKState Life Cycle
    
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        
        // Reset the elapsed time.
        elapsedTime = 0.0
        
        /*
            The `PlayerBot` is about to appear in the level. We use an `SKShader` to
            provide a "teleport" effect to beam in the `PlayerBot`.
        */
        
        // Retrieve and use an initial texture for the `PlayerBot`, taken from the appropriate idle animation.
        guard let appearTextures = PlayerBot.appearTextures else {
            fatalError("Attempt to access PlayerBot.appearTextures before they have been loaded.")
        }
        let texture = appearTextures[orientationComponent.compassDirection]!
        node.texture = texture
        node.size = PlayerBot.textureSize

        // Add an `SKShader` to the node to render the "teleport" effect.
        node.shader = PlayerBot.teleportShader
        
        // Add the node to the `PlayerBot`'s render node.
        renderComponent.node.addChild(node)
        
        // Hide the animation component node until the `PlayerBot` exits this state.
        animationComponent.node.isHidden = true

        // Disable the input component while the `PlayerBot` appears.
        inputComponent.isEnabled = false
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        
        // Update the amount of time that the `PlayerBot` has been teleporting in to the level.
        elapsedTime += seconds

        // Check if we have spent enough time
        if elapsedTime > GameplayConfiguration.PlayerBot.appearDuration {
            // Remove the node from the scene
            node.removeFromParent()
            
            // Switch the `PlayerBot` over to a "player controlled" state.
            stateMachine?.enter(PlayerBotPlayerControlledState.self)
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is PlayerBotPlayerControlledState.Type
    }
    
    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)
        
        // Un-hide the animation component node.
        animationComponent.node.isHidden = false
        
        // Re-enable the input component
        inputComponent.isEnabled = true
    }
}
