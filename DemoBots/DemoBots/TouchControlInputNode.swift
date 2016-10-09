/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An implementation of the `ControlInputSourceType` protocol that enables support for touch-based thumbsticks on iOS.
*/

import SpriteKit

class TouchControlInputNode: SKSpriteNode, ThumbStickNodeDelegate, ControlInputSourceType {
    // MARK: Properties
    
    /// `ControlInputSourceType` delegates.
    weak var delegate: ControlInputSourceDelegate?
    weak var gameStateDelegate: ControlInputSourceGameStateDelegate?
    
    let allowsStrafing = true
    
    /// Analog thumb stick controls for the left and right half of the screen.
    let leftThumbStickNode: ThumbStickNode
    let rightThumbStickNode: ThumbStickNode
    
    /// Node representing the touch area for the pause button.
    let pauseButton: SKSpriteNode
    
    /// Sets used to keep track of touches, and their relevant controls.
    var leftControlTouches = Set<UITouch>()
    var rightControlTouches = Set<UITouch>()
    
    /// The width of the zone in the center of the screen where the touch controls cannot be placed.
    let centerDividerWidth: CGFloat
    var hideThumbStickNodes: Bool = false {
        didSet {
            leftThumbStickNode.isHidden = hideThumbStickNodes
            rightThumbStickNode.isHidden = hideThumbStickNodes
        }
    }
    
    // MARK: Initialization
    
    /*
        `TouchControlInputNode` is intended as an overlay for the entire screen,
        therefore the `frame` is usually the scene's bounds or something equivalent.
    */
    init(frame: CGRect, thumbStickNodeSize: CGSize) {
        // An approximate width appropriate for different scene sizes.
        centerDividerWidth = frame.width / 4.5
        
        // Setup the thumbStickNodes.
        let initialVerticalOffset = -thumbStickNodeSize.height
        let initialHorizontalOffset = frame.width / 2 - thumbStickNodeSize.width
        
        leftThumbStickNode = ThumbStickNode(size: thumbStickNodeSize)
        leftThumbStickNode.position = CGPoint(x: -initialHorizontalOffset, y: initialVerticalOffset)
        
        rightThumbStickNode = ThumbStickNode(size: thumbStickNodeSize)
        rightThumbStickNode.position = CGPoint(x: initialHorizontalOffset, y: initialVerticalOffset)
        
        // Setup pause button.
        let buttonSize = CGSize(width: frame.height / 4, height: frame.height / 4)
        pauseButton = SKSpriteNode(texture: nil, color: UIColor.clear, size: buttonSize)
        pauseButton.position = CGPoint(x: 0, y: frame.height / 2)
        
        super.init(texture: nil, color: UIColor.clear, size: frame.size)
        rightThumbStickNode.delegate = self
        leftThumbStickNode.delegate = self
        
        addChild(leftThumbStickNode)
        addChild(rightThumbStickNode)
        addChild(pauseButton)
        
        /*
            A `TouchControlInputNode` is designed to receive all user interaction
            and forwards it along to the child nodes.
        */
        isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: ThumbStickNodeDelegate
    
    func thumbStickNode(thumbStickNode: ThumbStickNode, didUpdateXValue xValue: Float, yValue: Float) {
        // Determine which control this update is relevant to by comparing it to the references.
        if thumbStickNode === leftThumbStickNode {
            let displacement = float2(x: xValue, y: yValue)
            delegate?.controlInputSource(self, didUpdateDisplacement: displacement)
        }
        else if thumbStickNode === rightThumbStickNode {
            let displacement = float2(x: xValue, y: yValue)
            
            // Rotate the character only if the `thumbStickNode` is sufficiently displaced.
            if length(displacement) >= GameplayConfiguration.TouchControl.minimumRequiredThumbstickDisplacement {
                delegate?.controlInputSource(self, didUpdateAngularDisplacement: displacement)
            }
            else {
                delegate?.controlInputSource(self, didUpdateAngularDisplacement: float2())
            }
        }
    }
    
    func thumbStickNode(thumbStickNode: ThumbStickNode, isPressed: Bool) {
        if thumbStickNode === rightThumbStickNode {
            if isPressed {
                delegate?.controlInputSourceDidBeginAttacking(self)
            }
            else {
                delegate?.controlInputSourceDidFinishAttacking(self)
            }
        }
    }
    
    // MARK: ControlInputSourceType
    
    func resetControlState() {
        // Nothing to do here.
    }
    
    // MARK: UIResponder
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        for touch in touches {
            let touchPoint = touch.location(in: self)
            
            /*
                Ignore touches if the thumb stick controls are hidden, or if
                the touch is in the center of the screen.
            */
            let touchIsInCenter = touchPoint.x < centerDividerWidth / 2 && touchPoint.x > -centerDividerWidth / 2
            if hideThumbStickNodes || touchIsInCenter {
                    continue
            }
            
            if touchPoint.x < 0 {
                leftControlTouches.formUnion([touch])
                leftThumbStickNode.position = pointByCheckingControlOffset(suggestedPoint: touchPoint)
                leftThumbStickNode.touchesBegan([touch], with: event)
            }
            else {
                rightControlTouches.formUnion([touch])
                rightThumbStickNode.position = pointByCheckingControlOffset(suggestedPoint: touchPoint)
                rightThumbStickNode.touchesBegan([touch], with: event)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        /*
            If the touch pertains to a `thumbStickNode`, pass the
            touch along to be handled.
            
            Holding onto individual touches allows the user to drag
            a touch that initially started on the `leftThumbStickNode`
            over the the `rightThumbStickNode`s zone or vice versa,
            while ensuring it is handled by the correct thumb stick.
        */
        let movedLeftTouches = touches.intersection(leftControlTouches)
        leftThumbStickNode.touchesMoved(movedLeftTouches, with: event)
        
        let movedRightTouches = touches.intersection(rightControlTouches)
        rightThumbStickNode.touchesMoved(movedRightTouches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        for touch in touches {
            let touchPoint = touch.location(in: self)
            
            /// Toggle pause when touching in the pause node.
            if pauseButton === atPoint(touchPoint) {
                gameStateDelegate?.controlInputSourceDidTogglePauseState(self)
                break
            }
        }
        
        let endedLeftTouches = touches.intersection(leftControlTouches)
        leftThumbStickNode.touchesEnded(endedLeftTouches, with: event)
        leftControlTouches.subtract(endedLeftTouches)
        
        let endedRightTouches = touches.intersection(rightControlTouches)
        rightThumbStickNode.touchesEnded(endedRightTouches, with: event)
        rightControlTouches.subtract(endedRightTouches)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        super.touchesCancelled(touches!, with: event)

        leftThumbStickNode.resetTouchPad()
        rightThumbStickNode.resetTouchPad()
        
        // Keep the set's capacity, because roughly the same number of touch events are being received.
        leftControlTouches.removeAll(keepingCapacity: true)
        rightControlTouches.removeAll(keepingCapacity: true)
    }
    
    // MARK: Convenience Methods
    
    /// Calculates a point that keeps the `thumbStickNode` completely on screen.
    func pointByCheckingControlOffset(suggestedPoint: CGPoint) -> CGPoint {
        // `leftThumbStickNode` is an arbitrary choice - both are the same size.
        let controlSize = leftThumbStickNode.size
        let sceneSize = scene!.size
        
        /*
            The origin of `SKNode`'s coordinate system is at the center of the screen.
            Points to the left and below the origin are negative;
            points above and to the right are positive.
            
            Offset by 2/3 times the size of the control to maintain some padding
            around the edge of the view.
        */
        let minX = -sceneSize.width / 2 + controlSize.width / 1.5
        let maxX = sceneSize.width / 2 - controlSize.width / 1.5
        
        let minY = -sceneSize.height / 2 + controlSize.height / 1.5
        let maxY = sceneSize.height / 2 - controlSize.height / 1.5
        
        let boundX = max(min(suggestedPoint.x, maxX), minX)
        let boundY = max(min(suggestedPoint.y, maxY), minY)
        
        return CGPoint(x: boundX, y: boundY)
    }
    
}
