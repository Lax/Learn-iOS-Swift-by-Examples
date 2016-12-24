/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	WatchOS WKInterfaceController implementation of the game.
 */

import WatchKit
import Foundation
import simd
import SceneKit
import SpriteKit

class InterfaceController: WKInterfaceController {
    // MARK: Types
    
    /// A struct containing all the `SCNNode`s used in the game.
    struct GameNodes {
        let object: SCNNode
        
        let objectMaterial: SCNMaterial
        
        let confetti: SCNNode
        
        let camera: SCNCamera

        let countdownLabel: SKLabelNode

        let congratulationsLabel: SKLabelNode

        /// Queries the root node for the expected nodes.
        init?(sceneRoot: SCNNode) {
            guard let object = sceneRoot.childNode(withName: "teapot", recursively:true), let objectMaterial = object.geometry?.firstMaterial else { return nil }
            guard let confetti = sceneRoot.childNode(withName: "particles", recursively: true) else { return nil }
            guard let camera = sceneRoot.childNode(withName: "camera", recursively: true)!.camera else { return nil }
            
            self.object = object
            self.objectMaterial = objectMaterial
            self.confetti = confetti
            self.camera = camera
            
            countdownLabel = SKLabelNode()
            countdownLabel.horizontalAlignmentMode = .center

            congratulationsLabel = SKLabelNode(text: "You Win!")
            congratulationsLabel.fontColor = InterfaceController.GameColors.defaultFont
            congratulationsLabel.fontSize = 45;
        }
    }
    
    /// Defines the colors used in the game.
    struct GameColors {
        static let defaultFont = UIColor(red:31.0/255, green:226.0/255.0, blue:63.0/255.0, alpha:1.0)
        static let warning = UIColor.orange
        static let danger = UIColor.red
    }
    

    // MARK: Properties
    
    @IBOutlet var sceneInterface: WKInterfaceSCNScene!

    var gameNodes: GameNodes?

    var gameStarted = false

    var initialObject3DRotation = SCNMatrix4Identity
    
    var initialSphereLocation = float3()
    
    var countdown = 0
    
    weak var textUpdateTimer: Timer?
    
    weak var particleRemovalTimer: Timer?

    // MARK: WKInterfaceController
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        setupGame()
    }

    override func willActivate() {
        // Start the game if not already started.
        if !gameStarted {
            startGame()
        }
        
        super.willActivate()
    }

    // MARK: IB Actions
    
    @IBAction func handleTap(sender: AnyObject) {
        if let tapGesture = sender as? WKTapGestureRecognizer {
            if tapGesture.numberOfTapsRequired == 1 && !gameStarted {
                // Restart the game on single tap only if presenting congratulation screen.
                startGame()
            }
        }
    }
    
    // MARK: Gesture reconginzer handling

    /**
        Handle rotation of the 3D object by computing rotations of a virtual
        trackball using the pan gesture touch locations.
     
        On state ended, end the game if the object has the right orientation.
    */
    @IBAction func handlePan(panGesture: WKPanGestureRecognizer) {
        guard let gameNodes = gameNodes, gameStarted else { return }

        let location = panGesture.locationInObject()
        let bounds = panGesture.objectBounds()

        // Compute the projection of the interface point to the virtual trackball.
        let sphereLocation = sphereProjection(forInterfaceLocation: location, inBounds: bounds)

        switch panGesture.state {
            case .began:
                // Record initial states.
                initialSphereLocation = sphereLocation
                initialObject3DRotation = gameNodes.object.transform
            
            case .cancelled, .ended, .changed:
                // Compute the rotation and apply to the object.
                let currentRotation = rotationFromPoint(initialSphereLocation, to: sphereLocation)
                gameNodes.object.transform = SCNMatrix4Mult(initialObject3DRotation, currentRotation)
            
            default:
                debugPrint("Unhandled gesture state: \(panGesture.state)")
        }

        // End the game if the object has the initial orientation.
        if panGesture.state == .ended {
            endGameOnCorrectOrientation()
        }
    }

    // MARK: Game flow

    /// Setup overlays and lookup scene objects.
    func setupGame() {
        guard let sceneRoot = sceneInterface.scene?.rootNode, let gameNodes = GameNodes(sceneRoot: sceneRoot) else { fatalError("Unable to load game nodes") }
        self.gameNodes = gameNodes
        
        gameNodes.object.transform = SCNMatrix4Identity
        gameNodes.objectMaterial.transparency = 0.0
        
        gameNodes.confetti.isHidden = true

        let skScene = SKScene(size: CGSize(width: contentFrame.size.width, height: contentFrame.size.height))
        skScene.scaleMode = SKSceneScaleMode.resizeFill
        skScene.addChild(gameNodes.countdownLabel)
        
        sceneInterface.overlaySKScene = skScene
    }

    /// Start the game.
    func startGame() {
        guard let gameNodes = gameNodes else { fatalError("Nodes not set") }
        
        let startSequence = SCNAction.sequence([
            // Wait for 1 second.
            SCNAction.wait(duration: 1.0),
            
            SCNAction.group([
                // Fade in.
                SCNAction.fadeIn(duration: 0.3),
                
                // Start the game.
                SCNAction.run({ [weak self] (node: SCNNode) in
                    guard let gameNodes = self?.gameNodes else { return }
                    
                    // Compute a random orientation for the object3D.
                    let theta = Float(M_PI) * (Float(arc4random()) / 0x100000000)
                    let phi = acosf(2.0 * Float(arc4random()) / 0x100000000 - 1) / Float(M_PI)
                    var axis = float3()
                    axis.x = cosf(theta) * sinf(phi)
                    axis.y = sinf(theta) * sinf(phi)
                    axis.z = cosf(theta)
                    let angle = 2.0 * Float(M_PI) * (Float(arc4random()) / 0x100000000)

                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.3
                    SCNTransaction.completionBlock = {
                        self?.gameStarted = true
                    }
                    
                    gameNodes.objectMaterial.transparency = 1.0
                    gameNodes.object.transform = SCNMatrix4MakeRotation(angle, axis.x, axis.y, axis.z)
                    
                    SCNTransaction.commit()
                }),
            ])
        ])
        gameNodes.object.runAction(startSequence)

        // Load and set the background image.
        let backgroundImage = UIImage(named:"art.scnassets/background.png")
        sceneInterface.scene?.background.contents = backgroundImage

        // Hide particles, set camera projection to orthographic.
        particleRemovalTimer?.invalidate()
        gameNodes.congratulationsLabel.removeFromParent()
        gameNodes.confetti.isHidden = true
        gameNodes.camera.usesOrthographicProjection = true

        // Reset the countdown.
        countdown = 30
        gameNodes.countdownLabel.text = "\(countdown)"
        gameNodes.countdownLabel.fontColor = InterfaceController.GameColors.defaultFont

        gameNodes.countdownLabel.position = CGPoint(x: contentFrame.size.width / 2, y: contentFrame.size.height - 30)

        textUpdateTimer?.invalidate()
        textUpdateTimer = Timer.scheduledTimer(timeInterval: 1,
                                               target: self,
                                               selector: #selector(updateText(timer:)),
                                               userInfo: nil,
                                               repeats: true)
    }

    /// Update countdown timer.
    func updateText(timer: Timer) {
        guard let gameNodes = gameNodes else { fatalError("Nodes not set") }
        
        gameNodes.countdownLabel.text = "\(countdown)"
        sceneInterface.isPlaying = true
        sceneInterface.isPlaying = false
        countdown -= 1

        if countdown < 0 {
            gameNodes.countdownLabel.fontColor = InterfaceController.GameColors.danger
            textUpdateTimer?.invalidate()
            return
        }
        else if countdown < 10 {
            gameNodes.countdownLabel.fontColor = InterfaceController.GameColors.warning
        }
    }

    /**
        End the game by showing the congratulation screen after fading the object
        to white.
    */
    func endGame() {
        guard let gameNodes = gameNodes else { fatalError("Nodes not set") }
        
        textUpdateTimer?.invalidate()

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        SCNTransaction.completionBlock = { () in
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            SCNTransaction.completionBlock = { [weak self] () in
                self?.showCongratulation()
                gameNodes.objectMaterial.emission.contents = UIColor.black
                self?.gameStarted = false
            }
            SCNTransaction.commit()
        }
        
        gameNodes.object.transform = SCNMatrix4Identity
        gameNodes.objectMaterial.emission.contents = UIColor.white
        gameNodes.objectMaterial.transparency = 0.0
        
        SCNTransaction.commit()
    }
    
    // MARK: Convenience

    /// Compute the projection of screen points to unit sphere points.
    func sphereProjection(forInterfaceLocation location: CGPoint, inBounds bounds: CGRect) -> float3 {
        let screenLocation = screenProjection(forInterfaceLocation: location, inBounds: bounds)
        return sphereProjection(forScreenLocation: screenLocation)
    }

    /// Compute projection from object interface to virtual screen on the range [-1, 1].
    func screenProjection(forInterfaceLocation location: CGPoint, inBounds bounds: CGRect) -> CGPoint {
        let w = bounds.size.width
        let h = bounds.size.height
        let aspectRatioCorrection = (h - w) / 2
        var screenCoord = CGPoint(x: location.x / w * 2.0 - 1.0,
                                  y: ((h - location.y) - aspectRatioCorrection) / w * 2.0 - 1.0)
        screenCoord.x = min(1.0, max(-1.0, screenCoord.x))
        screenCoord.y = min(1.0, max(-1.0, screenCoord.y))
        return screenCoord
    }

    /// Compute projection of virtual screen point to unit sphere.
    func sphereProjection(forScreenLocation location: CGPoint) -> float3 {
        var sphereCoord = float3()
        let squaredLenght = location.x * location.x + location.y * location.y
        
        if squaredLenght <= 1.0 {
            sphereCoord.x = Float(location.x)
            sphereCoord.y = Float(location.y)
            sphereCoord.z = sqrtf(1.0 - Float(squaredLenght))
        } else {
            let n = 1.0 / sqrtf(Float(squaredLenght))
            sphereCoord.x = n * Float(location.x)
            sphereCoord.y = n * Float(location.y)
            sphereCoord.z = 0
        }
        
        return sphereCoord
    }

    /// Compute the rotation matrix from one point to another on a unit sphere.
    func rotationFromPoint(_ start: float3, to end: float3) -> SCNMatrix4 {
        let axis = cross(start, end)
        let angle = atan2f(length(axis), dot(start, end))
        
        return SCNMatrix4MakeRotation(angle, axis.x, axis.y, axis.z)
    }

    /// End the game if the object has its initial orientation with a 10 degree tolerance.
    func endGameOnCorrectOrientation() {
        guard let gameNodes = gameNodes, gameStarted else { return }
        
        let transform = SCNMatrix4ToMat4(gameNodes.object.transform)
        let unitX: float4 = [1 , 0, 0, 0]
        let unitY: float4 = [0 , 1, 0, 0]
        let tX: float4 = matrix_multiply(unitX, transform)
        let tY: float4 = matrix_multiply(unitY, transform)

        let toleranceDegree : Float = 10.0
        let max_cos_angle = cosf(toleranceDegree * Float(M_PI) / 180)
        let cos_angleX = dot(unitX, tX)
        let cos_angleY = dot(unitY, tY)
        
        if cos_angleX >= max_cos_angle && cos_angleY >= max_cos_angle {
            endGame()
        }
    }

    // Show the congratulation screen.
    func showCongratulation() {
        guard let gameNodes = gameNodes else { fatalError("Nodes not set") }

        gameNodes.camera.usesOrthographicProjection = false

        sceneInterface.scene?.background.contents = UIColor.black

        gameNodes.confetti.isHidden = false
        particleRemovalTimer?.invalidate()
        particleRemovalTimer = Timer.scheduledTimer(timeInterval: 30,
                                                    target: self,
                                                    selector: #selector(removeParticles(timer:)),
                                                    userInfo: nil,
                                                    repeats:false)

        gameNodes.congratulationsLabel.removeFromParent()
        gameNodes.congratulationsLabel.position = CGPoint(x: contentFrame.size.width/2 , y: contentFrame.size.height/2)
        gameNodes.congratulationsLabel.xScale = 0;
        gameNodes.congratulationsLabel.yScale = 0;
        gameNodes.congratulationsLabel.alpha = 0;
        gameNodes.congratulationsLabel.run(
            SKAction.group([
                SKAction.fadeIn(withDuration:0.25),
                SKAction.sequence([
                    SKAction.scale(to: 0.70, duration:0.25),
                    SKAction.scale(to: 0.80, duration:0.2)]),
            ])
        )

        sceneInterface.overlaySKScene?.addChild(gameNodes.congratulationsLabel)
    }

    // Remove the confetti particles.
    func removeParticles(timer: Timer) {
        guard let gameNodes = gameNodes else { fatalError("Nodes not set") }

        gameNodes.confetti.isHidden = true
    }
}
