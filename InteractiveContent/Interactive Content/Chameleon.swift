/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This file manages the movements and display of the Chameleon using SceneKit.
 */

import Foundation
import SceneKit
import ARKit

class Chameleon: SCNScene {
	
	// Special nodes used to control animations of the model
	private let contentRootNode = SCNNode()
	private var geometryRoot: SCNNode!
	private var head: SCNNode!
	private var leftEye: SCNNode!
	private var rightEye: SCNNode!
	private var jaw: SCNNode!
	private var tongueTip: SCNNode!
	private var focusOfTheHead = SCNNode()
	private var focusOfLeftEye = SCNNode()
	private var focusOfRightEye = SCNNode()
	private var tongueRestPositionNode = SCNNode()
	private var skin: SCNMaterial!
	
	// Animations
	private var idleAnimation: SCNAnimation?
	private var turnLeftAnimation: SCNAnimation?
	private var turnRightAnimation: SCNAnimation?
	
	// State variables
	private var modelLoaded: Bool = false
	private var headIsMoving: Bool = false
	private var chameleonIsTurning: Bool = false
	
	private let focusNodeBasePosition = simd_float3(0, 0.1, 0.25)
	private var leftEyeTargetOffset = simd_float3()
	private var rightEyeTargetOffset = simd_float3()
	private var currentTonguePosition = simd_float3()
	private var relativeTongueStickOutFactor: Float = 0
	private var readyToShootCounter: Int = 0
	private var triggerTurnLeftCounter: Int = 0
	private var triggerTurnRightCounter: Int = 0
	private var lastRelativePosition: RelativeCameraPositionToHead = .tooHighOrLow
	private var lastDistance: Float = Float.greatestFiniteMagnitude
	private var didEnterTargetLockDistance = false
	private var mouthAnimationState: MouthAnimationState = .mouthClosed
	
	private var changeColorTimer: Timer?
	private var lastColorFromEnvironment = SCNVector3(130.0 / 255.0, 196.0 / 255.0, 174.0 / 255.0)
	
	// Enums to describe the current state
	private enum RelativeCameraPositionToHead {
		case withinFieldOfView(Distance)
		case needsToTurnLeft
		case needsToTurnRight
		case tooHighOrLow
		
		var rawValue: Int {
			switch self {
			case .withinFieldOfView(_) : return 0
			case .needsToTurnLeft : return 1
			case .needsToTurnRight: return 2
			case .tooHighOrLow : return 3
			}
		}
	}
	
	private enum Distance {
		case outsideTargetLockDistance
		case withinTargetLockDistance
		case withinShootTongueDistance
	}
	
	private enum MouthAnimationState {
		case mouthClosed
		case mouthMoving
		case shootingTongue
		case pullingBackTongue
	}
	
	// MARK: - Initialization and Loading
	
	override init() {
		super.init()
		
		// Load the environment map
		self.lightingEnvironment.contents = UIImage(named: "art.scnassets/environment_blur.exr")!
		
		// Load the chameleon
		loadModel()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func loadModel() {
		guard let virtualObjectScene = SCNScene(named: "chameleon", inDirectory: "art.scnassets") else {
			return
		}
		
		let wrapperNode = SCNNode()
		for child in virtualObjectScene.rootNode.childNodes {
			wrapperNode.addChildNode(child)
		}
		self.rootNode.addChildNode(contentRootNode)
		contentRootNode.addChildNode(wrapperNode)
		hide()
		
		setupSpecialNodes()
		setupConstraints()
		setupShader()
		preloadAnimations()
		resetState()
		
		modelLoaded = true
	}
	
	// MARK: - Public API
	
	func show() {
		contentRootNode.isHidden = false
	}
	
	func hide() {
		contentRootNode.isHidden = true
		resetState()
	}
	
	func isVisible() -> Bool {
		return !contentRootNode.isHidden
	}
	
	func setTransform(_ transform: simd_float4x4) {
		contentRootNode.simdTransform = transform
	}
	
	// MARK: - Turn left/right and idle animations
	
	private func preloadAnimations() {
		idleAnimation = SCNAnimation.fromFile(named: "anim_idle", inDirectory: "art.scnassets")
		idleAnimation?.repeatCount = -1
		
		turnLeftAnimation = SCNAnimation.fromFile(named: "anim_turnleft", inDirectory: "art.scnassets")
		turnLeftAnimation?.repeatCount = 1
		turnLeftAnimation?.blendInDuration = 0.3
		turnLeftAnimation?.blendOutDuration = 0.3
		
		turnRightAnimation = SCNAnimation.fromFile(named: "anim_turnright", inDirectory: "art.scnassets")
		turnRightAnimation?.repeatCount = 1
		turnRightAnimation?.blendInDuration = 0.3
		turnRightAnimation?.blendOutDuration = 0.3
		
		// Start playing idle animation.
		if let anim = idleAnimation {
			contentRootNode.childNodes[0].addAnimation(anim, forKey: anim.keyPath)
		}
		
		tongueTip.removeAllAnimations()
		leftEye.removeAllAnimations()
		rightEye.removeAllAnimations()
		chameleonIsTurning = false
		headIsMoving = false
	}
	
	private func playTurnAnimation(_ animation: SCNAnimation) {
		var rotationAngle: Float = 0
		if animation == turnLeftAnimation {
			rotationAngle = Float.pi / 4
		} else if animation == turnRightAnimation {
			rotationAngle = -Float.pi / 4
		}
		
		let modelBaseNode = contentRootNode.childNodes[0]
		modelBaseNode.addAnimation(animation, forKey: animation.keyPath)
		
		chameleonIsTurning = true
		SCNTransaction.begin()
		SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
		SCNTransaction.animationDuration = animation.duration
		modelBaseNode.transform = SCNMatrix4Mult(modelBaseNode.presentation.transform, SCNMatrix4MakeRotation(rotationAngle, 0, 1, 0))
		SCNTransaction.completionBlock = {
			self.chameleonIsTurning = false
		}
		SCNTransaction.commit()
	}
	
	// MARK: - Head and tongue animations
	
	private func relativePositionToHead(pointOfViewPosition: simd_float3) -> RelativeCameraPositionToHead {
		// Compute angles between camera position and chameleon
		let cameraPosLocal = head.simdConvertPosition(pointOfViewPosition, from: nil)
		let cameraPosLocalComponentX = simd_float3(cameraPosLocal.x, head.position.y, cameraPosLocal.z)
		let dist = simd_length(cameraPosLocal - head.simdPosition)
		
		let xAngle = acos(simd_dot(simd_normalize(head!.simdPosition), simd_normalize(cameraPosLocalComponentX))) * 180 / Float.pi
		let yAngle = asin(cameraPosLocal.y / dist) * 180 / Float.pi
		
		let selfToUserDistance = simd_length(pointOfViewPosition - jaw.simdWorldPosition)
		
		var relativePosition: RelativeCameraPositionToHead
		
		if yAngle > 60 {
			relativePosition = .tooHighOrLow
		} else if xAngle > 60 {
			relativePosition = cameraPosLocal.x < 0 ? .needsToTurnLeft : .needsToTurnRight
		} else {
			var distanceCategory: Distance
			
			switch selfToUserDistance {
			case 0..<0.3:
				distanceCategory = .withinShootTongueDistance
			case 0.3..<0.45:
				distanceCategory = .withinTargetLockDistance
				if lastDistance > 0.45 || lastRelativePosition.rawValue > 0 {
					didEnterTargetLockDistance = true
				}
			default:
				distanceCategory = .outsideTargetLockDistance
			}
			relativePosition = .withinFieldOfView(distanceCategory)
		}
		
		lastDistance = selfToUserDistance
		lastRelativePosition = relativePosition
		return relativePosition
	}
	
	private func openCloseMouthAndShootTongue() {
		
		let startShootEvent = SCNAnimationEvent(keyTime: 0.07) { (_, _, _) in
			self.mouthAnimationState = .shootingTongue
		}
		let endShootEvent = SCNAnimationEvent(keyTime: 0.65) { (_, _, _) in
			self.mouthAnimationState = .pullingBackTongue
		}
		let mouthClosedEvent = SCNAnimationEvent(keyTime: 0.99) { (_, _, _) in
			self.mouthAnimationState = .mouthClosed
			self.readyToShootCounter = -100
		}
		
		let animation = CAKeyframeAnimation(keyPath: "eulerAngles.x")
		animation.duration = 4.0
		animation.keyTimes = [0.0, 0.05, 0.75, 1.0]
		animation.values = [0, -0.4, -0.4, 0]
		animation.timingFunctions = [
			CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut),
			CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear),
			CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
		]
		animation.animationEvents = [startShootEvent, endShootEvent, mouthClosedEvent]
		
		mouthAnimationState = .mouthMoving
		jaw.addAnimation(animation, forKey: "open close mouth")
		
		// Move the head a little bit up.
		let headUpAnimation = CAKeyframeAnimation(keyPath: "position.y")
		let startY = focusOfTheHead.position.y
		headUpAnimation.duration = 4.0
		headUpAnimation.keyTimes = [0.0, 0.05, 0.75, 1.0]
		headUpAnimation.values = [startY, startY + 0.1, startY + 0.1, startY]
		headUpAnimation.timingFunctions = [
			CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut),
			CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear),
			CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
		]
		focusOfTheHead.addAnimation(headUpAnimation, forKey: "move head up")
	}
}

// MARK: - React To Placement and Tap

extension Chameleon {
	
	func reactToPositionChange(in view: ARSCNView) {
		self.reactToPlacement(in: view)
	}
	
	func reactToInitialPlacement(in view: ARSCNView) {
		self.reactToPlacement(in: view, isInitial: true)
	}
	
	private func reactToPlacement(in sceneView: ARSCNView, isInitial: Bool = false) {
		if isInitial {
			DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
				self.getColorFromEnvironment(sceneView: sceneView)
				self.activateCamouflage(true)
			})
		} else {
			DispatchQueue.main.async {
				self.updateCamouflage(sceneView: sceneView)
			}
		}
	}
	
	func reactToTap(in sceneView: ARSCNView) {
		self.activateCamouflage(false)
		DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
			self.activateCamouflage(true)
		})
	}
	
	private func activateCamouflage(_ activate: Bool) {
		skin.setValue(NSValue(scnVector3: lastColorFromEnvironment), forKey: "skinColorFromEnvironment")
		
		let blendFactor = activate ? 1.0 : 0.0
		
		SCNTransaction.begin()
		SCNTransaction.animationDuration = 1.5
		skin.setValue(blendFactor, forKey: "blendFactor")
		SCNTransaction.commit()
	}
	
	private func updateCamouflage(sceneView: ARSCNView) {
		getColorFromEnvironment(sceneView: sceneView)
		
		SCNTransaction.begin()
		SCNTransaction.animationDuration = 1.5
		self.skin.setValue(NSValue(scnVector3: lastColorFromEnvironment), forKey: "skinColorFromEnvironment")
		SCNTransaction.commit()
	}
	
	private func getColorFromEnvironment(sceneView: ARSCNView) {
		let worldPos = sceneView.projectPoint(contentRootNode.worldPosition)
		let colorVector = sceneView.averageColorFromEnvironment(at: worldPos)
		lastColorFromEnvironment = colorVector
	}
}

// MARK: - React To Rendering

extension Chameleon {
	
	func reactToRendering(in sceneView: ARSCNView) {
		// Update environment map to match ambient light level
		lightingEnvironment.intensity = (sceneView.session.currentFrame?.lightEstimate?.ambientIntensity ?? 1000) / 100
		
		guard modelLoaded, !chameleonIsTurning, let pointOfView = sceneView.pointOfView else {
			return
		}
		
		let localTarget = focusOfTheHead.parent!.simdConvertPosition(pointOfView.simdWorldPosition, from: nil)
		followUserWithEyes(to: localTarget)
		
		// Obtain relative position of the head to the camera and act accordingly.
		let relativePos = self.relativePositionToHead(pointOfViewPosition: pointOfView.simdPosition)
		switch relativePos {
		case .withinFieldOfView(let distance):
			handleWithinFieldOfView(localTarget: localTarget, distance: distance)
		case .needsToTurnLeft:
			followUserWithHead(to: simd_float3(0.4, focusNodeBasePosition.y, focusNodeBasePosition.z))
			triggerTurnLeftCounter += 1
			if triggerTurnLeftCounter > 150 {
				triggerTurnLeftCounter = 0
				if let anim = turnLeftAnimation {
					playTurnAnimation(anim)
				}
			}
		case .needsToTurnRight:
			followUserWithHead(to: simd_float3(-0.4, focusNodeBasePosition.y, focusNodeBasePosition.z))
			triggerTurnRightCounter += 1
			if triggerTurnRightCounter > 150 {
				triggerTurnRightCounter = 0
				if let anim = turnRightAnimation {
					playTurnAnimation(anim)
				}
			}
		case .tooHighOrLow:
			followUserWithHead(to: focusNodeBasePosition)
		}
	}
	
	private func handleWithinFieldOfView(localTarget: simd_float3, distance: Distance) {
		triggerTurnLeftCounter = 0
		triggerTurnRightCounter = 0
		switch distance {
		case .outsideTargetLockDistance:
			followUserWithHead(to: localTarget)
		case .withinTargetLockDistance:
			followUserWithHead(to: localTarget, instantly: !didEnterTargetLockDistance)
		case .withinShootTongueDistance:
			followUserWithHead(to: localTarget, instantly: true)
			if mouthAnimationState == .mouthClosed {
				readyToShootCounter += 1
				if readyToShootCounter > 30 {
					openCloseMouthAndShootTongue()
				}
			} else {
				readyToShootCounter = 0
			}
		}
	}
	
	private func followUserWithHead(to target: simd_float3, instantly: Bool = false) {
		guard !headIsMoving else { return }
		
		if mouthAnimationState != .mouthClosed || instantly {
			focusOfTheHead.simdPosition = target
		} else {
			didEnterTargetLockDistance = false
			headIsMoving = true
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
				let moveToTarget = SCNAction.move(to: SCNVector3(target.x, target.y, target.z), duration: 0.5)
				self.focusOfTheHead.runAction(moveToTarget, completionHandler: {
					self.headIsMoving = false
				})
			})
		}
	}
	
	private func followUserWithEyes(to target: simd_float3) {
		randomlyUpdate(&leftEyeTargetOffset)
		randomlyUpdate(&rightEyeTargetOffset)
		focusOfLeftEye.simdPosition = target + leftEyeTargetOffset
		focusOfRightEye.simdPosition = target + rightEyeTargetOffset
	}
}

// MARK: - React To DidApplyConstraints

extension Chameleon {
	
	func reactToDidApplyConstraints(in sceneView: ARSCNView) {
		guard modelLoaded, let pointOfView = sceneView.pointOfView else {
			return
		}
		
		// Correct the user position such that it is a few centimeters in front of the camera.
		let translationLocal = SCNVector3(0, 0, -0.012)
		let translationWorld = pointOfView.convertVector(translationLocal, to: nil)
		let camTransform = SCNMatrix4Translate(pointOfView.transform, translationWorld.x, translationWorld.y, translationWorld.z)
		let userPosition = simd_float3(camTransform.m41, camTransform.m42, camTransform.m43)
		
		updateTongue(forTarget: userPosition)
	}
	
	private func updateTongue(forTarget target: simd_float3) {
		// When the tongue is in motion, update the relative amount how much it sticks out
		// between 0 (= in the mouth) and 1 (= at the target).
		if mouthAnimationState == .shootingTongue {
			if relativeTongueStickOutFactor < 1 {
				relativeTongueStickOutFactor += 0.08
			} else {
				relativeTongueStickOutFactor = 1
			}
		} else if mouthAnimationState == .pullingBackTongue {
			if relativeTongueStickOutFactor > 0 {
				relativeTongueStickOutFactor -= 0.02
			} else {
				relativeTongueStickOutFactor = 0
			}
		}
		
		// Set the position of the 'focus of the tongue' node, which is used by the tongue's transformation constraint.
		let startPos = tongueRestPositionNode.presentation.simdWorldPosition
		let endPos = target
		let intermediatePos = (endPos - startPos) * relativeTongueStickOutFactor
		
		currentTonguePosition = startPos + intermediatePos
		tongueTip.simdPosition = tongueTip.parent!.presentation.simdConvertPosition(currentTonguePosition, from: nil)
	}
}

// MARK: - Helper functions

extension Chameleon {
	
	private func rad(_ deg: Float) -> Float {
		return deg * Float.pi / 180
	}
	
	private func randomlyUpdate(_ vector: inout simd_float3) {
		switch arc4random() % 400 {
		case 0: vector.x = 0.1
		case 1: vector.x = -0.1
		case 2: vector.y = 0.1
		case 3: vector.y = -0.1
		case 4, 5, 6, 7: vector = simd_float3()
		default: break
		}
	}
	
	private func setupSpecialNodes() {
		// Retrieve nodes we need to reference for animations.
		geometryRoot = self.rootNode.childNode(withName: "Chameleon", recursively: true)
		head = self.rootNode.childNode(withName: "Neck02", recursively: true)
		jaw = self.rootNode.childNode(withName: "Jaw", recursively: true)
		tongueTip = self.rootNode.childNode(withName: "TongueTip_Target", recursively: true)
		leftEye = self.rootNode.childNode(withName: "Eye_L", recursively: true)
		rightEye = self.rootNode.childNode(withName: "Eye_R", recursively: true)
		
		skin = geometryRoot.geometry?.materials.first
		
		// Fix materials
		geometryRoot.geometry?.firstMaterial?.lightingModel = .physicallyBased
		geometryRoot.geometry?.firstMaterial?.roughness.contents = "art.scnassets/textures/chameleon_ROUGHNESS.png"
		let shadowPlane = self.rootNode.childNode(withName: "Shadow", recursively: true)
		shadowPlane?.castsShadow = false
		
		// Set up looking position nodes
		focusOfTheHead.simdPosition = focusNodeBasePosition
		focusOfLeftEye.simdPosition = focusNodeBasePosition
		focusOfRightEye.simdPosition = focusNodeBasePosition
		geometryRoot.addChildNode(focusOfTheHead)
		geometryRoot.addChildNode(focusOfLeftEye)
		geometryRoot.addChildNode(focusOfRightEye)
	}
	
	private func setupConstraints() {
		// Set up constraints for head movement
		let headConstraint = SCNLookAtConstraint(target: focusOfTheHead)
		headConstraint.isGimbalLockEnabled = true
		head?.constraints = [headConstraint]
		
		// Set up constraints for eye movement
		let leftEyeLookAtConstraint = SCNLookAtConstraint(target: focusOfLeftEye)
		leftEyeLookAtConstraint.isGimbalLockEnabled = true
		
		let rightEyeLookAtConstraint = SCNLookAtConstraint(target: focusOfRightEye)
		rightEyeLookAtConstraint.isGimbalLockEnabled = true
		
		let eyeRotationConstraint = SCNTransformConstraint(inWorldSpace: false) { (node, transform) -> SCNMatrix4 in
			var eulerX = node.presentation.eulerAngles.x
			var eulerY = node.presentation.eulerAngles.y
			if eulerX < self.rad(-20) { eulerX = self.rad(-20) }
			if eulerX > self.rad(20) { eulerX = self.rad(20) }
			if node.name == "Eye_R" {
				if eulerY < self.rad(-150) { eulerY = self.rad(-150) }
				if eulerY > self.rad(-5) { eulerY = self.rad(-5) }
			} else {
				if eulerY > self.rad(150) { eulerY = self.rad(150) }
				if eulerY < self.rad(5) { eulerY = self.rad(5) }
			}
			let tempNode = SCNNode()
			tempNode.transform = node.presentation.transform
			tempNode.eulerAngles = SCNVector3(eulerX, eulerY, 0)
			return tempNode.transform
		}
		
		leftEye?.constraints = [leftEyeLookAtConstraint, eyeRotationConstraint]
		rightEye?.constraints = [rightEyeLookAtConstraint, eyeRotationConstraint]
		
		// The tongueRestPositionNode always remains at the tongue rest position,
		// even if the tongue is animated. It helps to calculate the intermediate position in the tongue animation.
		tongueTip.parent!.addChildNode(tongueRestPositionNode)
		tongueRestPositionNode.transform = tongueTip.transform
		currentTonguePosition = tongueTip.simdPosition
	}
	
	private func resetState() {
		relativeTongueStickOutFactor = 0
		
		mouthAnimationState = .mouthClosed
		
		readyToShootCounter = 0
		triggerTurnLeftCounter = 0
		triggerTurnRightCounter = 0
		
		if changeColorTimer != nil {
			changeColorTimer?.invalidate()
			changeColorTimer = nil
		}
	}
	
	private func setupShader() {
		guard let path = Bundle.main.path(forResource: "skin", ofType: "shaderModifier", inDirectory: "art.scnassets"),
			let shader = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) else {
			return
		}
		
		skin.shaderModifiers = [SCNShaderModifierEntryPoint.surface: shader]

		skin.setValue(Double(0), forKey: "blendFactor")
		skin.setValue(NSValue(scnVector3: SCNVector3Zero), forKey: "skinColorFromEnvironment")
		
		let sparseTexture = SCNMaterialProperty(contents: UIImage(named: "art.scnassets/textures/chameleon_DIFFUSE_BASE.png")!)
		skin.setValue(sparseTexture, forKey: "sparseTexture")
	}
}
