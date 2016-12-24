/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The Stroke data model and math extensions for CG primitives for easier math
*/

import Foundation
import UIKit


class StrokeCollection {
    var strokes: [Stroke] = []
    var activeStroke: Stroke?
    
    func takeActiveStroke() {
        if let stroke = activeStroke {
            strokes.append(stroke)
            activeStroke = nil
        }
    }
}

enum StrokePhase {
    case began
    case changed
    case ended
    case cancelled
}

struct StrokeSample {
    // Always.
    let timestamp: TimeInterval
    let location: CGPoint
    
    // 3D Touch or Pencil.
    var force: CGFloat?
    
    // Pencil only.
    var estimatedProperties: UITouchProperties = []
    var estimatedPropertiesExpectingUpdates: UITouchProperties = []
    var altitude: CGFloat?
    var azimuth: CGFloat?
    
    var azimuthUnitVector: CGVector {
        return CGVector(dx: 1.0, dy: 0.0).apply(transform: CGAffineTransform(rotationAngle: azimuth!))
    }
    
    init(timestamp: TimeInterval, location: CGPoint,
         coalesced: Bool, predicted: Bool = false,
         force: CGFloat? = nil,
         azimuth: CGFloat? = nil, altitude: CGFloat? = nil, estimatedProperties: UITouchProperties = [], estimatedPropertiesExpectingUpdates: UITouchProperties = []) {
        self.timestamp = timestamp
        self.location = location
        self.force = force
        self.coalesced = coalesced
        self.predicted = predicted
        self.altitude = altitude
        self.azimuth = azimuth
    }

    /// Convenience accessor returns a non-optional (Default: 1.0)
    var forceWithDefault: CGFloat {
        return force ?? 1.0
    }

    /// Returns the force perpendicular to the screen. The regular stylus force is along the pencil axis.
    var perpendicularForce: CGFloat {
        let force = forceWithDefault
        if let altitude = altitude {
            let result = force / CGFloat(sin(Double(altitude)))
            return result
        } else {
            return force
        }
    }
    
    // Values for debug display.
    let coalesced: Bool
    let predicted: Bool
}

enum StrokeState {
    case active
    case done
    case cancelled
}

class Stroke {
    static let calligraphyFallbackAzimuthUnitVector = CGVector(dx: 1.0, dy:1.0).normalize!
    
    var samples: [StrokeSample] = []
    var predictedSamples: [StrokeSample] = []
    var previousPredictedSamples: [StrokeSample]?
    var state: StrokeState = .active
    var sampleIndicesExpectingUpdates = Set<Int>()
    var expectsAltitudeAzimuthBackfill = false
    var hasUpdatesFromStartTo: Int?
    var hasUpdatesAtEndFrom: Int?
    
    var receivedAllNeededUpdatesBlock: (() -> ())?

    func add(sample: StrokeSample) -> Int {
        let resultIndex = samples.count
        if hasUpdatesAtEndFrom == nil {
            hasUpdatesAtEndFrom = resultIndex
        }
        samples.append(sample)
        if previousPredictedSamples == nil {
            previousPredictedSamples = predictedSamples
        }
        if sample.estimatedPropertiesExpectingUpdates != [] {
            sampleIndicesExpectingUpdates.insert(resultIndex)
        }
        predictedSamples.removeAll()
        return resultIndex
    }
    
    func update(sample: StrokeSample, at index:Int) {
        if index == 0 {
            hasUpdatesFromStartTo = 0
        } else if hasUpdatesFromStartTo != nil && index == hasUpdatesFromStartTo! + 1 {
            hasUpdatesFromStartTo = index
        } else if hasUpdatesAtEndFrom == nil || hasUpdatesAtEndFrom! > index {
            hasUpdatesAtEndFrom = index
        }
        samples[index] = sample
        sampleIndicesExpectingUpdates.remove(index)
        
        if sampleIndicesExpectingUpdates.isEmpty {
            if let block = receivedAllNeededUpdatesBlock {
                receivedAllNeededUpdatesBlock = nil
                block()
            }
        }
    }

    func addPredicted(sample: StrokeSample) {
        predictedSamples.append(sample)
    }
    
    func clearUpdateInfo() {
        hasUpdatesFromStartTo = nil
        hasUpdatesAtEndFrom = nil
        previousPredictedSamples = nil
    }
    
    func updatedRanges() -> [CountableClosedRange<Int>] {
        guard hasUpdatesFromStartTo != nil || hasUpdatesAtEndFrom != nil else { return [] }
        if hasUpdatesFromStartTo == nil {
            return [(hasUpdatesAtEndFrom!)...(samples.count - 1)]
        } else if hasUpdatesAtEndFrom == nil {
            return [0...(hasUpdatesFromStartTo!)]
        } else {
            return [0...(hasUpdatesFromStartTo!), hasUpdatesAtEndFrom!...(samples.count - 1)]
        }
    }
    
}

extension Stroke : Sequence {
    func makeIterator() -> StrokeSegmentIterator {
        return StrokeSegmentIterator(stroke: self)
    }
}

private func interpolatedNormalUnitVector(between vector1: CGVector, and vector2: CGVector) -> CGVector {
    if let result = (vector1.normal + vector2.normal)?.normalize {
        return result
    } else {
        // This means they resulted in a 0,0 vector, 
        // in this case one of the incoming vectors is a good result.
        if let result = vector1.normalize {
            return result
        } else if let result = vector2.normalize {
            return result
        } else {
            // This case should not happen.
            return CGVector(dx:1.0, dy:0.0)
        }
    }
}

class StrokeSegment {
    var sampleBefore: StrokeSample?
    var fromSample: StrokeSample!
    var toSample: StrokeSample!
    var sampleAfter: StrokeSample?
    var fromSampleIndex: Int
    

    var segmentUnitNormal: CGVector {
        return segmentStrokeVector.normal!.normalize!
    }

    var fromSampleUnitNormal: CGVector {
        return interpolatedNormalUnitVector(between: previousSegmentStrokeVector, and: segmentStrokeVector)
    }

    var toSampleUnitNormal: CGVector {
        return interpolatedNormalUnitVector(between: segmentStrokeVector, and: nextSegmentStrokeVector)
    }

    var previousSegmentStrokeVector: CGVector {
        if let sampleBefore = self.sampleBefore {
            return fromSample.location - sampleBefore.location
        } else {
            return segmentStrokeVector
        }
    }
    
    var segmentStrokeVector: CGVector {
        return toSample.location - fromSample.location
    }

    var nextSegmentStrokeVector: CGVector {
        if let sampleAfter = self.sampleAfter {
            return sampleAfter.location - toSample.location
        } else {
            return segmentStrokeVector
        }
    }

    
    init(sample: StrokeSample) {
        self.sampleAfter = sample
        self.fromSampleIndex = -2
    }
    
    @discardableResult
    func advanceWithSample(incomingSample:StrokeSample?) -> Bool {
        if let sampleAfter = self.sampleAfter {
            self.sampleBefore = fromSample
            self.fromSample = toSample
            self.toSample = sampleAfter
            self.sampleAfter = incomingSample
            self.fromSampleIndex += 1
            return true
        }
        return false
    }
}

class StrokeSegmentIterator: IteratorProtocol {
    private let stroke: Stroke
    private var nextIndex: Int
    private let sampleCount: Int
    private let predictedSampleCount: Int
    private var segment: StrokeSegment!
    
    init(stroke: Stroke) {
        self.stroke = stroke
        nextIndex = 1
        sampleCount = stroke.samples.count
        predictedSampleCount = stroke.predictedSamples.count
        if (predictedSampleCount + sampleCount > 1) {
            segment = StrokeSegment(sample: sampleAt(0)!)
            segment.advanceWithSample(incomingSample: sampleAt(1))
        }
    }
    
    func sampleAt(_ index: Int) -> StrokeSample? {
        if (index < sampleCount) {
            return stroke.samples[index]
        }
        let predictedIndex = index - sampleCount
        if predictedIndex < predictedSampleCount {
            return stroke.predictedSamples[predictedIndex]
        } else {
            return nil
        }
    }
    
    func next() -> StrokeSegment? {
        nextIndex += 1
        if let segment = self.segment {
            if segment.advanceWithSample(incomingSample: sampleAt(nextIndex)) {
                return segment
            }
        }
        return nil
    }
}


