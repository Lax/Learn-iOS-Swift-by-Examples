/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 An extension to `CGContext` to draw the horizontal lines in a `GraphView`.
 */

import UIKit

extension CGContext {
    func drawGraphLines(in size: CGSize) {
        // Configure context settings.
        self.saveGState()
        setShouldAntialias(false)
        translateBy(x: 0, y: size.height / 2.0)
        
        // Add lines to the context.
        let gridLineSpacing = size.height / 8.0
        for index in -3...3 {
            // Skip the center line.
            guard index != 0 else { continue }
            
            let position = floor(gridLineSpacing * CGFloat(index))
            move(to: CGPoint(x: 0, y: position))
            addLine(to: CGPoint(x: size.width, y: position))
        }
        
        // Stroke the lines.
        setStrokeColor(UIColor.darkGray.cgColor)
        strokePath()
        
        // Add and stroke the center line.
        move(to: CGPoint(x: 0, y: 0))
        addLine(to: CGPoint(x: size.width, y: 0))
        
        setStrokeColor(UIColor.lightGray.cgColor)
        strokePath()
        
        // Restore the context state.
        self.restoreGState()
    }
}
