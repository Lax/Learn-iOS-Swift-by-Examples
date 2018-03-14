/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	A protocol that defines a type that can loop video.
*/

import UIKit

protocol Looper {
    
    init(videoURL: URL, loopCount: Int)
    
    func start(in layer: CALayer)
    
    func stop()
}
