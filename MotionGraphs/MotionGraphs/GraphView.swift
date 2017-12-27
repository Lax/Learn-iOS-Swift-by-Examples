/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A `UIView` subclass used to graph the values retreived from sensors. The graph is made up of segments represeneted by child views to avoid having to redraw the whole graph with every update.
 */

import UIKit
import simd

class GraphView: UIView {
    
    // MARK: Properties
    
    private var segments = [GraphSegment]()
    
    private var currentSegment: GraphSegment? {
        return segments.last
    }
    
    var valueRanges = [-4.0...4.0, -4.0...4.0, -4.0...4.0]
    
    // MARK: Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .black
    }
    
    // MARK: UIView overrides
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        
        // Fill the background.
        if let backgroundColor = backgroundColor {
            context.setFillColor(backgroundColor.cgColor)
            context.fill(bounds)
        }
        
        // Draw the static lines.
        context.drawGraphLines(in: bounds.size)
    }
    
    // MARK: Update methods
    
    func add(_ values: double3) {
        // Move all the segments horizontally.
        for segment in segments {
            segment.center.x += 1
        }
        
        // Add a new segment there are no segments or if the current segment is full.
        if segments.isEmpty {
            addSegment()
        }
        else if let segment = currentSegment, segment.isFull {
            addSegment()
            purgeSegments()
        }
        
        // Add the values to the current segment.
        currentSegment?.add(values)
    }
    
    // MARK: Private convenience methods
    
    private func addSegment() {
        let segmentWidth = CGFloat(GraphSegment.capacity)
        
        // Determine the start point for the next segment.
        let startPoint: double3
        if let currentSegment = currentSegment {
            startPoint = currentSegment.dataPoints.last!
        }
        else {
            startPoint = [0, 0, 0]
        }
        
        // Create and store a new segment.
        let segment = GraphSegment(startPoint: startPoint, valueRanges: valueRanges)
        segments.append(segment)
        
        // Add the segment to the view.
        segment.backgroundColor = backgroundColor
        segment.frame = CGRect(x: -segmentWidth, y: 0, width: segmentWidth, height: bounds.size.height)
        addSubview(segment)
    }
    
    private func purgeSegments() {
        segments = segments.filter { segment in
            if segment.frame.origin.x < bounds.size.width {
                // Include the segment if it's still visible.
                return true
            }
            else {
                // Remove the segment before excluding it from the filtered array.
                segment.removeFromSuperview()
                return false
            }
        }
    }
}
