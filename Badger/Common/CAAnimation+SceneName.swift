/*
     Copyright (C) 2016 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     An extension on CAAnimation used to load animations from an SCNScene.
 */

import SceneKit

// MARK: Core Animation

extension CAAnimation {
    class func animation(withSceneName name: String) -> CAAnimation {
        guard let scene = SCNScene(named: name) else {
            fatalError("Failed to find scene with name \(name).")
        }
        
        var animation: CAAnimation?
        scene.rootNode.enumerateChildNodes { (child, stop) in
            guard let firstKey = child.animationKeys.first else { return }
            animation = child.animation(forKey: firstKey)
            stop.initialize(to: true)
        }
        
        guard let foundAnimation = animation else {
            fatalError("Failed to find animation named \(name).")
        }
        
        foundAnimation.fadeInDuration = 0.3
        foundAnimation.fadeOutDuration = 0.3
        foundAnimation.repeatCount = 1
        
        return foundAnimation
    }
}
