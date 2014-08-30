/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines basic graphics utilities used throughout Adventure
      
*/

import SpriteKit

func createCGImageFromFile(path: String) -> CGImage {
#if os(iOS)
    let image = UIImage(contentsOfFile: path)
        
    return CGImageRetain(image.CGImage)
#else
    let nsimage = NSImage(contentsOfFile: path)
    let destRect = NSZeroRect
    
    return nsimage.CGImageForProposedRect(nil, context: nil, hints: nil).takeUnretainedValue()
#endif
}

func getCGImageNamed(name: String) -> CGImage {
#if os(iOS)
    let actualName = name.lastPathComponent
    let image = UIImage(named: actualName)
    return image.CGImage
#else
    var path: String
    
    if name.hasPrefix("/") {
        path = name
    } else {
        let directory = name.stringByDeletingLastPathComponent
        var newName = name.lastPathComponent
        let fileExtension = newName.pathExtension
        newName = newName.stringByDeletingPathExtension
        path = NSBundle.mainBundle().pathForResource(newName, ofType: fileExtension, inDirectory: directory)
    }
    return createCGImageFromFile(path)
#endif
}

extension SKEmitterNode {
    class func emitterNodeWithName(name: String) -> SKEmitterNode {
        return NSKeyedUnarchiver.unarchiveObjectWithFile(NSBundle.mainBundle().pathForResource(name, ofType: "sks")) as SKEmitterNode
    }
}

func unitRandom() -> CGFloat {
    return CGFloat(arc4random()) / (0x100000000 as CGFloat)
}

func createARGBBitmapContext(inImage: CGImage) -> CGContext {
    var bitmapByteCount = 0
    var bitmapBytesPerRow = 0

    let pixelsWide = CGImageGetWidth(inImage)
    let pixelsHigh = CGImageGetHeight(inImage)

    bitmapBytesPerRow = Int(pixelsWide) * 4
    bitmapByteCount = bitmapBytesPerRow * Int(pixelsHigh)

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapData = malloc(CUnsignedLong(bitmapByteCount))
    let bitmapInfo = CGBitmapInfo.fromRaw(CGImageAlphaInfo.PremultipliedFirst.toRaw())!

    let context = CGBitmapContextCreate(bitmapData, pixelsWide, pixelsHigh, CUnsignedLong(8), CUnsignedLong(bitmapBytesPerRow), colorSpace, bitmapInfo)

    return context
}

func createDataMap(mapName: String) -> COpaquePointer {
    let inImage = getCGImageNamed(mapName)
    let cgContext = createARGBBitmapContext(inImage)

    let width = CGImageGetWidth(inImage)
    let height = CGImageGetHeight(inImage)

    var rect = CGRectZero
    rect.size.width = CGFloat(width)
    rect.size.height = CGFloat(height)

    CGContextDrawImage(cgContext, rect, inImage)

    return CGBitmapContextGetData(cgContext)
}

// The assets are all facing Y down, so offset by half pi to get into X right facing
func adjustAssetOrientation(r: CGFloat) -> CGFloat {
    return r + (CGFloat(M_PI) * 0.5)
}

extension CGPoint : Equatable {
    func distanceTo(p : CGPoint) -> CGFloat {
        return hypot(self.x - p.x, self.y - p.y)
    }

    func radiansToPoint(p: CGPoint) -> CGFloat {
        var deltaX = p.x - self.x
        var deltaY = p.y - self.y

        return atan2(deltaY, deltaX)
    }

    func pointByAdding(point: CGPoint) -> CGPoint {
        return CGPoint(x: self.x + point.x, y: self.y + point.y)
    }
}

func ==(point1: CGPoint, point2: CGPoint) -> Bool {
    return CGPointEqualToPoint(point1, point2)
}

func runOneShotEmitter(emitter: SKEmitterNode, withDuration duration: CGFloat) {
    let waitAction = SKAction.waitForDuration(NSTimeInterval(duration))
    let birthRateSet = SKAction.runBlock { emitter.particleBirthRate = 0.0 }
    let waitAction2 = SKAction.waitForDuration(NSTimeInterval(emitter.particleLifetime + emitter.particleLifetimeRange))
    let removeAction = SKAction.removeFromParent()

    var sequence = [ waitAction, birthRateSet, waitAction2, removeAction]
    emitter.runAction(SKAction.sequence(sequence))
}

#if arch(arm) || arch(i386)
func sin(x: CGFloat) -> CGFloat {
    return sinf(x)
}

func cos(x: CGFloat) -> CGFloat {
    return cosf(x)
}
func hypot(x: CGFloat, y: CGFloat) -> CGFloat {
    return hypotf(x, y)
}

func atan2(x: CGFloat, y: CGFloat) -> CGFloat {
    return atan2f(x, y)
}
#endif

