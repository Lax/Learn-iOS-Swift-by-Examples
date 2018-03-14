/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Main view controller for the AR experience.
 */

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    // MARK: - IBOutlets
    
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    
    lazy var screenCenter: CGPoint = {
        CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
    }()
    
    // Shows a preview of the object to be placed and hovers over estimated planes.
    var previewNode: PreviewNode?
    
    // Contains the model that is shared by the preview and final nodes.
    var contentNode = SCNNode()
    
    // Audio source for positional audio feedback.
    var audioSource: SCNAudioSource = SCNAudioSource(fileNamed: "Assets.scnassets/ping.aif")!
    
    // State variable used to flag relocalization completion
    var relocalizing = false
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show statistics such as FPS and timing information.
        sceneView.showsStatistics = true
        
        // Setup environment mapping.
        let environmentMap = UIImage(named: "Assets.scnassets/sharedImages/environment_blur.exr")!
        sceneView.scene.lightingEnvironment.contents = environmentMap
        
        // Complete rendering setup of ARSCNView.
        sceneView.antialiasingMode = .multisampling4X
        sceneView.automaticallyUpdatesLighting = false
        
        sceneView.contentScaleFactor = 1.3
        
        // Setup the audio file.
        audioSource.loops = true
        audioSource.load()
        
        // Prevent the screen from being dimmed after a while as users will likely have
        // long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    /// - Tag: StartARSession
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Start the ARSession.
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        contentNode.removeAllAudioPlayers()
        
        // Pause the view's session.
        sceneView.session.pause()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // The screen's center point changes on orientation switch, so recalculate `screenCenter`.
        screenCenter = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
    }
    
    // MARK: - Internal methods
    
    // Check the light estimate from the current ARFrame and update the scene.
    private func updateLightEstimate() {
        if let lightEstimate = sceneView.session.currentFrame?.lightEstimate {
            sceneView.scene.lightingEnvironment.intensity = lightEstimate.ambientIntensity / 40.0
        } else {
            sceneView.scene.lightingEnvironment.intensity = 40.0
        }
    }
    
    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        // Reset preview state.
        contentNode.removeFromParentNode()
        contentNode = SCNNode()
        previewNode?.removeFromParentNode()
        previewNode = nil
        playSound()
    }
    
    private func setNewVirtualObjectToAnchor(_ object: SCNNode, to anchor: ARAnchor, cameraTransform: matrix_float4x4) {
        let cameraWorldPosition = cameraTransform.translation
        var cameraToPosition = anchor.transform.translation - cameraWorldPosition
        
        // Limit the distance of the object from the camera to a maximum of 10 meters.
        if simd_length(cameraToPosition) > 10 {
            cameraToPosition = simd_normalize(cameraToPosition)
            cameraToPosition *= 10
        }
        
        object.simdPosition = cameraWorldPosition + cameraToPosition
    }
    
    // MARK: - ARSCNViewDelegate
    
    /// - Tag: UpdateAudioPlayback
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if contentNode.parent == nil && previewNode == nil {
            // If our model hasn't been placed and we lack a preview for placement then setup a preview.
            setupPreviewNode()
            updatePreviewNode()
        } else {
            updatePreviewNode()
        }
        updateLightEstimate()
        cutVolumeIfPlacedObjectIsInView()
    }
    
    /// - Tag: PlaceARContent
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        // Place content only for anchors found by plane detection.
        guard anchor is ARPlaneAnchor && previewNode != nil
            else { return }
        
        // Stop showing a preview version of the object to be placed.
        contentNode.removeFromParentNode()
        previewNode?.removeFromParentNode()
        previewNode = nil
        
        // Add the contenNode to the scene's root node using the anchor's position.
        guard let cameraTransform = sceneView.session.currentFrame?.camera.transform
            else { return }
        setNewVirtualObjectToAnchor(contentNode, to: anchor, cameraTransform: cameraTransform)
        sceneView.scene.rootNode.addChildNode(contentNode)
        
        // Disable plane detection after the model has been added.
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [])
        
        // Set up positional audio to play in case the object moves offscreen.
        playSound()
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let message: String
        
        // Inform the user of their camera tracking state.
        switch camera.trackingState {
        case .notAvailable:
            message = "Tracking unavailable"
        case .normal:
            message = "Tracking normal"
            endRelocalization()
        case .limited(.excessiveMotion):
            message = "Tracking limited - Too much camera movement"
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Not enough surface detail"
        case .limited(.initializing):
            message = "Initializing AR Session"
        case .limited(.relocalizing):
            beginRelocalization()
            message = "Recovering from interruption. Return to the location where you left off or try resetting the session."
        }
        
        sessionInfoLabel.text = message
    }
    
    // Called after the session state has changed to "relocalizing"
    func beginRelocalization() {
        relocalizing = true
        // Hide our content because it's position is very likely incorrect.
        contentNode.isHidden = true
        // Start the tracking reset timer.
        trackingResetTimer = Timer.scheduledTimer(withTimeInterval: relocalizationLimit, repeats: false, block: { [unowned self] _ in
            self.sessionInfoLabel.text = "Failed to relocalize the AR session. Resetting the AR session."
            self.resetTracking()
        })
        // Mute audio since it can no longer be associated with our hidden content.
        guard let player = contentNode.audioPlayers.first,
            let avNode = player.audioNode as? AVAudioMixing else {
                return
        }
        avNode.volume = 0.0
    }
    
    // Called after the session state has changed from "relocalizing" to "normal"
    func endRelocalization() {
        if relocalizing {
            relocalizing = false
            // Show our content and reenable audio.
            contentNode.isHidden = false
            // Stop the reset timer.
            trackingResetTimer.invalidate()
            // Resume the audio.
            guard let player = contentNode.audioPlayers.first else {
                playSound()
                return
            }
            // Restore volume on contenNode's existing audio player.
            if let avNode = player.audioNode as? AVAudioMixing {
                avNode.volume = 1.0
            }
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription). Resetting the AR session."
        resetTracking()
    }
    
    // Countdown timer used to reset our AR tracking and session if we are unable to relocalize within relocalizationLimit seconds.
    private var trackingResetTimer = Timer()
    private let relocalizationLimit = TimeInterval(30.0)
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        sessionInfoLabel.text = "Session was interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        sessionInfoLabel.text = "Session interruption ended"
        // If object has not been placed yet, reset tracking
        if previewNode != nil {
            resetTracking()
        }
    }
    
    /*
     Allow the session to attempt to resume after an interruption.
     This process may not succeed, so the app must be prepared
     to reset the session if the relocalizing status continues
     for a long time.
     */
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        // Only relocalize if the object had been placed
        if previewNode != nil { return false }
        return true
    }
    
    // MARK: - Preview Node
    
    /*
     Loads the model (`contenNode`) that is used for the duration of the app.
     Initializes a `PreviewNode` that contains the `contenNode` and adds it to the node hierarchy.
     */
    func setupPreviewNode() {
        if (contentNode.childNode(withName: "candle", recursively: false) == nil) {
            // Load the scene from the bundle only once.
            let modelScene = SCNScene(named: "Assets.scnassets/candle/candle.scn")!
            // Get a handle to the model.
            let model = modelScene.rootNode.childNode(withName: "candle", recursively: true)!
            // Set the model onto `contenNode`.
            contentNode.addChildNode(model)
        }
        // Initialize `previewNode` to display the model.
        previewNode = PreviewNode(node: contentNode)
        // Add `previewNode` to the node hierarchy.
        sceneView.scene.rootNode.addChildNode(previewNode!)
    }
    
    /*
     `previewNode` exists when ARKit is finding a plane. During this time, get a world position for the areas closest to the scene's point of view that ARKit believes might be a plane, and use it to update the `previewNode` position.
     */
    func updatePreviewNode() {
        guard let node = previewNode else { return }
        let (worldPosition, planeAnchor, _) = worldPositionFromScreenPosition(screenCenter,
                                                                              in: sceneView,
                                                                              objectPos: node.simdPosition)
        if let position = worldPosition {
            node.update(for: position, planeAnchor: planeAnchor, camera: sceneView.session.currentFrame?.camera)
        }
    }
    
    // MARK: - Sound
    
    /*
     Determines whether the `contenNode` is visible. If the `contenNode` isn't visible, a sound is played using
     SceneKit's positional audio functionality to locate the `contenNode`.
     */
    func cutVolumeIfPlacedObjectIsInView() {
        guard previewNode == nil, let pointOfView = sceneView.pointOfView else { return }
        
        guard let player = contentNode.audioPlayers.first,
            let avNode = player.audioNode as? AVAudioMixing else {
                return
        }
        
        let placedObjectIsInView = sceneView.isNode(contentNode, insideFrustumOf: pointOfView)
        
        avNode.volume = placedObjectIsInView ? 0.0 : 1.0
    }
    
    // Plays a sound on the contenNode using SceneKit's positional audio.
    /// - Tag: AddAudioPlayer
    func playSound() {
        // Ensure there is only one audio player.
        contentNode.removeAllAudioPlayers()
        guard contentNode.audioPlayers.count == 0 else {
            return
        }
        contentNode.addAudioPlayer(SCNAudioPlayer(source: audioSource))
    }
}
