/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A custom view that changes the brush size based on the pressure the user applies to the Force Touch Trackpad. Also contains a subclass of DrawingView (MasterDrawingView) that provides an example of how to configure the trackpad so that the user does not get force clicks while drawing.
*/

import Cocoa

class MasterDrawingView: DrawingView {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Configures the trackpad so that the user does not get force clicks when drawing.
        pressureConfiguration = NSPressureConfiguration(pressureBehavior: .primaryGeneric)
    }
}

class DrawingView: NSView {
    // MARK: Properties

    static let minStrokeWidth: CGFloat = 1.0
    static let maxStrokeWidth: CGFloat = 15.0

    var drawingBitmap: NSBitmapImageRep?
    var eraseTimer: Timer?
    var penColor = NSColor.darkGray
    
    // MARK: Force Touch Trackpad Event Handling
    
    func dataFromMouseEvent(_ event: NSEvent, pressure: CGFloat) -> (loc: NSPoint, pressure: CGFloat, isUp: Bool) {
        let loc = convert(event.locationInWindow, from: nil)
        var isUp = false
        var outPressure = pressure
        
        switch event.type {
            case .leftMouseUp:
                isUp = true
            
            case .leftMouseDragged:
                if event.subtype == .tabletPoint {
                    // Pressure is always in the range [0,1].
                    outPressure = CGFloat(event.pressure)
                }
            
            case .tabletPoint:
                /*
                    Tablets issue pure tablet point events between the mouse down and
                    the first mouse drag. After that it should be all mouse drag events.
                    Pressure is always in the range [0,1].
                */
                outPressure = CGFloat(event.pressure)
            
            case .pressure:
                if event.stage > 1 {
                    /*
                        Cap pressure at 1. If we moved to stage 2, then consider this max pressure.
                        Note: Generally, do not add the stage value to the pressure value to get
                        a larger dynamic range. The force click feedback will be distracting
                        to the user and the additional pressure curves are not tuned for this.
                        You should set the pressureConfiguration to NSPressureBehaviorGeneric
                        to get a single stage pressure gesture with a large, properly tuned
                        input range. See MasterDrawingView below for an example.
                    */
                    outPressure = 1.0
                }
                else {
                    // Pressure is always in the range [0,1].
                    outPressure = CGFloat(event.pressure)
                }
            
            default:
                break
        }
        
        return (loc, outPressure, isUp)
    }
    
    override func mouseDown(with mouseDownEvent: NSEvent) {
        cancelEraseTimer()
        
        let drawingBitmap = drawingBitmapCreateIfNeeded()
        
        NSEvent.setMouseCoalescingEnabled(false)
        var lastLocation = convert(mouseDownEvent.locationInWindow, from: nil)
        
        // This may not be a force capable or tablet device. Let's start off with 1/4 pressure.
        var lastPressure: CGFloat = 0.25

        /*
            Add the pressure event mask to the drag events mask.

            Note: This value is used in the event coalescing loop, thus the `mouseUpMask`
            is not included here. It's added in the eventTrackingMask below
        */
        let dragEventsMask: NSEventMask = [.leftMouseDragged, .tabletPoint, .pressure]
        
        /*
            The eventTracking mask is the same as dragEventMasks but it also includes
            the mouse up event because tracking ends on mouse up.
        */
        let eventTrackingMask = dragEventsMask.union(.leftMouseUp)

        window!.trackEvents(matching: eventTrackingMask, timeout: NSEventDurationForever, mode: RunLoopMode.eventTrackingRunLoopMode) { event, stop in
            var newLocation = lastLocation
            var newPressure = lastPressure
            var isUp: Bool

            // Update new mouse event properties based on tuple return from `dataFromMouseEvent()`.
            (newLocation, newPressure, isUp) = self.dataFromMouseEvent(event, pressure: lastPressure)
            
            self.needsDisplay = true
            
            if isUp {
                /*
                    Avoid drawing a point for the mouse up. The pressure on the mouse up
                    will will be close to 0, and it's generally at the last mouse drag
                    location anyway.
                */
                stop.pointee = true
                return
            }

            self.drawInBitmap(drawingBitmap) {
                self.penColor.set()
                
                self.strokeLineFromPoint(lastLocation, toPoint: newLocation, pressure: newPressure, minWidth: DrawingView.minStrokeWidth, maxWidth: DrawingView.maxStrokeWidth)
                
                lastLocation = newLocation
                lastPressure = newPressure
                
                /*
                    Mouse event coalescing is turned off so that we get all of the input.
                    To keep up, we need to absorb all events still in the queue.
                    Note: A custom run loop mode is specified to prevent timers and other run
                    loop sources from firing while we absorb these events.
                */
                while let absorbedEvent = self.window!.nextEvent(matching: NSEventMask(rawValue: UInt64(Int(dragEventsMask.rawValue))), until: Date.distantPast, inMode: RunLoopMode(rawValue: "DrawingView_Event_Coalescing_Mode"), dequeue: true) {

                    (newLocation, newPressure, isUp) = self.dataFromMouseEvent(absorbedEvent, pressure: lastPressure)
                    
                    self.strokeLineFromPoint(lastLocation, toPoint: newLocation, pressure: newPressure, minWidth: DrawingView.minStrokeWidth, maxWidth: DrawingView.maxStrokeWidth)
                    
                    lastLocation = newLocation
                    
                    lastPressure = newPressure
                }
            }
        }
            
        NSEvent.setMouseCoalescingEnabled(true)
            
        installEraseTimer()
    }
    
    
    // MARK: Drawing
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if let drawingBitmap = drawingBitmap {
            drawingBitmap.draw(in: bounds, from: NSZeroRect, operation: .sourceOver, fraction: 1.0, respectFlipped: false, hints: nil)
        }
        else {
            NSColor.white.set()
            NSRectFill(dirtyRect)
            
            let drawHereString = NSAttributedString(string: "Draw Here", attributes: [
                NSForegroundColorAttributeName: NSColor.gray,
                NSFontAttributeName: NSFont.userFont(ofSize: 24.0)!
            ])
            
            let stringSize = drawHereString.size()
            
            let drawPointX = bounds.midX - (stringSize.width / 2.0)
            let drawPointY = bounds.midY - (stringSize.height / 2.0)
            let drawPoint = NSPoint(x: drawPointX, y: drawPointY)
            
            drawHereString.draw(at: drawPoint)
        }
        
        NSColor.black.set()
        NSFrameRectWithWidth(bounds, 2.0)
    }
    
    // MARK: Convenience
    
    func eraseTimerFired(_ timer: Timer) {
        eraseTimer = nil
        drawingBitmap = nil
        needsDisplay = true
    }
    
    func installEraseTimer() {
        eraseTimer = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(DrawingView.eraseTimerFired(_:)), userInfo: nil, repeats: false)
    }
    
    func cancelEraseTimer() {
        eraseTimer?.invalidate()
        eraseTimer = nil
    }
    
    func drawingBitmapCreateIfNeeded() -> NSBitmapImageRep {
        if drawingBitmap == nil {
            drawingBitmap = bitmapImageRepForCachingDisplay(in: bounds)
            
            let bitmapGraphicsContext = NSGraphicsContext(bitmapImageRep: drawingBitmap!)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.setCurrent(bitmapGraphicsContext)
            NSColor.white.set()
            
            let fillRect = NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
            NSRectFillUsingOperation(fillRect, .sourceOver)
            
            NSGraphicsContext.restoreGraphicsState()
        }
        
        return drawingBitmap!
    }
    
    func strokeLineFromPoint(_ fromPoint: NSPoint, toPoint: NSPoint, pressure: CGFloat, minWidth: CGFloat, maxWidth:CGFloat) {
        let width = minWidth + (pressure * (maxWidth - minWidth))
        let bezierPath = NSBezierPath()
        bezierPath.move(to: fromPoint)
        bezierPath.line(to: toPoint)
        bezierPath.lineWidth = width
        bezierPath.lineCapStyle = .roundLineCapStyle
        bezierPath.stroke()
    }
    
    func drawInBitmap(_ bitmap: NSBitmapImageRep, handler: (Void) -> Void) {
        let bitmapGraphicsContext = NSGraphicsContext(bitmapImageRep: bitmap)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.setCurrent(bitmapGraphicsContext)
        
        handler()
        
        NSGraphicsContext.restoreGraphicsState()
    }
}
