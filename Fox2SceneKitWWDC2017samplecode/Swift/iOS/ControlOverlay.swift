/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Exposes game controller action button type functionality with screen-rendered buttons.
 */

import SpriteKit

class ControlOverlay: SKNode {
    
    let buttonMargin = CGFloat( 25 )
    
    var leftPad = PadOverlay()
    var rightPad = PadOverlay()
    var buttonA = ButtonOverlay("A")
    var buttonB = ButtonOverlay("B")

    init(frame: CGRect) {
        super.init()

        leftPad.position = CGPoint(x: CGFloat(20), y: CGFloat(40))
        addChild(leftPad)
        
        rightPad.position = CGPoint(x: CGFloat(frame.size.width - 20 - rightPad.size.width), y: CGFloat(40))
        addChild(rightPad)
        
        let buttonDistance = rightPad.size.height / CGFloat( 2 ) + buttonMargin + buttonA.size.height / CGFloat( 2 )
        let center = CGPoint( x: rightPad.position.x + rightPad.size.width / 2.0, y: rightPad.position.y + rightPad.size.height / 2.0 )
        
        let buttonAx = center.x - buttonDistance * CGFloat(cosf(Float.pi / 4.0)) - (buttonB.size.width / 2)
        let buttonAy = center.y + buttonDistance * CGFloat(sinf(Float.pi / 4.0)) - (buttonB.size.height / 2)
        buttonA.position = CGPoint(x: buttonAx, y: buttonAy)
        addChild(buttonA)
        
        let buttonBx = center.x - buttonDistance * CGFloat(cosf(Float.pi / 2.0)) - (buttonB.size.width / 2)
        let buttonBy = center.y + buttonDistance * CGFloat(sinf(Float.pi / 2.0)) - (buttonB.size.height / 2)
        buttonB.position = CGPoint(x: buttonBx, y: buttonBy)
        addChild(buttonB)
    }

    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
