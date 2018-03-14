/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class manages the 2D overlay (score).
*/

import Foundation
import SceneKit
import SpriteKit

class Overlay: SKScene {
    private var overlayNode: SKNode
    private var congratulationsGroupNode: SKNode?
    private var collectedKeySprite: SKSpriteNode!
    private var collectedGemsSprites = [SKSpriteNode]()
    
    // demo UI
    private var demoMenu: Menu?
    
#if os( iOS )
    public var controlOverlay: ControlOverlay?
#endif

// MARK: - Initialization
    init(size: CGSize, controller: GameController) {
        overlayNode = SKNode()
        super.init(size: size)
        
        let w: CGFloat = size.width
        let h: CGFloat = size.height
        
        collectedGemsSprites = []
        
        // Setup the game overlays using SpriteKit.
        scaleMode = .resizeFill
        
        addChild(overlayNode)
        overlayNode.position = CGPoint(x: 0.0, y: h)
        
        // The Max icon.
        let characterNode = SKSpriteNode(imageNamed: "MaxIcon.png")
        let menuButton = Button(skNode: characterNode)
        menuButton.position = CGPoint(x: 50, y: -50)
        menuButton.xScale = 0.5
        menuButton.yScale = 0.5
        overlayNode.addChild(menuButton)
        menuButton.setClickedTarget(self, action: #selector(self.toggleMenu))
        
        // The Gems
        for i in 0..<1 {
            let gemNode = SKSpriteNode(imageNamed: "collectableBIG_empty.png")
            gemNode.position = CGPoint(x: 125 + i * 80, y: -50)
            gemNode.xScale = 0.25
            gemNode.yScale = 0.25
            overlayNode.addChild(gemNode)
            collectedGemsSprites.append(gemNode)
        }
        
        // The key
        collectedKeySprite = SKSpriteNode(imageNamed: "key_empty.png")
        collectedKeySprite.position = CGPoint(x: CGFloat(195), y: CGFloat(-50))
        collectedKeySprite.xScale = 0.4
        collectedKeySprite.yScale = 0.4
        overlayNode.addChild(collectedKeySprite)
        
        // The virtual D-pad
        #if os( iOS )
            controlOverlay = ControlOverlay(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: w, height: h))
            controlOverlay!.leftPad.delegate = controller
            controlOverlay!.rightPad.delegate = controller
            controlOverlay!.buttonA.delegate = controller
            controlOverlay!.buttonB.delegate = controller
            addChild(controlOverlay!)
        #endif
        // the demo UI
        demoMenu = Menu(size: size)
        demoMenu!.delegate = controller
        demoMenu!.isHidden = true
        overlayNode.addChild(demoMenu!)
        
        // Assign the SpriteKit overlay to the SceneKit view.
        isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func layout2DOverlay() {
        overlayNode.position = CGPoint(x: 0.0, y: size.height)

        guard let congratulationsGroupNode = self.congratulationsGroupNode else { return }
        
        congratulationsGroupNode.position = CGPoint(x: CGFloat(size.width * 0.5), y: CGFloat(size.height * 0.5))
        congratulationsGroupNode.xScale = 1.0
        congratulationsGroupNode.yScale = 1.0
        let currentBbox: CGRect = congratulationsGroupNode.calculateAccumulatedFrame()
        
        let margin: CGFloat = 25.0
        let bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let maximumAllowedBbox: CGRect = bounds.insetBy(dx: margin, dy: margin)
        
        let top: CGFloat = currentBbox.maxY - congratulationsGroupNode.position.y
        let bottom: CGFloat = congratulationsGroupNode.position.y - currentBbox.minY
        let maxTopAllowed: CGFloat = maximumAllowedBbox.maxY - congratulationsGroupNode.position.y
        let maxBottomAllowed: CGFloat = congratulationsGroupNode.position.y - maximumAllowedBbox.minY
        
        let `left`: CGFloat = congratulationsGroupNode.position.x - currentBbox.minX
        let `right`: CGFloat = currentBbox.maxX - congratulationsGroupNode.position.x
        let maxLeftAllowed: CGFloat = congratulationsGroupNode.position.x - maximumAllowedBbox.minX
        let maxRightAllowed: CGFloat = maximumAllowedBbox.maxX - congratulationsGroupNode.position.x
        
        let topScale: CGFloat = top > maxTopAllowed ? maxTopAllowed / top: 1
        let bottomScale: CGFloat = bottom > maxBottomAllowed ? maxBottomAllowed / bottom: 1
        let leftScale: CGFloat = `left` > maxLeftAllowed ? maxLeftAllowed / `left`: 1
        let rightScale: CGFloat = `right` > maxRightAllowed ? maxRightAllowed / `right`: 1
        
        let scale: CGFloat = min(topScale, min(bottomScale, min(leftScale, rightScale)))
        
        congratulationsGroupNode.xScale = scale
        congratulationsGroupNode.yScale = scale
    }
    
    var collectedGemsCount: Int = 0 {
        didSet {
            collectedGemsSprites[collectedGemsCount - 1].texture = SKTexture(imageNamed:"collectableBIG_full.png")
            
            collectedGemsSprites[collectedGemsCount - 1].run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.scale(by: 1.5, duration: 0.2),
                SKAction.scale(by: 1 / 1.5, duration: 0.2)
                ]))
        }
    }
    
    func didCollectKey() {
        collectedKeySprite.texture = SKTexture(imageNamed:"key_full.png")
        collectedKeySprite.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.scale(by: 1.5, duration: 0.2),
            SKAction.scale(by: 1 / 1.5, duration: 0.2)
            ]))
    }
    
    #if os( iOS )
    func showVirtualPad() {
        controlOverlay!.isHidden = false
    }
    
    func hideVirtualPad() {
        controlOverlay!.isHidden = true
    }
    #endif
    
    // MARK: Congratulate the player
    
    func showEndScreen() {
        // Congratulation title
        let congratulationsNode = SKSpriteNode(imageNamed: "congratulations.png")
        
        // Max image
        let characterNode = SKSpriteNode(imageNamed: "congratulations_pandaMax.png")
        characterNode.position = CGPoint(x: CGFloat(0.0), y: CGFloat(-220.0))
        characterNode.anchorPoint = CGPoint(x: CGFloat(0.5), y: CGFloat(0.0))
        
        congratulationsGroupNode = SKNode()
        congratulationsGroupNode!.addChild(characterNode)
        congratulationsGroupNode!.addChild(congratulationsNode)
        addChild(congratulationsGroupNode!)
        
        // Layout the overlay
        layout2DOverlay()
        
        // Animate
        congratulationsNode.alpha = 0.0
        congratulationsNode.xScale = 0.0
        congratulationsNode.yScale = 0.0
        congratulationsNode.run( SKAction.group([SKAction.fadeIn(withDuration: 0.25),
                                 SKAction.sequence([SKAction.scale(to: 1.22, duration: 0.25),
                                SKAction.scale(to: 1.0, duration: 0.1)])]))
        
        characterNode.alpha = 0.0
        characterNode.xScale = 0.0
        characterNode.yScale = 0.0
        characterNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                         SKAction.group([SKAction.fadeIn(withDuration: 0.5),
                         SKAction.sequence([SKAction.scale(to: 1.22, duration: 0.25),
                        SKAction.scale(to: 1.0, duration: 0.1)])])]))
    }
    
    @objc
    func toggleMenu(_ sender: Button) {
        demoMenu!.isHidden = !demoMenu!.isHidden
    }
}

