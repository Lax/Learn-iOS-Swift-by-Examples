/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An iOS-specific `SKSpriteNode` subclass used to provide the on-screen thumbsticks that enable player control.
*/

import SpriteKit

/// Relay control events though `ThumbStickNodeDelegate`.
protocol ThumbStickNodeDelegate: class {
    /// Called when `touchPad` is moved. Values are normalized between [-1.0, 1.0].
    func thumbStickNode(thumbStickNode: ThumbStickNode, didUpdateXValue xValue: Float, yValue: Float)
    
    /// Called to indicate when the `touchPad` is initially pressed, and when it is released.
    func thumbStickNode(thumbStickNode: ThumbStickNode, isPressed: Bool)
}

/// Touch representation of a classic analog stick.
class ThumbStickNode: SKSpriteNode {
    // MARK: Properties 
    
    /// The actual thumb pad that moves with touch.
    var touchPad: SKSpriteNode
    
    weak var delegate: ThumbStickNodeDelegate?
    
    /// The center point of this `ThumbStickNode`.
    let center: CGPoint
    
    /// The distance that `touchPad` can move from the `touchPadAnchorPoint`.
    let trackingDistance: CGFloat
    
    /// Styling settings for the thumbstick's nodes.
    let normalAlpha: CGFloat = 0.3
    let selectedAlpha: CGFloat = 0.5
    
    override var alpha: CGFloat {
        didSet {
            touchPad.alpha = alpha
        }
    }
    
    // MARK: Initialization
    
    init(size: CGSize) {
        trackingDistance = size.width / 2
        
        let touchPadLength = size.width / 2.2
        center = CGPoint(x: size.width / 2 - touchPadLength, y: size.height / 2 - touchPadLength)
        
        let touchPadSize = CGSize(width: touchPadLength, height: touchPadLength)
        let touchPadTexture = SKTexture(imageNamed: "ControlPad")
        
        // `touchPad` is the inner touch pad that follows the user's thumb.
        touchPad = SKSpriteNode(texture: touchPadTexture, color: UIColor.clearColor(), size: touchPadSize)
        
        super.init(texture: touchPadTexture, color: UIColor.clearColor(), size: size)

        alpha = normalAlpha
        
        addChild(touchPad)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UIResponder
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        // Highlight that the control is being used by adjusting the alpha.
        alpha = selectedAlpha
        
        // Inform the delegate that the control is being pressed.
        delegate?.thumbStickNode(self, isPressed: true)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        
        // For each touch, calculate the movement of the touchPad.
        for touch in touches {
            let touchLocation = touch.locationInNode(self)
            
            var dx = touchLocation.x - center.x
            var dy = touchLocation.y - center.y
            
            // Calculate the distance from the `touchPadAnchorPoint` to the current location.
            let distance = hypot(dx, dy)
            
            /*
                If the distance is greater than our allowed `trackingDistance`,
                create a unit vector and multiply by max displacement
                (`trackingDistance`).
            */
            if distance > trackingDistance {
                dx = (dx / distance) * trackingDistance
                dy = (dy / distance) * trackingDistance
            }
            
            // Position the touchPad to match the touch's movement.
            touchPad.position = CGPoint(x: center.x + dx, y: center.y + dy)
            
            // Normalize the displacements between [-1.0, 1.0].
            let normalizedDx = Float(dx / trackingDistance)
            let normalizedDy = Float(dy / trackingDistance)
            delegate?.thumbStickNode(self, didUpdateXValue: normalizedDx, yValue: normalizedDy)
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        
        // If the touches set is empty, return immediately.
        guard !touches.isEmpty else { return }
        
        resetTouchPad()
   }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        resetTouchPad()
    }
    
    /// When touches end, reset the `touchPad` to the center of the control.
    func resetTouchPad() {
        alpha = normalAlpha
        
        let restoreToCenter = SKAction.moveTo(CGPoint.zero, duration: 0.2)
        touchPad.runAction(restoreToCenter)
        
        delegate?.thumbStickNode(self, isPressed: false)
        delegate?.thumbStickNode(self, didUpdateXValue: 0, yValue: 0)
    }
}
