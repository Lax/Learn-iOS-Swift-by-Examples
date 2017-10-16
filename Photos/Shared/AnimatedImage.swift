/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
Model object encapsulating an animated GIF.
*/

import UIKit
import ImageIO

class AnimatedImage {
    public let frameCount: Int
    public let duration: Double
    public let loopCount: Int
    public let size: CGSize
    private let imageSource: CGImageSource
    private let delays: [Double]
    
    convenience init?(url: URL) {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        self.init(source: src)
    }
    
    convenience init?(data: Data) {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        self.init(source: src)
    }
    
    init(source: CGImageSource) {
        imageSource = source
        frameCount = CGImageSourceGetCount(imageSource)
        
        if let imageProperties = CGImageSourceCopyProperties(source, nil) as? [String: AnyObject] {
            loopCount = AnimatedImage.loopCountForProperties(properties: imageProperties)
        } else {
            // The default loop count for a GIF with no loop count specified is 1.
            // Infinite loops are indicated by an explicit value of 0 for this property.
            loopCount = 1
        }
        
        if let firstImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
            size = CGSize(width: firstImage.width, height: firstImage.height)
        } else {
            size = CGSize.zero
        }
        
        var delayTimes = [Double](repeating: (1.0 / 30.0), count: frameCount)
        var totalDuration: Double = 0.0
        for index in 0..<frameCount {
            if let imageProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: AnyObject] {
                if let time = AnimatedImage.frameDelayForProperties(properties: imageProperties) {
                    delayTimes[index] = time
                }
            }
            totalDuration += delayTimes[index]
        }
        duration = totalDuration
        delays = delayTimes
    }
    
    static func frameDelayForProperties(properties: [String: AnyObject]) -> Double? {
        // Read the delay time for a GIF.
        guard let gifDictionary = properties[kCGImagePropertyGIFDictionary as String] as? [String: AnyObject] else {
            return nil
        }
        
        if let delay = (gifDictionary[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber)?.doubleValue {
            if delay > 0.0 {
                return delay
            }
        }
        if let delay = gifDictionary[kCGImagePropertyGIFDelayTime as String]?.doubleValue {
            if delay > 0.0 {
                return delay
            }
        }
        
        return nil
    }
    
    static func loopCountForProperties(properties: [String: AnyObject]) -> Int {
        if let gifDictionary: [String: AnyObject] = properties[kCGImagePropertyGIFDictionary as String] as? [String: AnyObject] {
            if let loopCount = (gifDictionary[kCGImagePropertyGIFLoopCount as String] as? NSNumber)?.intValue {
                return loopCount
            }
        }
        
        // A single playthrough is the default if loop count metadata is missing.
        return 1
    }
    
    func imageAtIndex(index: Int) -> CGImage? {
        if index < frameCount {
            return CGImageSourceCreateImageAtIndex(imageSource, index, nil)
        } else {
            return nil
        }
    }
    
    func delayAtIndex(index: Int) -> Double {
        return delays[index]
    }
}
