/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Exposes D-Pad game controller type functionality with screen-rendered buttons.
 */

import SpriteKit
import simd

protocol PadOverlayDelegate: NSObjectProtocol {
    func padOverlayVirtualStickInteractionDidStart(_ padNode: PadOverlay)
    func padOverlayVirtualStickInteractionDidChange(_ padNode: PadOverlay)
    func padOverlayVirtualStickInteractionDidEnd(_ padNode: PadOverlay)
}

class PadOverlay: SKNode {
    // Default 100, 100
    
    var size = CGSize.zero {
        didSet {
            if size != oldValue {
                updateForSizeChange()
            }
        }
    }
    // Range [-1, 1]
    var stickPosition = CGPoint.zero {
        didSet {
            if stickPosition != oldValue {
                updateStickPosition()
            }
        }
    }
    weak var delegate: PadOverlayDelegate?

    private var trackingTouch: UITouch?
    private var startLocation = CGPoint.zero
    private var stick: SKShapeNode!
    private var background: SKShapeNode!

    override init() {
        super.init()
        size = CGSize(width: CGFloat(150), height: CGFloat(150))
        alpha = 0.7
        isUserInteractionEnabled = true
        buildPad()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func buildPad() {
        let backgroundRect = CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(size.width), height: CGFloat(size.height))
        background = SKShapeNode()
        background.path = CGPath( ellipseIn: backgroundRect, transform: nil )
        background.strokeColor = SKColor.black
        background.lineWidth = 3.0
        addChild(background)
        var stickRect = CGRect.zero
        stickRect.size = stickSize
        stick = SKShapeNode()
        stick.path = CGPath( ellipseIn: stickRect, transform: nil)
        stick.lineWidth = 2.0
        //#if os( OSX )
        stick.fillColor = SKColor.white
        //#endif
        stick.strokeColor = SKColor.black
        addChild(stick)
        updateStickPosition()
    }
    
    var stickSize: CGSize {
        return CGSize( width: size.width / 3.0, height: size.height / 3.0)
    }

    func updateForSizeChange() {
        guard let background = background else { return }

        let backgroundRect = CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(size.width), height: CGFloat(size.height))
        background.path = CGPath( ellipseIn: backgroundRect, transform: nil)
        let stickRect = CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(size.width / 3.0), height: CGFloat(size.height / 3.0))
        stick.path = CGPath( ellipseIn: stickRect, transform: nil)
    }

    func updateStickPosition() {
        let stickSize: CGSize = self.stickSize
        let stickX = size.width / 2.0 - stickSize.width / 2.0 + size.width / 2.0 * stickPosition.x
        let stickY = size.height / 2.0 - stickSize.height / 2.0 + size.width / 2.0 * stickPosition.y
        stick.position = CGPoint(x: stickX, y: stickY)
    }

    func updateStickPosition(forTouchLocation location: CGPoint) {
        var l_vec = vector_float2( x: Float( location.x - startLocation.x ), y: Float( location.y - startLocation.y ) )
        l_vec.x = (l_vec.x / Float( size.width ) - 0.5) * 2.0
        l_vec.y = (l_vec.y / Float( size.height ) - 0.5) * 2.0
        if simd_length_squared(l_vec) > 1 {
            l_vec = simd_normalize(l_vec)
        }
        stickPosition = CGPoint( x: CGFloat( l_vec.x ), y: CGFloat( l_vec.y ) )
    }

    func resetInteraction() {
        stickPosition = CGPoint.zero
        trackingTouch = nil
        startLocation = CGPoint.zero
        delegate!.padOverlayVirtualStickInteractionDidEnd(self)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        trackingTouch = touches.first
        startLocation = trackingTouch!.location(in: self)
        // Center start location
        startLocation.x -= size.width / 2.0
        startLocation.y -= size.height / 2.0
        updateStickPosition(forTouchLocation: trackingTouch!.location(in: self))
        delegate!.padOverlayVirtualStickInteractionDidStart(self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.contains(trackingTouch!) {
            updateStickPosition(forTouchLocation: trackingTouch!.location(in: self))
            delegate!.padOverlayVirtualStickInteractionDidChange(self)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.contains(trackingTouch!) {
            resetInteraction()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.contains(trackingTouch!) {
            resetInteraction()
        }
    }
}
