/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A class to manage the display of an overlay set of nodes on top of an existing scene.
*/

import SpriteKit

class SceneOverlay {
    // MARK: Properties
    
    let backgroundNode: SKSpriteNode
    
    let contentNode: SKSpriteNode
    
    let nativeContentSize: CGSize
    
    // MARK: Intialization
    
    init(overlaySceneFileName fileName: String, zPosition: CGFloat) {
        // Load the scene and get the overlay node from it.
        let overlayScene = SKScene(fileNamed: fileName)!
        let contentTemplateNode = overlayScene.childNode(withName: "Overlay") as! SKSpriteNode
        
        // Create a background node with the same color as the template.
        backgroundNode = SKSpriteNode(color: contentTemplateNode.color, size: contentTemplateNode.size)
        backgroundNode.zPosition = zPosition
        
        // Copy the template node into the background node.
        contentNode = contentTemplateNode.copy() as! SKSpriteNode
        contentNode.position = .zero
        backgroundNode.addChild(contentNode)
        
        // Set the content node to a clear color to allow the background node to be seen through it.
        contentNode.color = .clear
        
        // Store the current size of the content to allow it to be scaled correctly.
        nativeContentSize = contentNode.size
    }
    
    func updateScale() {
        guard let viewSize = backgroundNode.scene?.view?.frame.size else {
            return
        }

        // Resize the background node.
        backgroundNode.size = viewSize
        
        // Scale the content so that the height always fits.
        let scale = viewSize.height / nativeContentSize.height
        contentNode.setScale(scale)
    }
}
