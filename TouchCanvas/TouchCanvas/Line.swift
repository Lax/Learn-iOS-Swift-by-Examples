/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Contains the `Line` and `LinePoint` types used to represent and draw lines derived from touches.
 */

import UIKit

class Line: NSObject {
    // MARK: Properties

    // The live line.
    var points = [LinePoint]()

    // Use the estimation index of the touch to track points awaiting updates.
    var pointsWaitingForUpdatesByEstimationIndex = [NSNumber: LinePoint]()

    // Points already drawn into 'frozen' representation of this line.
    var committedPoints = [LinePoint]()

    var isComplete: Bool {
        return pointsWaitingForUpdatesByEstimationIndex.count == 0
    }

    func updateWithTouch(touch: UITouch) -> (Bool, CGRect) {
        if  let estimationUpdateIndex = touch.estimationUpdateIndex,
            let point = pointsWaitingForUpdatesByEstimationIndex[estimationUpdateIndex] {
            var rect = updateRectForExistingPoint(point: point)
            let didUpdate = point.updateWithTouch(touch: touch)
            if didUpdate {
                rect = rect.union(updateRectForExistingPoint(point: point))
            }
            if point.estimatedPropertiesExpectingUpdates == [] {
                pointsWaitingForUpdatesByEstimationIndex.removeValue(forKey: estimationUpdateIndex)
            }
            return (didUpdate,rect)
        }
        return (false, CGRect.null)
    }

    // MARK: Interface

    func addPointOfType(pointType: LinePoint.PointType, forTouch touch: UITouch) -> CGRect {
        let previousPoint = points.last
        let previousSequenceNumber = previousPoint?.sequenceNumber ?? -1
        let point = LinePoint(touch: touch, sequenceNumber: previousSequenceNumber + 1, pointType:pointType)

        if let estimationIndex = point.estimationUpdateIndex {
            if !point.estimatedPropertiesExpectingUpdates.isEmpty {
                pointsWaitingForUpdatesByEstimationIndex[estimationIndex] = point
            }
        }

        points.append(point)

        let updateRect = updateRectForLinePoint(point: point, previousPoint: previousPoint)

        return updateRect
    }

    func removePointsWithType(type: LinePoint.PointType) -> CGRect {
        var updateRect = CGRect.null
        var priorPoint: LinePoint?

        points = points.filter { point in
            let keepPoint = !point.pointType.contains(type)

            if !keepPoint {
                var rect = self.updateRectForLinePoint(point: point)

                if let priorPoint = priorPoint {
                    rect = rect.union(updateRectForLinePoint(point: priorPoint))
                }

                updateRect = updateRect.union(rect)
            }

            priorPoint = point

            return keepPoint
        }

        return updateRect
    }

    func cancel() -> CGRect {
        // Process each point in the line and accumulate the `CGRect` containing all the points.
        let updateRect = points.reduce(CGRect.null) { accumulated, point in
            // Update the type set to include `.Cancelled`.
            point.pointType.formUnion(.Cancelled)

            /*
                Union the `CGRect` for this point with accumulated `CGRect` and return it. The result is
                supplied to the next invocation of the closure.
            */
            return accumulated.union(updateRectForLinePoint(point: point))
        }

        return updateRect
    }

    // MARK: Drawing

    func drawInContext(context: CGContext, isDebuggingEnabled: Bool, usePreciseLocation: Bool) {
        var maybePriorPoint: LinePoint?

        for point in points {
            guard let priorPoint = maybePriorPoint else {
                maybePriorPoint = point
                continue
            }

            // This color will used by default for `.Standard` touches.
            var color = UIColor.black

            let pointType = point.pointType
            if isDebuggingEnabled {
                if pointType.contains(.Cancelled) {
                    color = UIColor.red
                }
                else if pointType.contains(.NeedsUpdate) {
                    color = UIColor.orange
                }
                else if pointType.contains(.Finger) {
                    color = UIColor.purple
                }
                else if pointType.contains(.Coalesced) {
                    color = UIColor.green
                }
                else if pointType.contains(.Predicted) {
                    color = UIColor.blue
                }
            } else {
                if pointType.contains(.Cancelled) {
                    color = UIColor.clear
                }
                else if pointType.contains(.Finger) {
                    color = UIColor.purple
                }
                if pointType.contains(.Predicted) && !pointType.contains(.Cancelled) {
                    color = color.withAlphaComponent(0.5)
                }
            }

            let location = usePreciseLocation ? point.preciseLocation : point.location
            let priorLocation = usePreciseLocation ? priorPoint.preciseLocation : priorPoint.location

            context.setStrokeColor(color.cgColor)

            context.beginPath()

            context.move(to: CGPoint(x: priorLocation.x, y: priorLocation.y))
            context.addLine(to: CGPoint(x: location.x, y: location.y))

            context.setLineWidth(point.magnitude)
            context.strokePath()

            // Draw azimuith and elevation on all non-coalesced points when debugging.
            if isDebuggingEnabled && !pointType.contains(.Coalesced) && !pointType.contains(.Predicted) && !pointType.contains(.Finger) {
                context.beginPath()
                context.setStrokeColor(UIColor.red.cgColor)
                context.setLineWidth(0.5)
                context.move(to: CGPoint(x: location.x, y: location.y))
                var targetPoint = CGPoint(x: 0.5 + 10.0 * cos(point.altitudeAngle), y:0.0)
                targetPoint = targetPoint.applying(CGAffineTransform.init(rotationAngle: point.azimuthAngle))
                targetPoint.x += location.x
                targetPoint.y += location.y
                context.addLine(to: CGPoint(x: targetPoint.x, y: targetPoint.y))
                context.strokePath()
            }

            maybePriorPoint = point
        }
    }

    func drawFixedPointsInContext(context: CGContext, isDebuggingEnabled: Bool, usePreciseLocation: Bool, commitAll: Bool = false) {
        let allPoints = points
        var committing = [LinePoint]()

        if commitAll {
            committing = allPoints
            points.removeAll()
        }
        else {
            for (index, point) in allPoints.enumerated() {
                // Only points whose type does not include `.NeedsUpdate` or `.Predicted` and are not last or prior to last point can be committed.
                guard point.pointType.intersection([.NeedsUpdate, .Predicted]).isEmpty && index < allPoints.count - 2 else {
                    committing.append(points.first!)
                    break
                }

                guard index > 0 else { continue }

                // First time to this point should be index 1 if there is a line segment that can be committed.
                let removed = points.removeFirst()
                committing.append(removed)
            }
        }
        // If only one point could be committed, no further action is required. Otherwise, draw the `committedLine`.
        guard committing.count > 1 else { return }

        let committedLine = Line()
        committedLine.points = committing
        committedLine.drawInContext(context: context, isDebuggingEnabled: isDebuggingEnabled, usePreciseLocation: usePreciseLocation)


        if committedPoints.count > 0 {
            // Remove what was the last point committed point; it is also the first point being committed now.
            committedPoints.removeLast()
        }

        // Store the points being committed for redrawing later in a different style if needed.
        committedPoints.append(contentsOf: committing)
    }

    func drawCommitedPointsInContext(context: CGContext, isDebuggingEnabled: Bool, usePreciseLocation: Bool) {
        let committedLine = Line()
        committedLine.points = committedPoints
        committedLine.drawInContext(context: context, isDebuggingEnabled: isDebuggingEnabled, usePreciseLocation: usePreciseLocation)
    }

    // MARK: Convenience

    func updateRectForLinePoint(point: LinePoint) -> CGRect {
        var rect = CGRect(origin: point.location, size: CGSize.zero)

        // The negative magnitude ensures an outset rectangle.
        let magnitude = -3 * point.magnitude - 2
        rect = rect.insetBy(dx: magnitude, dy: magnitude)

        return rect
    }

    func updateRectForLinePoint(point: LinePoint, previousPoint optionalPreviousPoint: LinePoint? = nil) -> CGRect {
        var rect = CGRect(origin: point.location, size: CGSize.zero)

        var pointMagnitude = point.magnitude

        if let previousPoint = optionalPreviousPoint {
            pointMagnitude = max(pointMagnitude, previousPoint.magnitude)
            rect = rect.union( CGRect(origin: previousPoint.location, size: CGSize.zero))
        }

        // The negative magnitude ensures an outset rectangle.
        let magnitude = -3.0 * pointMagnitude - 2.0
        rect = rect.insetBy(dx: magnitude, dy: magnitude)

        return rect
    }

    func updateRectForExistingPoint(point: LinePoint) -> CGRect {
        var rect = updateRectForLinePoint(point: point)

        let arrayIndex = point.sequenceNumber - points.first!.sequenceNumber

        if arrayIndex > 0 {
            rect = rect.union(updateRectForLinePoint(point: point, previousPoint: points[arrayIndex-1]))
        }
        if arrayIndex + 1 < points.count {
            rect = rect.union(updateRectForLinePoint(point: point, previousPoint: points[arrayIndex+1]))
        }
        return rect
    }

}


class LinePoint: NSObject  {
    // MARK: Types

    struct PointType: OptionSet {
        // MARK: Properties

        let rawValue: Int

        // MARK: Options

        static var Standard: PointType    { return self.init(rawValue: 0) }
        static var Coalesced: PointType   { return self.init(rawValue: 1 << 0) }
        static var Predicted: PointType   { return self.init(rawValue: 1 << 1) }
        static var NeedsUpdate: PointType { return self.init(rawValue: 1 << 2) }
        static var Updated: PointType     { return self.init(rawValue: 1 << 3) }
        static var Cancelled: PointType   { return self.init(rawValue: 1 << 4) }
        static var Finger: PointType      { return self.init(rawValue: 1 << 5) }
    }

    // MARK: Properties

    var sequenceNumber: Int
    let timestamp: TimeInterval
    var force: CGFloat
    var location: CGPoint
    var preciseLocation: CGPoint
    var estimatedPropertiesExpectingUpdates: UITouchProperties
    var estimatedProperties: UITouchProperties
    let type: UITouchType
    var altitudeAngle: CGFloat
    var azimuthAngle: CGFloat
    let estimationUpdateIndex: NSNumber?

    var pointType: PointType

    var magnitude: CGFloat {
        return max(force, 0.025)
    }

    // MARK: Initialization

    init(touch: UITouch, sequenceNumber: Int, pointType: PointType) {
        self.sequenceNumber = sequenceNumber
        self.type = touch.type
        self.pointType = pointType

        timestamp = touch.timestamp
        let view = touch.view
        location = touch.location(in: view)
        preciseLocation = touch.preciseLocation(in: view)
        azimuthAngle = touch.azimuthAngle(in: view)
        estimatedProperties = touch.estimatedProperties
        estimatedPropertiesExpectingUpdates = touch.estimatedPropertiesExpectingUpdates
        altitudeAngle = touch.altitudeAngle
        force = (type == .stylus || touch.force > 0) ? touch.force : 1.0

        if !estimatedPropertiesExpectingUpdates.isEmpty {
            self.pointType.formUnion(.NeedsUpdate)
        }

        estimationUpdateIndex = touch.estimationUpdateIndex
    }

    func updateWithTouch(touch: UITouch) -> Bool {
        guard let estimationUpdateIndex = touch.estimationUpdateIndex, estimationUpdateIndex == estimationUpdateIndex else { return false }

        // An array of the touch properties that may be of interest.
        let touchProperties: [UITouchProperties] = [.altitude, .azimuth, .force, .location]

        // Iterate through possible properties.
        for expectedProperty in touchProperties {
            // If an update to this property is not expected, continue to the next property.
            guard !estimatedPropertiesExpectingUpdates.contains(expectedProperty) else { continue }

            // Update the value of the point with the value from the touch's property.
            switch expectedProperty {
                case UITouchProperties.force:
                    force = touch.force
                case UITouchProperties.azimuth:
                    azimuthAngle = touch.azimuthAngle(in: touch.view)
                case UITouchProperties.altitude:
                    altitudeAngle = touch.altitudeAngle
                case UITouchProperties.location:
                    location = touch.location(in: touch.view)
                    preciseLocation = touch.preciseLocation(in: touch.view)
                default:
                    ()
            }

            if !touch.estimatedProperties.contains(expectedProperty) {
                // Flag that this point now has a 'final' value for this property.
                estimatedProperties.subtract(expectedProperty)
            }

            if !touch.estimatedPropertiesExpectingUpdates.contains(expectedProperty) {
                // Flag that this point is no longer expecting updates for this property.
                estimatedPropertiesExpectingUpdates.subtract(expectedProperty)

                if estimatedPropertiesExpectingUpdates.isEmpty {
                    // Flag that this point has been updated and no longer needs updates.
                    pointType.subtract(.NeedsUpdate)
                    pointType.formUnion(.Updated)
                }
            }
        }

        return true
    }
}

