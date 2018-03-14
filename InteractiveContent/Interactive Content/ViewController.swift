/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Main view controller for the Interactive Content sample app.  This file manages the interactions between the view and ARKit.
 */

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
	@IBOutlet weak var toast: UIVisualEffectView!
	@IBOutlet weak var label: UILabel!
	var chameleon = Chameleon()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
		
        // Set the scene to the view
        sceneView.scene = chameleon
		
		// The chameleon uses an environment map, so disable built-in lighting
		sceneView.automaticallyUpdatesLighting = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
		
		guard ARWorldTrackingConfiguration.isSupported else {
			fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
		}
		
		// Prevent the screen from being dimmed after a while.
		UIApplication.shared.isIdleTimerDisabled = true
        
        // Start a new session
		startNewSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
	
	func startNewSession() {
		// hide toast
		self.toast.alpha = 0
		self.toast.frame = self.toast.frame.insetBy(dx: 5, dy: 5)
		
		chameleon.hide()
		
		// Create a session configuration with horizontal plane detection
		let configuration = ARWorldTrackingConfiguration()
		configuration.planeDetection = .horizontal
		
		// Run the view's session
		sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
	}
	
	// MARK: - Gesture Recognizers
	
	@IBAction func didTap(_ recognizer: UITapGestureRecognizer) {
		let location = recognizer.location(in: sceneView)
		
		// When tapped on the object, call the object's method to react on it
		let sceneHitTestResult = sceneView.hitTest(location, options: nil)
		if !sceneHitTestResult.isEmpty {
			// We only have one content, so we know which node was hit.
			// If the scene contains multiple objects, you would need to check here if the right node was hit
			chameleon.reactToTap(in: sceneView)
			return
		}
		
		// When tapped on a plane, reposition the content
		let arHitTestResult = sceneView.hitTest(location, types: .existingPlane)
		if !arHitTestResult.isEmpty {
			let hit = arHitTestResult.first!
			chameleon.setTransform(hit.worldTransform)
			chameleon.reactToPositionChange(in: sceneView)
		}
	}
	
	@IBAction func didPan(_ recognizer: UIPanGestureRecognizer) {
		let location = recognizer.location(in: sceneView)
		
		// Drag the object on an infinite plane
		let arHitTestResult = sceneView.hitTest(location, types: .existingPlane)
		if !arHitTestResult.isEmpty {
			let hit = arHitTestResult.first!
			chameleon.setTransform(hit.worldTransform)
			
			if recognizer.state == .ended {
				chameleon.reactToPositionChange(in: sceneView)
			}
		}
	}
}

extension ViewController: ARSCNViewDelegate {
	
	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
		if chameleon.isVisible() { return }
		
		// Unhide the content and position it on the detected plane
		if anchor is ARPlaneAnchor {
			chameleon.setTransform(anchor.transform)
			chameleon.show()
			chameleon.reactToInitialPlacement(in: sceneView)
			
			DispatchQueue.main.async {
				self.hideToast()
			}
		}
	}
	
	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		chameleon.reactToRendering(in: sceneView)
	}
	
	func renderer(_ renderer: SCNSceneRenderer, didApplyConstraintsAtTime time: TimeInterval) {
		chameleon.reactToDidApplyConstraints(in: sceneView)
	}
}

extension ViewController: ARSessionObserver {
	
	func sessionWasInterrupted(_ session: ARSession) {
		showToast("Session was interrupted")
	}
	
	func sessionInterruptionEnded(_ session: ARSession) {
		startNewSession()
	}
	
	func session(_ session: ARSession, didFailWithError error: Error) {
		showToast("Session failed: \(error.localizedDescription)")
		startNewSession()
	}
	
	func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
		var message: String? = nil
		
		switch camera.trackingState {
		case .notAvailable:
			message = "Tracking not available"
		case .limited(.initializing):
			message = "Initializing AR session"
		case .limited(.excessiveMotion):
			message = "Too much motion"
		case .limited(.insufficientFeatures):
			message = "Not enough surface details"
		case .normal:
			if !chameleon.isVisible() {
				message = "Move to find a horizontal surface"
			}
		default:
			// We are only concerned with the tracking states above.
			message = "Camera changed tracking state"
		}
		
		message != nil ? showToast(message!) : hideToast()
	}
}

extension ViewController {
	
	func showToast(_ text: String) {
		label.text = text
		
		guard toast.alpha == 0 else {
			return
		}
		
		toast.layer.masksToBounds = true
		toast.layer.cornerRadius = 7.5
		
		UIView.animate(withDuration: 0.25, animations: {
			self.toast.alpha = 1
			self.toast.frame = self.toast.frame.insetBy(dx: -5, dy: -5)
		})
		
	}
	
	func hideToast() {
		UIView.animate(withDuration: 0.25, animations: {
			self.toast.alpha = 0
			self.toast.frame = self.toast.frame.insetBy(dx: 5, dy: 5)
		})
	}
}
