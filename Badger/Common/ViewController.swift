/*
     Copyright (C) 2016 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     The main ViewController used to host the scene and 
                 configure gameplay.
 */

import GameKit
import AVFoundation

#if os(iOS) || os(tvOS)
typealias BaseViewController = UIViewController
#elseif os(OSX)
typealias BaseViewController = NSViewController
#endif

class ViewController: BaseViewController, SCNSceneRendererDelegate {
    // MARK: Types
    
    struct Assets {
        static let basePath = "badger.scnassets/"
        private static let soundsPath = basePath + "sounds/"
        
        static func sound(named name: String) -> SCNAudioSource {
            guard let source = SCNAudioSource(named: soundsPath + name) else {
                fatalError("Failed to load audio source \(name).")
            }
            return source
        }
        
        static func animation(named name: String) -> CAAnimation {
            return CAAnimation.animation(withSceneName: basePath + name)
        }
        
        static func scene(named name: String) -> SCNScene {
            guard let scene = SCNScene(named: basePath + name) else {
                fatalError("Failed to load scene \(name).")
            }
            return scene
        }
    }
    
    struct Trigger {
        let position: float3
        let action: (ViewController) -> ()
    }
    
    private enum CollectableState: UInt {
        case notCollected = 0
        case beingCollected = 2
    }
    
    private enum GameState: UInt {
        case notStarted = 0
        case started = 1
    }
    
    // MARK: Configuration Properties
    
    /// Determines if the level uses local sun.
    let isUsingLocalSun = true
    
    /// Determines if audio should be enabled.
    let isSoundEnabled = true

    let speedFactor: Float = 1.5
    
    // MARK: Scene Properties
    
    @IBOutlet var sceneView: View!
    
    let scene = Assets.scene(named: "scene.scn")
    
    // MARK: Animation Properties

    let character: SCNNode
    let idleAnimationOwner: SCNNode

    let cartAnimationName: String
    
    /** 
       These animations will be played when the user performs an action
       and will temporarily disable the "idle" animation.
    */
    
    let jumpAnimation      = Assets.animation(named: "animation-jump.scn")
    let squatAnimation     = Assets.animation(named: "animation-squat.scn")
    let leanLeftAnimation  = Assets.animation(named: "animation-lean-left.scn")
    let leanRightAnimation = Assets.animation(named: "animation-lean-right.scn")
    let slapAnimation      = Assets.animation(named: "animation-slap.scn")
    
    let leftHand: SCNNode
    let rightHand: SCNNode
    
    var sunTargetRelativeToCamera: SCNVector3
    var sunDirection: SCNVector3
    var sun: SCNNode
    
    // Sparkles effect
    var sparkles: SCNParticleSystem
    var stars: SCNParticleSystem
    var leftWheelEmitter: SCNNode
    var rightWheelEmitter: SCNNode
    var headEmitter: SCNNode
    var wheels: SCNNode

    // Collect particles
    var collectParticleSystem: SCNParticleSystem
    var collectBigParticleSystem: SCNParticleSystem

    // State
    var squatCounter = 0
    var isOverWood = false
    
    // MARK: Sound Properties
    
    var railSoundSpeed: UInt = 0
    
    let hitSound             = Assets.sound(named: "hit.mp3")
    let railHighSpeedSound   = Assets.sound(named: "rail_highspeed_loop.mp3")
    let railMediumSpeedSound = Assets.sound(named: "rail_normalspeed_loop.mp3")
    let railLowSpeedSound    = Assets.sound(named: "rail_slowspeed_loop.mp3")
    let railWoodSound        = Assets.sound(named: "rail_wood_loop.mp3")
    let railSqueakSound      = Assets.sound(named: "cart_turn_squeak.mp3")
    let cartHide             = Assets.sound(named: "cart_hide.mp3")
    let cartJump             = Assets.sound(named: "cart_jump.mp3")
    let cartTurnLeft         = Assets.sound(named: "cart_turn_left.mp3")
    let cartTurnRight        = Assets.sound(named: "cart_turn_right.mp3")
    let cartBoost            = Assets.sound(named: "cart_boost.mp3")
    
    // MARK: Collectable Properties
    
    let collectables: SCNNode
    let speedItems: SCNNode
    let collectSound = Assets.sound(named: "collect1.mp3")
    let collectSound2 = Assets.sound(named: "collect2.mp3")
    
    // MARK: Triggers
    
    /// Triggers are configured in `configureScene()`.
    var triggers = [Trigger]()
    var activeTriggerIndex = -1

    // MARK: Game controls
    
    var controllerDPad: GCControllerDirectionPad?
    
    /// Game state
    private var gameState: GameState = .notStarted

    // MARK: View Controller Initialization
    
    #if os(iOS) || os(tvOS)
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(coder:) has not been implemented")
    }
    #elseif os(OSX)
    override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(coder:) has not been implemented")
    }
    #endif
    
    required init?(coder: NSCoder) {
        // Retrieve the character and its animations.
     
        // The character node "Bob_root" initially is a placeholder.
        // We will load the models from one of the animation scenes and add them to the empty node.
        character = scene.rootNode.childNode(withName: "Bob_root", recursively: true)!
        
        let idleScene = Assets.scene(named: "animation-idle.scn")
        let characterHierarchy = idleScene.rootNode.childNode(withName: "Bob_root", recursively: true)!
        
        for node in characterHierarchy.childNodes {
            character.addChildNode(node)
        }
        
        idleAnimationOwner = character.childNode(withName: "Dummy_kart_root", recursively: true)!
        
        // The animation for the cart is always running. The name of the animation is retrieved
        // so that we can change its speed as the cart accelerates or decelerates.
        cartAnimationName = scene.rootNode.animationKeys.first!
        
        // Play character idle animation.
        let idleAnimation = Assets.animation(named: "animation-start-idle.scn")
        idleAnimation.repeatCount = Float.infinity
        character.addAnimation(idleAnimation, forKey: "start")
        
        // Load sparkles.
        let sparkleScene = Assets.scene(named: "sparkles.scn")
        let sparkleNode = sparkleScene.rootNode.childNode(withName: "sparkles", recursively: true)!
        sparkles = sparkleNode.particleSystems![0]
        sparkles.loops = false

        let starsNode = sparkleScene.rootNode.childNode(withName: "slap", recursively: true)!
        stars = starsNode.particleSystems![0]
        stars.loops = false
        
        // Collect particles.
        collectParticleSystem = SCNParticleSystem(named: "collect.scnp", inDirectory: "badger.scnassets")!
        collectParticleSystem.loops = false
        
        collectBigParticleSystem = SCNParticleSystem(named: "collect-big.scnp", inDirectory: "badger.scnassets")!
        collectBigParticleSystem.loops = false
        
        leftHand = character.childNode(withName: "Bip001_L_Finger0Nub", recursively: true)!
        rightHand = character.childNode(withName: "Bip001_R_Finger0Nub", recursively: true)!

        leftWheelEmitter = character.childNode(withName: "Dummy_rightWheel_sparks", recursively: true)!
        rightWheelEmitter = character.childNode(withName: "Dummy_leftWheel_sparks", recursively: true)!
        wheels = character.childNode(withName: "wheels_front", recursively: true)!
        
        headEmitter = SCNNode()
        headEmitter.position = SCNVector3Make(0, 1, 0)
        character.addChildNode(headEmitter)
        
        let wheelAnimation = CABasicAnimation(keyPath: "eulerAngles.x")
        wheelAnimation.byValue = 10.0
        wheelAnimation.duration = 1.0
        wheelAnimation.repeatCount = Float.infinity
        wheelAnimation.isCumulative = true
        wheels.addAnimation(wheelAnimation, forKey: "wheel");
        
        // Make sure the slap animation plays right away (no fading)
        slapAnimation.fadeInDuration = 0.0
        
        /// Similarly collectables are grouped under a common parent node.
        /// In addition, load a sound file that will be played when the user collects an item.
        collectables = scene.rootNode.childNode(withName: "Collectables", recursively: false)!
        speedItems = scene.rootNode.childNode(withName: "SpeedItems", recursively: false)!
        
        // Load sounds.
        collectSound.volume = 5.0
        collectSound2.volume = 5.0

        // Configure sounds.
        let sounds = [
            railSqueakSound, collectSound, collectSound2,
            hitSound, railHighSpeedSound, railMediumSpeedSound,
            railLowSpeedSound, railWoodSound, railSqueakSound,
            cartHide, cartJump, cartTurnLeft,
            cartTurnRight
        ]
        
        for sound in sounds {
            sound.isPositional = false
            sound.load()
        }
        
        railSqueakSound.loops = true
        
        // Configure the scene to use a local sun.
        if isUsingLocalSun {
            sun = scene.rootNode.childNode(withName: "Direct001", recursively: false)!
            sun.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
            sun.light?.orthographicScale = 10
            
            sunTargetRelativeToCamera = SCNVector3(x:0, y:0, z:-10)
            sun.position = SCNVector3Zero
            sunDirection = sun.convertPosition(SCNVector3(x:0, y:0, z:-1), to: nil)
        }
        else {
            sun = SCNNode()
            sunTargetRelativeToCamera = SCNVector3Zero
            sunDirection = SCNVector3Zero
        }
        
        super.init(coder: coder)
    }

    func configureScene() {
        // Add sparkles.
        let leftEvent1 = SCNAnimationEvent(keyTime: 0.15) { [unowned self] _ in
            self.leftWheelEmitter.addParticleSystem(self.sparkles)
        }
        let leftEvent2 = SCNAnimationEvent(keyTime: 0.9) { [unowned self] _ in
            self.rightWheelEmitter.addParticleSystem(self.sparkles)
        }
        let rightEvent1 = SCNAnimationEvent(keyTime: 0.9) { [unowned self] _ in
            self.leftWheelEmitter.addParticleSystem(self.sparkles)
        }
        leanLeftAnimation.animationEvents = [leftEvent1, leftEvent2]
        leanRightAnimation.animationEvents = [rightEvent1]

        sceneView.antialiasingMode = .none
        
        // Configure triggers and collectables
        
        /// Special nodes ("triggers") are placed in the scene under a common parent node.
        /// Their names indicate what event should occur as they are hit by the cart.
        let triggerGroup = scene.rootNode.childNode(withName: "triggers", recursively: false)!
        
        triggers = triggerGroup.childNodes.flatMap { node in
            let triggerName = node.name! as NSString
            let triggerPosition = float3(node.position)
            
            if triggerName.hasPrefix("Trigger_speed") {
                let speedValueOffset = "Trigger_speedX_".characters.count
                var speedValue = triggerName.substring(from: speedValueOffset)
                speedValue = speedValue.replacingOccurrences(of: "_", with: ".")
                
                guard let speed = Float(speedValue) else {
                    print("Failed to parse speed value \(speedValue).")
                    return nil
                }
                
                return Trigger(position: triggerPosition, action: { controller in
                    controller.trigger(characterSpeed: speed)
                })
            }
            
            if triggerName.hasPrefix("Trigger_obstacle") {
                return Trigger(position: triggerPosition, action: { controller in
                    controller.triggerCollision()
                })
            }
            
            if triggerName.hasPrefix("Trigger_reverb") && triggerName.hasSuffix("start") {
                return Trigger(position: triggerPosition, action: { controller in
                    controller.startReverb()
                })
            }
            
            if triggerName.hasPrefix("Trigger_reverb") && triggerName.hasSuffix("stop") {
                return Trigger(position: triggerPosition, action: { controller in
                    controller.stopReverb()
                })
            }
            
            if triggerName.hasPrefix("Trigger_turn_start") {
                return Trigger(position: triggerPosition, action: { controller in
                    controller.startTurn()
                })
            }
            
            if triggerName.hasPrefix("Trigger_turn_stop") {
                return Trigger(position: triggerPosition, action: { controller in
                    controller.stopTurn()
                })
            }
            
            if triggerName.hasPrefix("Trigger_wood_start") {
                return Trigger(position: triggerPosition, action: { controller in
                    controller.startWood()
                })
            }
            
            if triggerName.hasPrefix("Trigger_wood_stop") {
                return Trigger(position: triggerPosition, action: { controller in
                    controller.stopWood()
                })
            }
            
            if triggerName.hasPrefix("Trigger_highSpeed") {
                return Trigger(position: triggerPosition, action: { controller in
                    controller.changeSpeedSound(speed: 3)
                })
            }
            
            if triggerName.hasPrefix("Trigger_normalSpeed") {
                return Trigger(position: triggerPosition, action: { controller in
                    controller.changeSpeedSound(speed: 2)
                })
            }
            
            if triggerName.hasPrefix("Trigger_slowSpeed") {
                return Trigger(position: triggerPosition, action: { controller in
                    controller.changeSpeedSound(speed: 1)
                })
            }
            
            return nil
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure scene post init.
        configureScene()

        /// Set the scene and make sure all shaders and textures are pre-loaded.
        sceneView.scene = scene

        // At every round regenerate collectables.
        let cartAnimation = scene.rootNode.animation(forKey: cartAnimationName)!
        cartAnimation.animationEvents = [SCNAnimationEvent(keyTime: 0.9, block: { [unowned self] _ in
            self.respawnCollectables()
        })]
        scene.rootNode.addAnimation(cartAnimation, forKey: cartAnimationName)
        
        sceneView.prepare(scene, shouldAbortBlock: nil)
        sceneView.delegate = self
        sceneView.pointOfView = sceneView.scene?.rootNode.childNode(withName: "camera_depart", recursively: true)

        // Play wind sound at launch.
        let sound = Assets.sound(named: "wind.m4a")
        sound.loops = true
        sound.isPositional = false
        sound.shouldStream = true
        sound.volume = 8.0
        sceneView.scene?.rootNode.addAudioPlayer(SCNAudioPlayer(source: sound))

        #if os(iOS)
        sceneView.contentScaleFactor = 1.3
        #elseif os(tvOS)
        sceneView.contentScaleFactor = 1.0
        #else
        sceneView.layer?.contentsScale = 1.0
        #endif
        
        // Start at speed 0.
        characterSpeed = 0.0
        
        setupGameControllers()
    }
    
    // MARK: Render loop
    
    /// At each frame, verify if an event should occur
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        activateTriggers()
        collectItems()

        // Update sun position
        if isUsingLocalSun {
            let target = (renderer.pointOfView?.presentation.convertPosition(sunTargetRelativeToCamera, to: nil))!
            sun.position = SCNVector3(float3(target) - float3(sunDirection) * 10.0)
        }
    }
    
    // MARK: Sound effects
    
    func startReverb() {
    }
    
    func stopReverb() {
    }
    
    func startTurn() {
        guard isSoundEnabled else { return }
        
        let player = SCNAudioPlayer(source:railSqueakSound)
        leftWheelEmitter.addAudioPlayer(player)
    }
    
    func stopTurn() {
        guard isSoundEnabled else { return }

        leftWheelEmitter.removeAllAudioPlayers()
    }
    
    func startWood() {
        isOverWood = true
        updateCartSound()
    }
    
    func stopWood() {
        isOverWood = false
        updateCartSound()
    }
    
    func trigger(characterSpeed speed: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 2.0
        characterSpeed = speed
        SCNTransaction.commit()        
    }
    
    func triggerCollision() {
        guard squatCounter <= 0 else { return }
        
        // Play sound and animate.
        character.runAction(.playAudio(hitSound, waitForCompletion: false))
        character.addAnimation(slapAnimation, forKey: nil)

        // Add stars.
        let emitter = character.childNode(withName: "Bip001_Head", recursively: true)
        emitter?.addParticleSystem(stars)
    }
    
    private func activateTriggers() {
        let characterPosition = float3(character.presentation.convertPosition(SCNVector3Zero, to: nil))
        
        var index = 0
        var didTrigger = false
        
        for trigger in triggers {
            if length_squared(characterPosition - trigger.position) < 0.05 {
                if activeTriggerIndex != index {
                    activeTriggerIndex = index
                    trigger.action(self)
                }
                didTrigger = true
                break
            }
            
            index = index + 1
        }
        
        if didTrigger == false {
            activeTriggerIndex = -1
        }
    }
    
    // MARK: Collectables
    
    private func respawnCollectables() {
        for collectable in collectables.childNodes {
            collectable.categoryBitMask = 0
            collectable.scale = SCNVector3(x:1, y:1, z:1)
        }
        
        for collectable in speedItems.childNodes {
            collectable.categoryBitMask = 0
            collectable.scale = SCNVector3(x:1, y:1, z:1)
        }
    }
    
    private func collectItems() {
        let leftHandPosition = float3(leftHand.presentation.convertPosition(SCNVector3Zero, to: nil))
        let rightHandPosition = float3(rightHand.presentation.convertPosition(SCNVector3Zero, to: nil))
        
        for collectable in collectables.childNodes {
            guard collectable.categoryBitMask != Int(CollectableState.beingCollected.rawValue) else { continue }

            let collectablePosition = float3(collectable.position)
            if length_squared(leftHandPosition - collectablePosition) < 0.05 || length_squared(rightHandPosition - collectablePosition) < 0.05 {
                collectable.categoryBitMask = Int(CollectableState.beingCollected.rawValue)
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.25
                
                collectable.scale = SCNVector3Zero
                
                #if os(iOS) || os(tvOS)
                    scene.addParticleSystem(collectParticleSystem, transform: collectable.presentation.worldTransform)
                #else
                    scene.addParticleSystem(collectParticleSystem, transform: collectable.presentation.worldTransform)
                #endif
                
                if let name = collectable.name, name.hasPrefix("big") {
                    headEmitter.addParticleSystem(collectBigParticleSystem)

                    sceneView.didCollectBigItem()
                    collectable.runAction(.playAudio(collectSound2, waitForCompletion: false))
                }
                else {
                    sceneView.didCollectItem()
                    collectable.runAction(.playAudio(collectSound, waitForCompletion: false))
                }

                SCNTransaction.commit()
                
                break
            }
        }
        
        for collectable in speedItems.childNodes {
            guard collectable.categoryBitMask != Int(CollectableState.beingCollected.rawValue) else { continue }
            
            let collectablePosition = float3(collectable.position)
            if length_squared(rightHandPosition - collectablePosition) < 0.05 {
                collectable.categoryBitMask = Int(CollectableState.beingCollected.rawValue)
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.25
                
                collectable.scale = SCNVector3Zero
                collectable.runAction(.playAudio(collectSound2, waitForCompletion: false))
                
                #if os(iOS) || os(tvOS)
                scene.addParticleSystem(collectParticleSystem, transform: collectable.presentation.worldTransform)
                #else
                scene.addParticleSystem(collectParticleSystem, transform: collectable.presentation.worldTransform)
                #endif
                
                SCNTransaction.commit()
                
                // Speed boost!
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 1.0
                
                let pov = sceneView.pointOfView!
                pov.camera?.xFov = 100.0
                
                #if !os(tvOS)
                pov.camera?.motionBlurIntensity = 1.0
                #endif
                
                let adjustCamera = SCNAction.run { _ in
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 1.0
                    
                    pov.camera?.xFov = 70
                    pov.camera?.motionBlurIntensity = 0.0
                    
                    SCNTransaction.commit()
                }
                
                pov.runAction(.sequence([.wait(duration: 2.0), adjustCamera]))
                character.runAction(.playAudio(cartBoost, waitForCompletion: false))
                
                SCNTransaction.commit()
                
                break
            }
        }
    }
    
    // MARK: Controlling the Character
    
    func changeSpeedSound(speed: UInt) {
        railSoundSpeed = speed
        updateCartSound()
    }
    
    func updateCartSound() {
        guard isSoundEnabled else { return }
        wheels.removeAllAudioPlayers()
        
        switch railSoundSpeed {
            case _ where isOverWood:
            wheels.addAudioPlayer(SCNAudioPlayer(source:railWoodSound))

            case 1:
            wheels.addAudioPlayer(SCNAudioPlayer(source:railLowSpeedSound))
                
            case 3:
            wheels.addAudioPlayer(SCNAudioPlayer(source:railHighSpeedSound))
                
            case let speed where speed > 0:
            wheels.addAudioPlayer(SCNAudioPlayer(source:railMediumSpeedSound))
                
            default: break
        }
    }
    
    func updateSpeed () {
        let speed = boostSpeedFactor * characterSpeed
        let effectiveSpeed = CGFloat(speedFactor * speed)
        scene.rootNode.setAnimationSpeed(effectiveSpeed, forKey: cartAnimationName)
        wheels.setAnimationSpeed(effectiveSpeed, forKey: "wheel")
        idleAnimationOwner.setAnimationSpeed(effectiveSpeed, forKey: "bob_idle-1")
        
        // Update sound.
        updateCartSound()
    }
    
    private var boostSpeedFactor: Float = 1.0 {
        didSet {
            updateSpeed()
        }
    }
    
    var characterSpeed: Float = 1.0 {
        didSet {
            updateSpeed()
        }
    }
    
    func squat() {
        SCNTransaction.begin()
        SCNTransaction.completionBlock = {
            self.squatCounter -= 1
        }
        squatCounter += 1
        
        character.addAnimation(squatAnimation, forKey: nil)
        character.runAction(.playAudio(cartHide, waitForCompletion: false))
        
        SCNTransaction.commit()
    }
    
    func jump() {
        character.addAnimation(jumpAnimation, forKey: nil)
        character.runAction(.playAudio(cartJump, waitForCompletion: false))
    }
    
    func leanLeft() {
        character.addAnimation(leanLeftAnimation, forKey: nil)
        character.runAction(.playAudio(cartTurnLeft, waitForCompletion: false))
    }
    
    func leanRight() {
        character.addAnimation(leanRightAnimation, forKey: nil)
        character.runAction(.playAudio(cartTurnRight, waitForCompletion: false))
    }
    
    func startMusic() {
        guard isSoundEnabled else { return }
        
        let musicIntroSource = Assets.sound(named: "music_intro.mp3")
        let musicLoopSource = Assets.sound(named: "music_loop.mp3")
        musicLoopSource.loops = true
        musicIntroSource.isPositional = false
        musicLoopSource.isPositional = false
        
        // `shouldStream` must be false to wait for completion.
        musicIntroSource.shouldStream = false
        musicLoopSource.shouldStream = true

        sceneView.scene?.rootNode.runAction(.playAudio(musicIntroSource, waitForCompletion: true)) { [unowned self] in
            self.sceneView.scene?.rootNode.addAudioPlayer(SCNAudioPlayer(source:musicLoopSource))
        }
    }
    
    func startGameIfNeeded() -> Bool {
        guard gameState == .notStarted else { return false }
        sceneView.setup2DOverlay()

        // Stop wind.
        sceneView.scene?.rootNode.removeAllAudioPlayers()
        
        // Play some music.
        startMusic()
        
        gameState = .started

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 2.0
        SCNTransaction.completionBlock = {
            self.jump()
        }
        
        let idleAnimation = Assets.animation(named: "animation-start.scn")
        character.addAnimation(idleAnimation, forKey: nil)
        character.removeAnimation(forKey: "start", fadeOutDuration: 0.3)
    
        sceneView.pointOfView = sceneView.scene?.rootNode.childNode(withName: "Camera", recursively: true)
        
        SCNTransaction.commit()
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 5.0
        
        characterSpeed = 1.0
        railSoundSpeed = 1
        
        SCNTransaction.commit()
        
        return true
    }
}
