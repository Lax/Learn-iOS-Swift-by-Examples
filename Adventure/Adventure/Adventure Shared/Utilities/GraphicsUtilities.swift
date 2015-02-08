/*
  Copyright (C) 2015 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  Defines basic graphics utilities used throughout Adventure
*/

import SpriteKit

func loadFramesFromAtlasWithName(atlasName: String) -> [SKTexture] {
    let atlas = SKTextureAtlas(named: atlasName)
    return sorted(atlas.textureNames as [String]).map { atlas.textureNamed($0) }
}

func unitRandom() -> CGFloat {
    let quotient = Double(arc4random()) / Double(UInt32.max)
    return CGFloat(quotient)
}

// The assets are all facing Y down, so offset by half pi to get into X right facing
func adjustAssetOrientation(r: CGFloat) -> CGFloat {
    return r + (CGFloat(M_PI) * 0.5)
}

extension CGPoint {
    func distanceToPoint(point: CGPoint) -> CGFloat {
        return hypot(x - point.x, y - point.y)
    }

    func radiansToPoint(point: CGPoint) -> CGFloat {
        var deltaX = point.x - x
        var deltaY = point.y - y

        return atan2(deltaY, deltaX)
    }
}

// Adds the coordinates of the two points together.
func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func runOneShotEmitter(emitter: SKEmitterNode, withDuration duration: CGFloat) {
    let waitAction = SKAction.waitForDuration(NSTimeInterval(duration))
    let birthRateSet = SKAction.runBlock { emitter.particleBirthRate = 0.0 }
    let waitAction2 = SKAction.waitForDuration(NSTimeInterval(emitter.particleLifetime + emitter.particleLifetimeRange))
    let removeAction = SKAction.removeFromParent()

    var sequence = [ waitAction, birthRateSet, waitAction2, removeAction]
    emitter.runAction(SKAction.sequence(sequence))
}
