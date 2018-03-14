/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class represents the player.
 */

import GameplayKit

class PlayerComponent: BaseComponent {
    public var character: Character!

    override func update(deltaTime seconds: TimeInterval) {
        positionAgentFromNode()
        super.update(deltaTime: seconds)
    }
}
