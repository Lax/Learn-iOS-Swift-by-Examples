/*
     Copyright (C) 2016 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     An SCNView used to relay keyboard controls on OSX, and present
                 setup the 2D overlay.
 */

import GameKit

class View: SCNView {

    // MARK: Mouse and Keyboard Events
    
    #if os(OSX)
    var eventsDelegate: KeyboardEventsDelegate?
    
    override func keyDown(with event: NSEvent) {
        guard let eventsDelegate = eventsDelegate, eventsDelegate.keyDown(in: self, with: event) else {
            super.keyDown(with: event)
            return
        }
    }
    
    override func keyUp(with event: NSEvent) {
        guard let eventsDelegate = eventsDelegate, eventsDelegate.keyUp(in: self, with: event) else {
            super.keyUp(with: event)
            return
        }
    }
    #endif
    
    // Resizing
    
    #if os(iOS) || os(tvOS)
    override func layoutSubviews() {
        super.layoutSubviews()
        update2DOverlays()
    }
    #elseif os(OSX)
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        update2DOverlays()
    }
    #endif

    // MARK: Overlays
    
    private let _overlayNode = SKNode()
    private let _scaleNode = SKNode()
    private let _collectedItemsCountLabel = SKLabelNode(fontNamed: "Superclarendon")
    
    private func update2DOverlays() {
        _overlayNode.position = CGPoint(x: 0.0, y: bounds.size.height)
    }
    
    func setup2DOverlay() {
        let w = bounds.size.width
        let h = bounds.size.height
        
        // Setup the game overlays using SpriteKit.
        let skScene = SKScene(size: CGSize(width: w, height: h))
        skScene.scaleMode = .resizeFill
        
        skScene.addChild(_scaleNode)
        _scaleNode.addChild(_overlayNode)
        _overlayNode.position = CGPoint(x: 0.0, y: h)
        
        #if os(OSX)
        _scaleNode.xScale = layer!.contentsScale
        _scaleNode.yScale = layer!.contentsScale
        #endif

        // The Bob icon.
        let bobSprite = SKSpriteNode(imageNamed: "BobHUD.png")
        bobSprite.position = CGPoint(x: 70, y:-50)
        bobSprite.xScale = 0.5
        bobSprite.yScale = 0.5
        _overlayNode.addChild(bobSprite)
        
        _collectedItemsCountLabel.text = "x0"
        _collectedItemsCountLabel.horizontalAlignmentMode = .left
        _collectedItemsCountLabel.position = CGPoint(x: 135, y:-63)
        _overlayNode.addChild(_collectedItemsCountLabel)
        
        // Assign the SpriteKit overlay to the SceneKit view.
        self.overlaySKScene = skScene
        skScene.isUserInteractionEnabled = false
    }
    
    var collectedItemsCount = 0 {
        didSet {
            _collectedItemsCountLabel.text = "x\(collectedItemsCount)"
        }
    }
    
    func didCollectItem() {
        collectedItemsCount = collectedItemsCount + 1
    }
    
    func didCollectBigItem() {
        collectedItemsCount = collectedItemsCount + 10
    }
    
}
