/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `GKComponent` that provides and manages the actions used to animate characters on screen as they move through different states and face different directions. `AnimationComponent` is supported by a structure called `Animation` that encapsulates information about an individual animation.
*/

import SpriteKit
import GameplayKit

/// The different animation states that an animated character can be in.
enum AnimationState: String {
    case idle = "Idle"
    case walkForward = "WalkForward"
    case walkBackward = "WalkBackward"
    case preAttack = "PreAttack"
    case attack = "Attack"
    case zapped = "Zapped"
    case hit = "Hit"
    case inactive = "Inactive"
}

/**
    Encapsulates all of the information needed to animate an entity and its shadow
    for a given animation state and facing direction.
*/
struct Animation {

    // MARK: Properties
    
    /// The animation state represented in this animation.
    let animationState: AnimationState
    
    /// The direction the entity is facing during this animation.
    let compassDirection: CompassDirection
    
    /// One or more `SKTexture`s to animate as a cycle for this animation.
    let textures: [SKTexture]
    
    /**
        The offset into the `textures` array to use as the first frame of the animation.
        Defaults to zero, but will be updated if a copy of this animation decides to offset
        the starting frame to continue smoothly from the end of a previous animation.
    */
    var frameOffset = 0
    
    /**
        An array of textures that runs from the animation's `frameOffset` to its end,
        followed by the textures from its start to just before the `frameOffset`.
    */
    var offsetTextures: [SKTexture] {
        if frameOffset == 0 {
            return textures
        }
        let offsetToEnd = Array(textures[frameOffset..<textures.count])
        let startToBeforeOffset = textures[0..<frameOffset]
        return offsetToEnd + startToBeforeOffset
    }

    /// Whether this action's `textures` array should be repeated forever when animated.
    let repeatTexturesForever: Bool

    /// The name of an optional action for this entity's body, loaded from an action file.
    let bodyActionName: String?

    /// The optional action for this entity's body, loaded from an action file.
    let bodyAction: SKAction?

    /// The name of an optional action for this entity's shadow, loaded from an action file.
    let shadowActionName: String?

    /// The optional action for this entity's shadow, loaded from an action file.
    let shadowAction: SKAction?
}

class AnimationComponent: GKComponent {
    
    /// The key to use when adding an optional action to the entity's body.
    static let bodyActionKey = "bodyAction"

    /// The key to use when adding an optional action to the entity's shadow.
    static let shadowActionKey = "shadowAction"

    /// The key to use when adding a texture animation action to the entity's body.
    static let textureActionKey = "textureAction"

    /// The time to display each frame of a texture animation.
    static let timePerFrame = TimeInterval(1.0 / 10.0)
    
    // MARK: Properties
    
    /**
        The most recent animation state that the animation component has been requested to play,
        but has not yet started playing.
    */
    var requestedAnimationState: AnimationState?
    
    /// The node on which animations should be run for this animation component.
    let node: SKSpriteNode
    
    /// The node for the entity's shadow (to be set by the entity if needed).
    var shadowNode: SKSpriteNode?
    
    /// The current set of animations for the component's entity.
    var animations: [AnimationState: [CompassDirection: Animation]]
    
    /// The animation that is currently running.
    private(set) var currentAnimation: Animation?
    
    /// The length of time spent in the current animation state and direction.
    private var elapsedAnimationDuration: TimeInterval = 0.0
    
    // MARK: Initializers

    init(textureSize: CGSize, animations: [AnimationState: [CompassDirection: Animation]]) {
        node = SKSpriteNode(texture: nil, size: textureSize)
        self.animations = animations
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Character Animation

    private func runAnimationForAnimationState(animationState: AnimationState, compassDirection: CompassDirection, deltaTime: TimeInterval) {
        
        // Update the tracking of how long we have been animating.
        elapsedAnimationDuration += deltaTime
        
        // Check if we are already running this animation. There's no need to do anything if so.
        if currentAnimation != nil && currentAnimation!.animationState == animationState && currentAnimation!.compassDirection == compassDirection { return }

        /*
            Retrieve a copy of the stored animation for the requested state and compass direction.
            `Animation` is a structure - i.e. a value type - so the `animation` variable below
            will contain a unique copy of the animation's data.
            We request this copy as a variable (rather than a constant) so that the
            `animation` variable's `frameOffset` property can be modified later in this method
            if we choose to offset the animation's start point from zero.
        */
        guard let unwrappedAnimation = animations[animationState]?[compassDirection] else {
            print("Unknown animation for state \(animationState.rawValue), compass direction \(compassDirection.rawValue).")
            return
        }
        var animation = unwrappedAnimation
        
        // Check if the action for the body node has changed.
        if currentAnimation?.bodyActionName != animation.bodyActionName {
            // Remove the existing body action if it exists.
            node.removeAction(forKey: AnimationComponent.bodyActionKey)
            
            // Reset the node's position in its parent (it may have been animating with a move action).
            node.position = CGPoint.zero

            // Add the new body action to the node if an action exists.
            if let bodyAction = animation.bodyAction {
                node.run(SKAction.repeatForever(bodyAction), withKey: AnimationComponent.bodyActionKey)
            }
        }

        // Check if the action for the shadow node has changed.
        if currentAnimation?.shadowActionName != animation.shadowActionName {
            // Remove the existing shadow action if it exists.
            shadowNode?.removeAction(forKey: AnimationComponent.shadowActionKey)

            // Reset the node's position in its parent (it may have been animating with a move action).
            shadowNode?.position = CGPoint.zero

            // Reset the node's scale (it may have been changed with a resize action).
            shadowNode?.xScale = 1.0
            shadowNode?.yScale = 1.0
            
            // Add the new shadow action to the shadow node if an action exists.
            if let shadowAction = animation.shadowAction {
                shadowNode?.run(SKAction.repeatForever(shadowAction), withKey: AnimationComponent.shadowActionKey)
            }
        }

        // Remove the existing texture animation action if it exists.
        node.removeAction(forKey: AnimationComponent.textureActionKey)

        // Create a new action to display the appropriate animation textures.
        let texturesAction: SKAction
        
        if animation.textures.count == 1 {
            // If the new animation only has a single frame, create a simple "set texture" action.
            texturesAction = SKAction.setTexture(animation.textures.first!)
        }
        else {
            
            if currentAnimation != nil && animationState == currentAnimation!.animationState {
                /*
                    We have just changed facing direction within the same animation state.
                    To make the animation feel smooth as we change direction,
                    begin the animation for the new direction on the frame after
                    the last frame displayed for the old direction.
                    This prevents (e.g.) a walk cycle from resetting to its start
                    every time a character turns to the left or right.
                */
                
                // Work out how many frames of this animation have played since the animation began.
                let numberOfFramesInCurrentAnimation = currentAnimation!.textures.count
                let numberOfFramesPlayedSinceCurrentAnimationBegan = Int(elapsedAnimationDuration / AnimationComponent.timePerFrame)
                
                /*
                    Work out how far into the animation loop the next frame would be.
                    This takes into account the fact that the current animation may have been
                    started from a non-zero offset.
                */
                animation.frameOffset = (currentAnimation!.frameOffset + numberOfFramesPlayedSinceCurrentAnimationBegan + 1) % numberOfFramesInCurrentAnimation
            }
            
            // Create an appropriate action from the (possibly offset) animation frames.
            if animation.repeatTexturesForever {
                texturesAction = SKAction.repeatForever(SKAction.animate(with: animation.offsetTextures, timePerFrame: AnimationComponent.timePerFrame))
            }
            else {
                texturesAction = SKAction.animate(with: animation.offsetTextures, timePerFrame: AnimationComponent.timePerFrame)
            }
        }
        
        // Add the textures animation to the body node.
        node.run(texturesAction, withKey: AnimationComponent.textureActionKey)
        
        // Remember the animation we are currently running.
        currentAnimation = animation
        
        // Reset the "how long we have been animating" counter.
        elapsedAnimationDuration = 0.0
    }
    
    // MARK: GKComponent Life Cycle
    
    override func update(deltaTime: TimeInterval) {
        super.update(deltaTime: deltaTime)
        
        // If an animation has been requested, run the animation.
        if let animationState = requestedAnimationState {
            guard let orientationComponent = entity?.component(ofType: OrientationComponent.self) else { fatalError("An AnimationComponent's entity must have an OrientationComponent.") }
            
            runAnimationForAnimationState(animationState: animationState, compassDirection: orientationComponent.compassDirection, deltaTime: deltaTime)
            requestedAnimationState = nil
        }
    }
    
    // MARK: Texture loading utilities

    /// Returns the first texture in an atlas for a given `CompassDirection`.
    class func firstTextureForOrientation(compassDirection: CompassDirection, inAtlas atlas: SKTextureAtlas, withImageIdentifier identifier: String) -> SKTexture {
        // Filter for this facing direction, and sort the resulting texture names alphabetically.
        let textureNames = atlas.textureNames.filter {
            $0.hasPrefix("\(identifier)_\(compassDirection.rawValue)_")
        }.sorted()
        
        // Find and return the first texture for this direction.
        return atlas.textureNamed(textureNames.first!)
    }
    
    /// Creates a texture action from all textures in an atlas.
    class func actionForAllTexturesInAtlas(atlas: SKTextureAtlas) -> SKAction {
        // Sort the texture names alphabetically, and map them to an array of actual textures.
        let textures = atlas.textureNames.sorted().map {
            atlas.textureNamed($0)
        }

        // Create an appropriate action for these textures.
        if textures.count == 1 {
            return SKAction.setTexture(textures.first!)
        }
        else {
            let texturesAction = SKAction.animate(with: textures, timePerFrame: AnimationComponent.timePerFrame)
            return SKAction.repeatForever(texturesAction)
        }
    }

    /// Creates an `Animation` from textures in an atlas and actions loaded from file.
    class func animationsFromAtlas(atlas: SKTextureAtlas, withImageIdentifier identifier: String, forAnimationState animationState: AnimationState, bodyActionName: String? = nil, shadowActionName: String? = nil, repeatTexturesForever: Bool = true, playBackwards: Bool = false) -> [CompassDirection: Animation] {
        // Load a body action from an actions file if requested.
        let bodyAction: SKAction?
        if let name = bodyActionName {
            bodyAction = SKAction(named: name)
        }
        else {
            bodyAction = nil
        }

        // Load a shadow action from an actions file if requested.
        let shadowAction: SKAction?
        if let name = shadowActionName {
            shadowAction = SKAction(named: name)
        }
        else {
            shadowAction = nil
        }
        
        /// A dictionary of animations with an entry for each compass direction.
        var animations = [CompassDirection: Animation]()
        
        for compassDirection in CompassDirection.allDirections {
            
            // Find all matching texture names, sorted alphabetically, and map them to an array of actual textures.
            let textures = atlas.textureNames.filter {
                $0.hasPrefix("\(identifier)_\(compassDirection.rawValue)_")
            }.sorted {
                playBackwards ? $0 > $1 : $0 < $1
            }.map {
                atlas.textureNamed($0)
            }
            
            // Create a new `Animation` for these settings.
            animations[compassDirection] = Animation(
                animationState: animationState,
                compassDirection: compassDirection,
                textures: textures,
                frameOffset: 0,
                repeatTexturesForever: repeatTexturesForever,
                bodyActionName: bodyActionName,
                bodyAction: bodyAction,
                shadowActionName: shadowActionName,
                shadowAction: shadowAction
            )
            
        }
        
        return animations
    }
    
}
