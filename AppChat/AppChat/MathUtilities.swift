/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Various math utilities used throughout the app.
 */

import CoreGraphics

func clamp<T: Comparable>(value: T, minimum: T, maximum: T) -> T {
    return min(max(value, minimum), maximum)
}

func rotate(vector: CGVector, by radians: Double) -> CGVector {
    let dx = (vector.dx * CGFloat(cos(radians))) - (vector.dy * CGFloat(sin(radians)))
    let dy = (vector.dy * CGFloat(cos(radians))) + (vector.dx * CGFloat(sin(radians)))
    return CGVector(dx: dx, dy: dy)
}
