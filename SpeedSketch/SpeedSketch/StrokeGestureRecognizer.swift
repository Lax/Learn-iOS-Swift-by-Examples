/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The custom UIGestureRecognizer subclass to capture strokes.
*/

import UIKit
import UIKit.UIGestureRecognizerSubclass


class StrokeGestureRecognizer: UIGestureRecognizer {
    // MARK: Configuration.
    var collectsCoalescedTouches = true
    var usesPredictedSamples = true
    var isForPencil: Bool = false {
        didSet {
            if (isForPencil) {
                allowedTouchTypes = [UITouchType.stylus.rawValue as NSNumber]
            } else {
                allowedTouchTypes = [UITouchType.direct.rawValue as NSNumber]
            }
        }
    }

    // MARK: Data.
    var stroke = Stroke()
    var outstandingUpdateIndexes = [Int:(Stroke, Int)]()
    var coordinateSpaceView: UIView?

    // MARK: State.
    var trackedTouch: UITouch?
    var initialTimestamp: TimeInterval?
    var collectForce = false

    var fingerStartTimer: Timer? = nil
    private let cancellationTimeInterval = TimeInterval(0.1)
    
    var ensuredReferenceView: UIView {
        if let view = coordinateSpaceView {
            return view
        } else  {
            return view!
        }
    }
    
    // MARK: Stroke data collection.
    func append(touches: Set<UITouch>, event: UIEvent?) -> Bool {
        if let touchToAppend = trackedTouch {
            
            // Cancel the stroke recognition if we get a second touch during cancellation period.
            for touch in touches {
                if touch !== touchToAppend &&
                    touch.timestamp - initialTimestamp! < cancellationTimeInterval {
                    if state == .possible {
                        state = .failed
                    } else {
                        state = .cancelled
                    }
                    return false
                }
            }
            
            // See if those touches contain our tracked touch. If not, ignore gracefully.
            if touches.contains(touchToAppend) {

                let collector = { (stroke: Stroke, touch: UITouch, view: UIView, coalesced: Bool , predicted: Bool ) in

                    // Only collect samples that actually moved in 2D space.
                    let location = touch.preciseLocation(in: view)
                    if let previousSample = stroke.samples.last {
                        if (previousSample.location - location).quadrance < 0.003 {
                            return
                        }
                    }
                    
                    var sample = StrokeSample(timestamp: touch.timestamp, location: location, coalesced: coalesced, predicted: predicted, force: self.collectForce ? touch.force : nil)
                    if touch.type == .stylus {
                        let estimatedProperties = touch.estimatedProperties
                        sample.estimatedProperties = estimatedProperties
                        sample.estimatedPropertiesExpectingUpdates = touch.estimatedPropertiesExpectingUpdates
                        sample.altitude = touch.altitudeAngle
                        sample.azimuth = touch.azimuthAngle(in: view)
                        if stroke.samples.count == 0 &&
                            estimatedProperties.contains(.azimuth) {
                            stroke.expectsAltitudeAzimuthBackfill = true
                        } else if stroke.expectsAltitudeAzimuthBackfill &&
                            !estimatedProperties.contains(.azimuth) {
                            for (index, priorSample) in stroke.samples.enumerated() {
                                var updatedSample = priorSample
                                if updatedSample.estimatedProperties.contains(.altitude) {
                                    updatedSample.estimatedProperties.remove(.altitude)
                                    updatedSample.altitude = sample.altitude
                                }
                                if updatedSample.estimatedProperties.contains(.azimuth) {
                                    updatedSample.estimatedProperties.remove(.azimuth)
                                    updatedSample.azimuth = sample.azimuth
                                }
                                stroke.update(sample: updatedSample, at: index)
                            }
                            stroke.expectsAltitudeAzimuthBackfill = false
                        }
                    }
                    if predicted {
                        stroke.addPredicted(sample: sample)
                    } else {
                        let index = stroke.add(sample: sample)
                        if touch.estimatedPropertiesExpectingUpdates != [] {
                            self.outstandingUpdateIndexes[Int(touch.estimationUpdateIndex!)] = (stroke, index)
                        }
                    }
                }
                
                let view = ensuredReferenceView
                if collectsCoalescedTouches {
                    if let event = event {
                        let coalescedTouches = event.coalescedTouches(for: touchToAppend)!
                        let lastIndex = coalescedTouches.count - 1
                        for index in 0..<lastIndex {
                            collector(stroke, coalescedTouches[index], view, true, false)
                        }
                        collector(stroke, coalescedTouches[lastIndex], view, false, false)
                    }
                } else {
                    collector(stroke, touchToAppend, view, false, false)
                }
                
                if (usesPredictedSamples && stroke.state == .active) {
                    if let predictedTouches = event?.predictedTouches(for: touchToAppend) {
                        for touch in predictedTouches {
                            collector(stroke, touch, view, false, true)
                        }
                    }
                }
                return true
            }
        }
        return false
    }
    
    // MARK: Touch handling methods.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if trackedTouch == nil {
            trackedTouch = touches.first
            initialTimestamp = trackedTouch?.timestamp
            collectForce = trackedTouch!.type == .stylus || view?.traitCollection.forceTouchCapability == .available
            if !isForPencil {
                fingerStartTimer = Timer.scheduledTimer(timeInterval: cancellationTimeInterval, target: self, selector: #selector(beginIfNeeded(_:)), userInfo: nil, repeats: false)
            }
        }
        if append(touches: touches, event:event) {
            if isForPencil {
                state = .began
            }
        }
    }

    // If not for pencil we give other gestures (pan, pinch) a chance by delaying our begin just a little.
    func beginIfNeeded(_ timer: Timer) {
        if state == .possible {
            state = .began
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if append(touches: touches, event:event) {
            if state == .began {
                state = .changed
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if append(touches: touches, event:event) {
            stroke.state = .done
            state = .ended
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if append(touches: touches, event:event) {
            stroke.state = .cancelled
            state = .failed
        }
    }
    
    override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {
        for touch in touches {
            if let (stroke, sampleIndex) = outstandingUpdateIndexes[Int(touch.estimationUpdateIndex!)] {
                var sample = stroke.samples[sampleIndex]
                let expectedUpdates = sample.estimatedPropertiesExpectingUpdates
                // Only force is reported this way as of iOS 10.0
                if expectedUpdates.contains(.force) {
                    sample.force = touch.force
                    if !touch.estimatedProperties.contains(.force) {
                        // Only remove the estimate flag if the new value isn't estimated as well.
                        sample.estimatedProperties.remove(.force)
                    }
                }
                sample.estimatedPropertiesExpectingUpdates = touch.estimatedPropertiesExpectingUpdates
                if touch.estimatedPropertiesExpectingUpdates == [] {
                    outstandingUpdateIndexes.removeValue(forKey: sampleIndex)
                }
                stroke.update(sample: sample, at: sampleIndex)
            }
        }
    }

    override func reset() {
        stroke = Stroke()
        trackedTouch = nil
        if let timer = fingerStartTimer {
            timer.invalidate()
            fingerStartTimer = nil
        }
        super.reset()
    }
}
