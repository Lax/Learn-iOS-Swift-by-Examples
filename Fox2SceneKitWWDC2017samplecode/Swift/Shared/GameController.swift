/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class serves as the app's source of control flow.
 */

import GameController
import GameplayKit
import SceneKit

// Collision bit masks
struct Bitmask: OptionSet {
    let rawValue: Int
    static let character = Bitmask(rawValue: 1 << 0) // the main character
    static let collision = Bitmask(rawValue: 1 << 1) // the ground and walls
    static let enemy = Bitmask(rawValue: 1 << 2) // the enemies
    static let trigger = Bitmask(rawValue: 1 << 3) // the box that triggers camera changes and other actions
    static let collectable = Bitmask(rawValue: 1 << 4) // the collectables (gems and key)
}

#if os( iOS )
    typealias ExtraProtocols = SCNSceneRendererDelegate & SCNPhysicsContactDelegate & MenuDelegate
        & PadOverlayDelegate & ButtonOverlayDelegate
#else
    typealias ExtraProtocols = SCNSceneRendererDelegate & SCNPhysicsContactDelegate & MenuDelegate
#endif

enum ParticleKind: Int {
    case collect = 0
    case collectBig
    case keyApparition
    case enemyExplosion
    case unlockDoor
    case totalCount
}

enum AudioSourceKind: Int {
    case collect = 0
    case collectBig
    case unlockDoor
    case hitEnemy
    case totalCount
}
class GameController: NSObject, ExtraProtocols {

// Global settings
    static let DefaultCameraTransitionDuration = 1.0
    static let NumberOfFiends = 100
    static let CameraOrientationSensitivity: Float = 0.05

    private var scene: SCNScene?
    private weak var sceneRenderer: SCNSceneRenderer?

    // Overlays
    private var overlay: Overlay?

    // Character
    private var character: Character?

    // Camera and targets
    private var cameraNode = SCNNode()
    private var lookAtTarget = SCNNode()
    private var lastActiveCamera: SCNNode?
    private var lastActiveCameraFrontDirection = simd_float3.zero
    private var activeCamera: SCNNode?
    private var playingCinematic: Bool = false

    //triggers
    private var lastTrigger: SCNNode?
    private var firstTriggerDone: Bool = false

    //enemies
    private var enemy1: SCNNode?
    private var enemy2: SCNNode?

    //friends
    private var friends = [SCNNode](repeating: SCNNode(), count: NumberOfFiends)
    private var friendsSpeed = [Float](repeating: 0.0, count: NumberOfFiends)
    private var friendCount: Int = 0
    private var friendsAreFree: Bool = false

    //collected objects
    private var collectedKeys: Int = 0
    private var collectedGems: Int = 0
    private var keyIsVisible: Bool = false

    // particles
    private var particleSystems = [[SCNParticleSystem]](repeatElement([SCNParticleSystem()], count: ParticleKind.totalCount.rawValue))

    // audio
    private var audioSources = [SCNAudioSource](repeatElement(SCNAudioSource(), count: AudioSourceKind.totalCount.rawValue))

    // GameplayKit
    private var gkScene: GKScene?

    // Game controller
    private var gamePadCurrent: GCController?
    private var gamePadLeft: GCControllerDirectionPad?
    private var gamePadRight: GCControllerDirectionPad?

    // update delta time
    private var lastUpdateTime = TimeInterval()

// MARK: -
// MARK: Setup

    func setupGameController() {
        NotificationCenter.default.addObserver(
                self, selector: #selector(self.handleControllerDidConnect),
                name: NSNotification.Name.GCControllerDidConnect, object: nil)

        NotificationCenter.default.addObserver(
            self, selector: #selector(self.handleControllerDidDisconnect),
            name: NSNotification.Name.GCControllerDidDisconnect, object: nil)
        guard let controller = GCController.controllers().first else {
            return
        }
        registerGameController(controller)
    }

    func setupCharacter() {
        character = Character(scene: scene!)

        // keep a pointer to the physicsWorld from the character because we will need it when updating the character's position
        character!.physicsWorld = scene!.physicsWorld
        scene!.rootNode.addChildNode(character!.node!)
    }

    func setupPhysics() {
        //make sure all objects only collide with the character
        self.scene?.rootNode.enumerateHierarchy({(_ node: SCNNode, _ _: UnsafeMutablePointer<ObjCBool>) -> Void in
            node.physicsBody?.collisionBitMask = Int(Bitmask.character.rawValue)
        })
    }

    func setupCollisions() {
        // load the collision mesh from another scene and merge into main scene
        let collisionsScene = SCNScene( named: "Art.scnassets/collision.scn" )
        collisionsScene!.rootNode.enumerateChildNodes { (_ child: SCNNode, _ _: UnsafeMutablePointer<ObjCBool>) in
            child.opacity = 0.0
            self.scene?.rootNode.addChildNode(child)
        }
    }

    // the follow camera behavior make the camera to follow the character, with a constant distance, altitude and smoothed motion
    func setupFollowCamera(_ cameraNode: SCNNode) {
        // look at "lookAtTarget"
        let lookAtConstraint = SCNLookAtConstraint(target: self.lookAtTarget)
        lookAtConstraint.influenceFactor = 0.07
        lookAtConstraint.isGimbalLockEnabled = true

        // distance constraints
        let follow = SCNDistanceConstraint(target: self.lookAtTarget)
        let distance = CGFloat(simd_length(cameraNode.simdPosition))
        follow.minimumDistance = distance
        follow.maximumDistance = distance

        // configure a constraint to maintain a constant altitude relative to the character
        let desiredAltitude = abs(cameraNode.simdWorldPosition.y)
        weak var weakSelf = self

        let keepAltitude = SCNTransformConstraint.positionConstraint(inWorldSpace: true, with: {(_ node: SCNNode, _ position: SCNVector3) -> SCNVector3 in
                guard let strongSelf = weakSelf else { return position }
                var position = float3(position)
                position.y = strongSelf.character!.baseAltitude + desiredAltitude
                return SCNVector3( position )
            })

        let accelerationConstraint = SCNAccelerationConstraint()
        accelerationConstraint.maximumLinearVelocity = 1500.0
        accelerationConstraint.maximumLinearAcceleration = 50.0
        accelerationConstraint.damping = 0.05

        // use a custom constraint to let the user orbit the camera around the character
        let transformNode = SCNNode()
        let orientationUpdateConstraint = SCNTransformConstraint(inWorldSpace: true) { (_ node: SCNNode, _ transform: SCNMatrix4) -> SCNMatrix4 in
            guard let strongSelf = weakSelf else { return transform }
            if strongSelf.activeCamera != node {
                return transform
            }

            // Slowly update the acceleration constraint influence factor to smoothly reenable the acceleration.
            accelerationConstraint.influenceFactor = min(1, accelerationConstraint.influenceFactor + 0.01)

            let targetPosition = strongSelf.lookAtTarget.presentation.simdWorldPosition
            let cameraDirection = strongSelf.cameraDirection
            if cameraDirection.allZero() {
                return transform
            }

            // Disable the acceleration constraint.
            accelerationConstraint.influenceFactor = 0

            let characterWorldUp = strongSelf.character?.node?.presentation.simdWorldUp

            transformNode.transform = transform

            let q = simd_mul(
                simd_quaternion(GameController.CameraOrientationSensitivity * cameraDirection.x, characterWorldUp!),
                simd_quaternion(GameController.CameraOrientationSensitivity * cameraDirection.y, transformNode.simdWorldRight)
            )

            transformNode.simdRotate(by: q, aroundTarget: targetPosition)
            return transformNode.transform
        }

        cameraNode.constraints = [follow, keepAltitude, accelerationConstraint, orientationUpdateConstraint, lookAtConstraint]
    }

    // the axis aligned behavior look at the character but remains aligned using a specified axis
    func setupAxisAlignedCamera(_ cameraNode: SCNNode) {
        let distance: Float = simd_length(cameraNode.simdPosition)
        let originalAxisDirection = cameraNode.simdWorldFront

        self.lastActiveCameraFrontDirection = originalAxisDirection

        let symetricAxisDirection = simd_make_float3(-originalAxisDirection.x, originalAxisDirection.y, -originalAxisDirection.z)

        weak var weakSelf = self

        // define a custom constraint for the axis alignment
        let axisAlignConstraint = SCNTransformConstraint.positionConstraint(
            inWorldSpace: true, with: {(_ node: SCNNode, _ position: SCNVector3) -> SCNVector3 in
                guard let strongSelf = weakSelf else { return position }
                guard let activeCamera = strongSelf.activeCamera else { return position }

                let axisOrigin = strongSelf.lookAtTarget.presentation.simdWorldPosition
                let referenceFrontDirection =
                    strongSelf.activeCamera == node ? strongSelf.lastActiveCameraFrontDirection : activeCamera.presentation.simdWorldFront

                let axis = simd_dot(originalAxisDirection, referenceFrontDirection) > 0 ? originalAxisDirection: symetricAxisDirection

                let constrainedPosition = axisOrigin - distance * axis
                return SCNVector3(constrainedPosition)
            })

        let accelerationConstraint = SCNAccelerationConstraint()
        accelerationConstraint.maximumLinearAcceleration = 20
        accelerationConstraint.decelerationDistance = 0.5
        accelerationConstraint.damping = 0.05

        // look at constraint
        let lookAtConstraint = SCNLookAtConstraint(target: self.lookAtTarget)
        lookAtConstraint.isGimbalLockEnabled = true // keep horizon horizontal

        cameraNode.constraints = [axisAlignConstraint, lookAtConstraint, accelerationConstraint]
    }

    func setupCameraNode(_ node: SCNNode) {
        guard let cameraName = node.name else { return }

        if cameraName.hasPrefix("camTrav") {
            setupAxisAlignedCamera(node)
        } else if cameraName.hasPrefix("camLookAt") {
            setupFollowCamera(node)
        }
    }

    func setupCamera() {
        //The lookAtTarget node will be placed slighlty above the character using a constraint
        weak var weakSelf = self

        self.lookAtTarget.constraints = [ SCNTransformConstraint.positionConstraint(
                                        inWorldSpace: true, with: { (_ node: SCNNode, _ position: SCNVector3) -> SCNVector3 in
            guard let strongSelf = weakSelf else { return position }

            guard var worldPosition = strongSelf.character?.node?.simdWorldPosition else { return position }
            worldPosition.y = strongSelf.character!.baseAltitude + 0.5
            return SCNVector3(worldPosition)
        })]

        self.scene?.rootNode.addChildNode(lookAtTarget)

        self.scene?.rootNode.enumerateHierarchy({(_ node: SCNNode, _ _: UnsafeMutablePointer<ObjCBool>) -> Void in
            if node.camera != nil {
                self.setupCameraNode(node)
            }
        })

        self.cameraNode.camera = SCNCamera()
        self.cameraNode.name = "mainCamera"
        self.cameraNode.camera!.zNear = 0.1
        self.scene!.rootNode.addChildNode(cameraNode)

        setActiveCamera("camLookAt_cameraGame", animationDuration: 0.0)
    }

    func setupEnemies() {
        self.enemy1 = self.scene?.rootNode.childNode(withName: "enemy1", recursively: true)
        self.enemy2 = self.scene?.rootNode.childNode(withName: "enemy2", recursively: true)

        let gkScene = GKScene()

        // Player
        let playerEntity = GKEntity()
        gkScene.addEntity(playerEntity)
        playerEntity.addComponent(GKSCNNodeComponent(node: character!.node))

        let playerComponent = PlayerComponent()
        playerComponent.isAutoMoveNode = false
        playerComponent.character = self.character
        playerEntity.addComponent(playerComponent)
        playerComponent.positionAgentFromNode()

        // Chaser
        let chaserEntity = GKEntity()
        gkScene.addEntity(chaserEntity)
        chaserEntity.addComponent(GKSCNNodeComponent(node: self.enemy1!))
        let chaser = ChaserComponent()
        chaserEntity.addComponent(chaser)
        chaser.player = playerComponent
        chaser.positionAgentFromNode()

        // Scared
        let scaredEntity = GKEntity()
        gkScene.addEntity(scaredEntity)
        scaredEntity.addComponent(GKSCNNodeComponent(node: self.enemy2!))
        let scared = ScaredComponent()
        scaredEntity.addComponent(scared)
        scared.player = playerComponent
        scared.positionAgentFromNode()

        // animate enemies (move up and down)
        let anim = CABasicAnimation(keyPath: "position")
        anim.fromValue = NSValue(scnVector3: SCNVector3(0, 0.1, 0))
        anim.toValue = NSValue(scnVector3: SCNVector3(0, -0.1, 0))
        anim.isAdditive = true
        anim.repeatCount = .infinity
        anim.autoreverses = true
        anim.duration = 1.2
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)

        self.enemy1!.addAnimation(anim, forKey: "")
        self.enemy2!.addAnimation(anim, forKey: "")

        self.gkScene = gkScene
    }

    func loadParticleSystems(atPath path: String) -> [SCNParticleSystem] {
        let url = URL(fileURLWithPath: path)
        let directory = url.deletingLastPathComponent()

        let fileName = url.lastPathComponent
        let ext: String = url.pathExtension

        if ext == "scnp" {
            return [SCNParticleSystem(named: fileName, inDirectory: directory.relativePath)!]
        } else {
            var particles = [SCNParticleSystem]()
            let scene = SCNScene(named: fileName, inDirectory: directory.relativePath, options: nil)
            scene!.rootNode.enumerateHierarchy({(_ node: SCNNode, _ _: UnsafeMutablePointer<ObjCBool>) -> Void in
                if node.particleSystems != nil {
                    particles += node.particleSystems!
                }
            })
            return particles
        }
    }

    func setupParticleSystem() {
        particleSystems[ParticleKind.collect.rawValue] = loadParticleSystems(atPath: "Art.scnassets/particles/collect.scnp")
        particleSystems[ParticleKind.collectBig.rawValue] = loadParticleSystems(atPath: "Art.scnassets/particles/key_apparition.scn")
        particleSystems[ParticleKind.enemyExplosion.rawValue] = loadParticleSystems(atPath: "Art.scnassets/particles/enemy_explosion.scn")
        particleSystems[ParticleKind.keyApparition.rawValue] = loadParticleSystems(atPath: "Art.scnassets/particles/key_apparition.scn")
        particleSystems[ParticleKind.unlockDoor.rawValue] = loadParticleSystems(atPath: "Art.scnassets/particles/unlock_door.scn")
    }

    func setupPlatforms() {
        let PLATFORM_MOVE_OFFSET = Float(1.5)
        let PLATFORM_MOVE_SPEED = Float(0.5)

        var alternate: Float = 1
        // This could be done in the editor using the action editor.
        scene!.rootNode.enumerateHierarchy({(_ node: SCNNode, _ _: UnsafeMutablePointer<ObjCBool>) -> Void in
            if node.name == "mobilePlatform" && !node.childNodes.isEmpty {
                node.simdPosition = simd_float3(
                    node.simdPosition.x - (alternate * PLATFORM_MOVE_OFFSET / 2.0), node.simdPosition.y, node.simdPosition.z)

                let moveAction = SCNAction.move(by: SCNVector3(alternate * PLATFORM_MOVE_OFFSET, 0, 0),
                                                duration: TimeInterval(1 / PLATFORM_MOVE_SPEED))
                moveAction.timingMode = .easeInEaseOut
                node.runAction(SCNAction.repeatForever(SCNAction.sequence([moveAction, moveAction.reversed()])))

                alternate = -alternate // alternate movement of platforms to desynchronize them

                node.enumerateChildNodes({ (_ child: SCNNode, _ _: UnsafeMutablePointer<ObjCBool>) in
                    if child.name == "particles_platform" {
                        child.particleSystems?[0].orientationDirection = SCNVector3(0, 1, 0)
                    }
                })
            }
        })
    }

    // MARK: - Camera transitions

    // transition to the specified camera
    // this method will reparent the main camera under the camera named "cameraNamed"
    // and trigger the animation to smoothly move from the current position to the new position
    func setActiveCamera(_ cameraName: String, animationDuration duration: CFTimeInterval) {
        guard let camera = scene?.rootNode.childNode(withName: cameraName, recursively: true) else { return }
        if self.activeCamera == camera {
            return
        }

        self.lastActiveCamera = activeCamera
        if activeCamera != nil {
            self.lastActiveCameraFrontDirection = (activeCamera?.presentation.simdWorldFront)!
        }
        self.activeCamera = camera

        // save old transform in world space
        let oldTransform: SCNMatrix4 = cameraNode.presentation.worldTransform

        // re-parent
        camera.addChildNode(cameraNode)

        // compute the old transform relative to our new parent node (yeah this is the complex part)
        let parentTransform = camera.presentation.worldTransform
        let parentInv = SCNMatrix4Invert(parentTransform)

        // with this new transform our position is unchanged in workd space (i.e we did re-parent but didn't move).
        cameraNode.transform = SCNMatrix4Mult(oldTransform, parentInv)

        // now animate the transform to identity to smoothly move to the new desired position
        SCNTransaction.begin()
        SCNTransaction.animationDuration = duration
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        cameraNode.transform = SCNMatrix4Identity

        if let cameraTemplate = camera.camera {
            cameraNode.camera!.fieldOfView = cameraTemplate.fieldOfView
            cameraNode.camera!.wantsDepthOfField = cameraTemplate.wantsDepthOfField
            cameraNode.camera!.sensorHeight = cameraTemplate.sensorHeight
            cameraNode.camera!.fStop = cameraTemplate.fStop
            cameraNode.camera!.focusDistance = cameraTemplate.focusDistance
            cameraNode.camera!.bloomIntensity = cameraTemplate.bloomIntensity
            cameraNode.camera!.bloomThreshold = cameraTemplate.bloomThreshold
            cameraNode.camera!.bloomBlurRadius = cameraTemplate.bloomBlurRadius
            cameraNode.camera!.wantsHDR = cameraTemplate.wantsHDR
            cameraNode.camera!.wantsExposureAdaptation = cameraTemplate.wantsExposureAdaptation
            cameraNode.camera!.vignettingPower = cameraTemplate.vignettingPower
            cameraNode.camera!.vignettingIntensity = cameraTemplate.vignettingIntensity
        }
        SCNTransaction.commit()
    }

    func setActiveCamera(_ cameraName: String) {
        setActiveCamera(cameraName, animationDuration: GameController.DefaultCameraTransitionDuration)
    }

    // MARK: - Audio

    func playSound(_ audioName: AudioSourceKind) {
        scene!.rootNode.addAudioPlayer(SCNAudioPlayer(source: audioSources[audioName.rawValue]))
    }

    func setupAudio() {
        // Get an arbitrary node to attach the sounds to.
        let node = scene!.rootNode

        // ambience
        if let audioSource = SCNAudioSource(named: "audio/ambience.mp3") {
            audioSource.loops = true
            audioSource.volume = 0.8
            audioSource.isPositional = false
            audioSource.shouldStream = true
            node.addAudioPlayer(SCNAudioPlayer(source: audioSource))
        }
        // volcano
        if let volcanoNode = scene!.rootNode.childNode(withName: "particles_volcanoSmoke_v2", recursively: true) {
            if let audioSource = SCNAudioSource(named: "audio/volcano.mp3") {
                audioSource.loops = true
                audioSource.volume = 5.0
                volcanoNode.addAudioPlayer(SCNAudioPlayer(source: audioSource))
            }
        }

        // other sounds
        audioSources[AudioSourceKind.collect.rawValue] = SCNAudioSource(named: "audio/collect.mp3")!
        audioSources[AudioSourceKind.collectBig.rawValue] = SCNAudioSource(named: "audio/collectBig.mp3")!
        audioSources[AudioSourceKind.unlockDoor.rawValue] = SCNAudioSource(named: "audio/unlockTheDoor.m4a")!
        audioSources[AudioSourceKind.hitEnemy.rawValue] = SCNAudioSource(named: "audio/hitEnemy.wav")!

        // adjust volumes
        audioSources[AudioSourceKind.unlockDoor.rawValue].isPositional = false
        audioSources[AudioSourceKind.collect.rawValue].isPositional = false
        audioSources[AudioSourceKind.collectBig.rawValue].isPositional = false
        audioSources[AudioSourceKind.hitEnemy.rawValue].isPositional = false

        audioSources[AudioSourceKind.unlockDoor.rawValue].volume = 0.5
        audioSources[AudioSourceKind.collect.rawValue].volume = 4.0
        audioSources[AudioSourceKind.collectBig.rawValue].volume = 4.0
    }

    // MARK: - Init

    init(scnView: SCNView) {
        super.init()
        
        sceneRenderer = scnView
        sceneRenderer!.delegate = self
        
        // Uncomment to show statistics such as fps and timing information
        //scnView.showsStatistics = true
        
        // setup overlay
        overlay = Overlay(size: scnView.bounds.size, controller: self)
        scnView.overlaySKScene = overlay

        //load the main scene
        self.scene = SCNScene(named: "Art.scnassets/scene.scn")

        //setup physics
        setupPhysics()

        //setup collisions
        setupCollisions()

        //load the character
        setupCharacter()

        //setup enemies
        setupEnemies()

        //setup friends
        addFriends(3)

        //setup platforms
        setupPlatforms()

        //setup particles
        setupParticleSystem()

        //setup lighting
        let light = scene!.rootNode.childNode(withName: "DirectLight", recursively: true)!.light
        light!.shadowCascadeCount = 3  // turn on cascade shadows
        light!.shadowMapSize = CGSize(width: CGFloat(512), height: CGFloat(512))
        light!.maximumShadowDistance = 20
        light!.shadowCascadeSplittingFactor = 0.5
        
        //setup camera
        setupCamera()

        //setup game controller
        setupGameController()

        //configure quality
        configureRenderingQuality(scnView)

        //assign the scene to the view
        sceneRenderer!.scene = self.scene

        //setup audio
        setupAudio()

        //select the point of view to use
        sceneRenderer!.pointOfView = self.cameraNode

        //register ourself as the physics contact delegate to receive contact notifications
        sceneRenderer!.scene!.physicsWorld.contactDelegate = self
    }

    func resetPlayerPosition() {
        character!.queueResetCharacterPosition()
    }

    // MARK: - cinematic

    func startCinematic() {
        playingCinematic = true
        character!.node!.isPaused = true
    }

    func stopCinematic() {
        playingCinematic = false
        character!.node!.isPaused = false
    }

    // MARK: - particles

    func particleSystems(with kind: ParticleKind) -> [SCNParticleSystem] {
        return particleSystems[kind.rawValue]
    }

    func addParticles(with kind: ParticleKind, withTransform transform: SCNMatrix4) {
        let particles = particleSystems(with: kind)
        for ps: SCNParticleSystem in particles {
            scene!.addParticleSystem(ps, transform: transform)
        }
    }

    // MARK: - Triggers

    // "triggers" are triggered when a character enter a box with the collision mask BitmaskTrigger
    func execTrigger(_ triggerNode: SCNNode, animationDuration duration: CFTimeInterval) {
        //exec trigger
        if triggerNode.name!.hasPrefix("trigCam_") {
            let cameraName = (triggerNode.name as NSString?)!.substring(from: 8)
            setActiveCamera(cameraName, animationDuration: duration)
        }
        //action
        if triggerNode.name!.hasPrefix("trigAction_") {
            if collectedKeys > 0 {
                let actionName = (triggerNode.name as NSString?)!.substring(from: 11)
                if actionName == "unlockDoor" {
                    unlockDoor()
                }
            }
        }
    }

    func trigger(_ triggerNode: SCNNode) {
        if playingCinematic {
            return
        }
        if lastTrigger != triggerNode {
            lastTrigger = triggerNode

            // the very first trigger should not animate (initial camera position)
            execTrigger(triggerNode, animationDuration: firstTriggerDone ? GameController.DefaultCameraTransitionDuration: 0)
            firstTriggerDone = true
        }
    }

    // MARK: - Friends

    func updateFriends(deltaTime: CFTimeInterval) {
        let pathCurve: Float = 0.4

        // update pandas
        for i in 0..<friendCount {
            let friend = friends[i]

            var pos = friend.simdPosition
            let offsetx = pos.x - sinf(pathCurve * pos.z)

            pos.z += friendsSpeed[i] * Float(deltaTime) * 0.5
            pos.x = sinf(pathCurve * pos.z) + offsetx

            friend.simdPosition = pos

            ensureNoPenetrationOfIndex(i)
        }
    }

    func animateFriends() {
            //animations
        let walkAnimation = Character.loadAnimation(fromSceneNamed: "Art.scnassets/character/max_walk.scn")

        SCNTransaction.begin()
        for i in 0..<friendCount {
            //unsynchronize
            let walk = walkAnimation.copy() as! SCNAnimationPlayer
            walk.speed = CGFloat(friendsSpeed[i])
            friends[i].addAnimationPlayer(walk, forKey: "walk")
            walk.play()
        }
        SCNTransaction.commit()
    }
    
    func addFriends(_ count: Int) {
        var count = count
        if count + friendCount > GameController.NumberOfFiends {
            count = GameController.NumberOfFiends - friendCount
        }

        let friendScene = SCNScene(named: "Art.scnassets/character/max.scn")
        guard let friendModel = friendScene?.rootNode.childNode(withName: "Max_rootNode", recursively: true) else { return }
        friendModel.name = "friend"

        var textures = [String](repeating: "", count: 3)
        textures[0] = "Art.scnassets/character/max_diffuseB.png"
        textures[1] = "Art.scnassets/character/max_diffuseC.png"
        textures[2] = "Art.scnassets/character/max_diffuseD.png"

        var geometries = [SCNGeometry](repeating: SCNGeometry(), count: 3)
        guard let geometryNode = friendModel.childNode(withName: "Max", recursively: true) else { return }

        geometryNode.geometry!.firstMaterial?.diffuse.intensity = 0.5

        geometries[0] = geometryNode.geometry!.copy() as! SCNGeometry
        geometries[1] = geometryNode.geometry!.copy() as! SCNGeometry
        geometries[2] = geometryNode.geometry!.copy() as! SCNGeometry

        geometries[0].firstMaterial = geometries[0].firstMaterial?.copy() as? SCNMaterial
        geometryNode.geometry?.firstMaterial?.diffuse.contents = "Art.scnassets/character/max_diffuseB.png"

        geometries[1].firstMaterial = geometries[1].firstMaterial?.copy() as? SCNMaterial
        geometryNode.geometry?.firstMaterial?.diffuse.contents = "Art.scnassets/character/max_diffuseC.png"

        geometries[2].firstMaterial = geometries[2].firstMaterial?.copy() as? SCNMaterial
        geometryNode.geometry?.firstMaterial?.diffuse.contents = "Art.scnassets/character/max_diffuseD.png"

        //remove physics from our friends
        friendModel.enumerateHierarchy({(_ node: SCNNode, _ _: UnsafeMutablePointer<ObjCBool>) -> Void in
            node.physicsBody = nil
        })

        let friendPosition = simd_make_float3(-5.84, -0.75, 3.354)
        let FRIEND_AREA_LENGTH: Float = 5.0

        // group them
        var friendsNode: SCNNode? = scene!.rootNode.childNode(withName: "friends", recursively: false)
        if friendsNode == nil {
            friendsNode = SCNNode()
            friendsNode!.name = "friends"
            scene!.rootNode.addChildNode(friendsNode!)
        }

        //animations
        let idleAnimation = Character.loadAnimation(fromSceneNamed: "Art.scnassets/character/max_idle.scn")
        for _ in 0..<count {
            let friend = friendModel.clone()

            //replace texture
            let geometryIndex = Int(arc4random_uniform(UInt32(3)))
            guard let geometryNode = friend.childNode(withName: "Max", recursively: true) else { return }
            geometryNode.geometry = geometries[geometryIndex]

            //place our friend
            friend.simdPosition = simd_make_float3(
                friendPosition.x + (1.4 * (Float(arc4random_uniform(UInt32(RAND_MAX))) / Float(RAND_MAX)) - 0.5),
                friendPosition.y,
                friendPosition.z - (FRIEND_AREA_LENGTH * (Float(arc4random_uniform(UInt32(RAND_MAX))) / Float(RAND_MAX))))

            //unsynchronize
            let idle = (idleAnimation.copy() as! SCNAnimationPlayer)
            idle.speed = CGFloat(Float(1.5) + Float(1.5) * Float(arc4random_uniform(UInt32(RAND_MAX))) / Float(RAND_MAX))

            friend.addAnimationPlayer(idle, forKey: "idle")
            idle.play()
            friendsNode?.addChildNode(friend)

            self.friendsSpeed[friendCount] = Float(idle.speed)
            self.friends[friendCount] = friend
            self.friendCount += 1
        }

        for i in 0..<friendCount {
            ensureNoPenetrationOfIndex(i)
        }
    }
    
    // iterates on every friend and move them if they intersect friend at index i
    func ensureNoPenetrationOfIndex(_ index: Int) {
        var pos = friends[index].simdPosition

        // ensure no penetration
        let pandaRadius: Float = 0.15
        let pandaDiameter = pandaRadius * 2.0
        for j in 0..<friendCount {
            if j == index {
                continue
            }

            let otherPos = float3(friends[j].position)
            let v = otherPos - pos
            let dist = simd_length(v)
            if dist < pandaDiameter {
                // penetration
                let pen = pandaDiameter - dist
                pos -= simd_normalize(v) * pen
            }
        }

        //ensure within the box X[-6.662 -4.8] Z<3.354
        if friends[index].position.z <= 3.354 {
            pos.x = max(pos.x, -6.662)
            pos.x = min(pos.x, -4.8)
        }
        friends[index].simdPosition = pos
    }

    // MARK: - Game actions

    func unlockDoor() {
        if friendsAreFree {  //already unlocked
            return
        }

        startCinematic()  //pause the scene

        //play sound
        playSound(AudioSourceKind.unlockDoor)

        //cinematic02
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.0
        SCNTransaction.completionBlock = {() -> Void in
            //trigger particles
            let door: SCNNode? = self.scene!.rootNode.childNode(withName: "door", recursively: true)
            let particle_door: SCNNode? = self.scene!.rootNode.childNode(withName: "particles_door", recursively: true)
            self.addParticles(with: .unlockDoor, withTransform: particle_door!.worldTransform)

            //audio
            self.playSound(.collectBig)

            //add friends
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.0
            self.addFriends(GameController.NumberOfFiends)
            SCNTransaction.commit()

            //open the door
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 1.0
            SCNTransaction.completionBlock = {() -> Void in
                //animate characters
                self.animateFriends()

                // update state
                self.friendsAreFree = true

                // show end screen
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() +
                    Double(Int64(1.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {() -> Void in
                    self.showEndScreen()
                })
            }
            door!.opacity = 0.0
            SCNTransaction.commit()
        }

        // change the point of view
        setActiveCamera("CameraCinematic02", animationDuration: 1.0)
        SCNTransaction.commit()
    }

    func showKey() {
        keyIsVisible = true

        // get the key node
        let key: SCNNode? = scene!.rootNode.childNode(withName: "key", recursively: true)

        //sound fx
        playSound(AudioSourceKind.collectBig)

        //particles
        addParticles(with: .keyApparition, withTransform: key!.worldTransform)

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        SCNTransaction.completionBlock = {() -> Void in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() +
                Double(Int64(2.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {() -> Void in
                self.keyDidAppear()
            })
        }
        key!.opacity = 1.0 // show the key
        SCNTransaction.commit()
    }

    func keyDidAppear() {
        execTrigger(lastTrigger!, animationDuration: 0.75) //revert to previous camera
        stopCinematic()
    }

    func keyShouldAppear() {
        startCinematic()

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.0
        SCNTransaction.completionBlock = {() -> Void in
            self.showKey()
        }
        setActiveCamera("CameraCinematic01", animationDuration: 3.0)
        SCNTransaction.commit()
    }

    func collect(_ collectable: SCNNode) {
        if collectable.physicsBody != nil {

            //the Key
            if collectable.name == "key" {
                if !self.keyIsVisible { //key not visible yet
                    return
                }

                // play sound
                playSound(AudioSourceKind.collect)
                self.overlay?.didCollectKey()

                self.collectedKeys += 1
            }

            //the gems
            else if collectable.name == "CollectableBig" {
                self.collectedGems += 1

                // play sound
                playSound(AudioSourceKind.collect)

                // update the overlay
                self.overlay?.collectedGemsCount = self.collectedGems

                if self.collectedGems == 1 {
                    //we collect a gem, show the key after 1 second
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() +
                        Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {() -> Void in
                        self.keyShouldAppear()
                    })
                }
            }

            collectable.physicsBody = nil //not collectable anymore

            // particles
            addParticles(with: .keyApparition, withTransform: collectable.worldTransform)

            collectable.removeFromParentNode()
        }
    }

    // MARK: - Controlling the character

    func controllerJump(_ controllerJump: Bool) {
        character!.isJump = controllerJump
    }

    func controllerAttack() {
        if !self.character!.isAttacking {
            self.character!.attack()
        }
    }

    var characterDirection: vector_float2 {
        get {
            return character!.direction
        }
        set {
            var direction = newValue
            let l = simd_length(direction)
            if l > 1.0 {
                direction *= 1 / l
            }
            character!.direction = direction
        }
    }

    var cameraDirection = vector_float2.zero {
        didSet {
            let l = simd_length(cameraDirection)
            if l > 1.0 {
                cameraDirection *= 1 / l
            }
            cameraDirection.y = 0
        }
    }
    
    // MARK: - Update

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // compute delta time
        if lastUpdateTime == 0 {
            lastUpdateTime = time
        }
        let deltaTime: TimeInterval = time - lastUpdateTime
        lastUpdateTime = time

        // Update Friends
        if friendsAreFree {
            updateFriends(deltaTime: deltaTime)
        }

        // stop here if cinematic
        if playingCinematic == true {
            return
        }

        // update characters
        character!.update(atTime: time, with: renderer)

        // update enemies
        for entity: GKEntity in gkScene!.entities {
            entity.update(deltaTime: deltaTime)
        }
    }

    // MARK: - contact delegate

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {

        // triggers
        if contact.nodeA.physicsBody!.categoryBitMask == Bitmask.trigger.rawValue {
            trigger(contact.nodeA)
        }
        if contact.nodeB.physicsBody!.categoryBitMask == Bitmask.trigger.rawValue {
            trigger(contact.nodeB)
        }

        // collectables
        if contact.nodeA.physicsBody!.categoryBitMask == Bitmask.collectable.rawValue {
            collect(contact.nodeA)
        }
        if contact.nodeB.physicsBody!.categoryBitMask == Bitmask.collectable.rawValue {
            collect(contact.nodeB)
        }
    }

    // MARK: - Congratulating the Player

    func showEndScreen() {
        // Play the congrat sound.
        guard let victoryMusic = SCNAudioSource(named: "audio/Music_victory.mp3") else { return }
        victoryMusic.volume = 0.5

        self.scene?.rootNode.addAudioPlayer(SCNAudioPlayer(source: victoryMusic))

        self.overlay?.showEndScreen()
    }

    // MARK: - Configure rendering quality

    func turnOffEXRForMAterialProperty(property: SCNMaterialProperty) {
        if var propertyPath = property.contents as? NSString {
            if propertyPath.pathExtension == "exr" {
                propertyPath = ((propertyPath.deletingPathExtension as NSString).appendingPathExtension("png")! as NSString)
                property.contents = propertyPath
            }
        }
    }

    func turnOffEXR() {
        self.turnOffEXRForMAterialProperty(property: scene!.background)
        self.turnOffEXRForMAterialProperty(property: scene!.lightingEnvironment)

        scene?.rootNode.enumerateChildNodes { (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            if let materials = child.geometry?.materials {
                for material in materials {
                    self.turnOffEXRForMAterialProperty(property: material.selfIllumination)
                }
            }
        }
    }

    func turnOffNormalMaps() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            if let materials = child.geometry?.materials {
                for material in materials {
                    material.normal.contents = SKColor.black
                }
            }
        })
    }

    func turnOffHDR() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            child.camera?.wantsHDR = false
        })
    }

    func turnOffDepthOfField() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            child.camera?.wantsDepthOfField = false
        })
    }

    func turnOffSoftShadows() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            if let lightSampleCount = child.light?.shadowSampleCount {
                child.light?.shadowSampleCount = min(lightSampleCount, 1)
            }
        })
    }

    func turnOffPostProcess() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            if let light = child.light {
                light.shadowCascadeCount = 0
                light.shadowMapSize = CGSize(width: 1024, height: 1024)
            }
        })
    }

    func turnOffOverlay() {
        sceneRenderer?.overlaySKScene = nil
    }

    func turnOffVertexShaderModifiers() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            if var shaderModifiers = child.geometry?.shaderModifiers {
                shaderModifiers[SCNShaderModifierEntryPoint.geometry] = nil
                child.geometry?.shaderModifiers = shaderModifiers
            }

            if let materials = child.geometry?.materials {
                for material in materials where material.shaderModifiers != nil {
                    var shaderModifiers = material.shaderModifiers!
                    shaderModifiers[SCNShaderModifierEntryPoint.geometry] = nil
                    material.shaderModifiers = shaderModifiers
                }
            }
        })
    }

    func turnOffVegetation() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            guard let materialName = child.geometry?.firstMaterial?.name as NSString? else { return }
            if materialName.hasPrefix("plante") {
                child.isHidden = true
            }
        })
    }

    func configureRenderingQuality(_ view: SCNView) {
        
#if os( tvOS )
    self.turnOffEXR()  //tvOS doesn't support exr maps
    // the following things are done for low power device(s) only
    self.turnOffNormalMaps()
    self.turnOffHDR()
    self.turnOffDepthOfField()
    self.turnOffSoftShadows()
    self.turnOffPostProcess()
    self.turnOffOverlay()
    self.turnOffVertexShaderModifiers()
    self.turnOffVegetation()
#endif

    }

    // MARK: - Debug menu

    func fStopChanged(_ value: CGFloat) {
        sceneRenderer!.pointOfView!.camera!.fStop = value
    }

    func focusDistanceChanged(_ value: CGFloat) {
        sceneRenderer!.pointOfView!.camera!.focusDistance = value
    }

    func debugMenuSelectCameraAtIndex(_ index: Int) {
        if index == 0 {
            let key = self.scene?.rootNode .childNode(withName: "key", recursively: true)
            key?.opacity = 1.0
        }
        self.setActiveCamera("CameraDof\(index)")
    }

    // MARK: - GameController

    @objc
    func handleControllerDidConnect(_ notification: Notification) {
        if gamePadCurrent != nil {
            return
        }
        guard let gameController = notification.object as? GCController else {
            return
        }
        registerGameController(gameController)
    }

    @objc
    func handleControllerDidDisconnect(_ notification: Notification) {
        guard let gameController = notification.object as? GCController else {
            return
        }
        if gameController != gamePadCurrent {
            return
        }

        unregisterGameController()

        for controller: GCController in GCController.controllers() where gameController != controller {
            registerGameController(controller)
        }
    }

    func registerGameController(_ gameController: GCController) {

        var buttonA: GCControllerButtonInput?
        var buttonB: GCControllerButtonInput?

        if let gamepad = gameController.extendedGamepad {
            self.gamePadLeft = gamepad.leftThumbstick
            self.gamePadRight = gamepad.rightThumbstick
            buttonA = gamepad.buttonA
            buttonB = gamepad.buttonB
        } else if let gamepad = gameController.gamepad {
            self.gamePadLeft = gamepad.dpad
            buttonA = gamepad.buttonA
            buttonB = gamepad.buttonB
        } else if let gamepad = gameController.microGamepad {
            self.gamePadLeft = gamepad.dpad
            buttonA = gamepad.buttonA
            buttonB = gamepad.buttonX
        }

        weak var weakController = self

        gamePadLeft!.valueChangedHandler = {(_ dpad: GCControllerDirectionPad, _ xValue: Float, _ yValue: Float) -> Void in
            guard let strongController = weakController else {
                return
            }
            strongController.characterDirection = simd_make_float2(xValue, -yValue)
        }

        if let gamePadRight = self.gamePadRight {
            gamePadRight.valueChangedHandler = {(_ dpad: GCControllerDirectionPad, _ xValue: Float, _ yValue: Float) -> Void in
                guard let strongController = weakController else {
                    return
                }
                strongController.cameraDirection = simd_make_float2(xValue, yValue)
            }
        }

        buttonA?.valueChangedHandler = {(_ button: GCControllerButtonInput, _ value: Float, _ pressed: Bool) -> Void in
            guard let strongController = weakController else {
                return
            }
            strongController.controllerJump(pressed)
        }

        buttonB?.valueChangedHandler = {(_ button: GCControllerButtonInput, _ value: Float, _ pressed: Bool) -> Void in
            guard let strongController = weakController else {
                return
            }
            strongController.controllerAttack()
        }

#if os( iOS )
    if gamePadLeft != nil {
            overlay!.hideVirtualPad()
        }
#endif
    }

    func unregisterGameController() {
        gamePadLeft = nil
        gamePadRight = nil
        gamePadCurrent = nil
#if os( iOS )
        overlay!.showVirtualPad()
#endif
    }

#if os( iOS )
    // MARK: - PadOverlayDelegate

    func padOverlayVirtualStickInteractionDidStart(_ padNode: PadOverlay) {
        if padNode == overlay!.controlOverlay!.leftPad {
            characterDirection = float2(Float(padNode.stickPosition.x), -Float(padNode.stickPosition.y))
        }
        if padNode == overlay!.controlOverlay!.rightPad {
            cameraDirection = float2( -Float(padNode.stickPosition.x), Float(padNode.stickPosition.y))
        }
    }

    func padOverlayVirtualStickInteractionDidChange(_ padNode: PadOverlay) {
        if padNode == overlay!.controlOverlay!.leftPad {
            characterDirection = float2(Float(padNode.stickPosition.x), -Float(padNode.stickPosition.y))
        }
        if padNode == overlay!.controlOverlay!.rightPad {
            cameraDirection = float2( -Float(padNode.stickPosition.x), Float(padNode.stickPosition.y))
        }
    }

    func padOverlayVirtualStickInteractionDidEnd(_ padNode: PadOverlay) {
        if padNode == overlay!.controlOverlay!.leftPad {
            characterDirection = [0, 0]
        }
        if padNode == overlay!.controlOverlay!.rightPad {
            cameraDirection = [0, 0]
        }
    }

    func willPress(_ button: ButtonOverlay) {
        if button == overlay!.controlOverlay!.buttonA {
            controllerJump(true)
        }
        if button == overlay!.controlOverlay!.buttonB {
            controllerAttack()
        }
    }

    func didPress(_ button: ButtonOverlay) {
        if button == overlay!.controlOverlay!.buttonA {
            controllerJump(false)
        }
    }
#endif
}
