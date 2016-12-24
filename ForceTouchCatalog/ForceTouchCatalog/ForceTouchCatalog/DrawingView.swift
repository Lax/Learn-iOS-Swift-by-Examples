/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A custom view that changes the brush size based on the pressure the user applies to the Force Touch Trackpad. Also contains a subclass of DrawingView (MasterDrawingView) that provides an example of how to configure the trackpad so that the user does not get force clicks while drawing.
*/

import Cocoa

class DrawingView: NSView {
    static let minStrokeWidth = CGFloat(1.0)
    static let maxStrokeWidth = CGFloat(15.0)

    var drawingBitmap: NSBitmapImageRep?
    var eraseTimer: NSTimer?
    var penColor = NSColor.darkGrayColor()

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        if let drawingBitmap = drawingBitmap {
            drawingBitmap.drawInRect(bounds, fromRect: NSZeroRect, operation: .CompositeSourceOver, fraction: 1.0, respectFlipped: false, hints: nil)
        } else {
            NSColor.whiteColor().set()
            NSRectFill(dirtyRect)
            
            let drawHereString = NSAttributedString(string: "Draw Here", attributes: [NSForegroundColorAttributeName : NSColor.grayColor(), NSFontAttributeName : NSFont.userFontOfSize(24.0)!])
            let stringSize = drawHereString.size()
            let drawPoint = NSMakePoint(bounds.midX - (stringSize.width / 2.0), bounds.midY - (stringSize.height / 2.0))
            drawHereString.drawAtPoint(drawPoint)
        }
        
        NSColor.blackColor().set()
        NSFrameRectWithWidth(bounds, 2.0)
    }
    
    func eraseTimerFired(timer: NSTimer) {
        eraseTimer = nil
        drawingBitmap = nil
        needsDisplay = true
    }
    
    func installEraseTimer() {
        eraseTimer = NSTimer.scheduledTimerWithTimeInterval(4.0, target: self, selector: "eraseTimerFired:", userInfo: nil, repeats: false)
    }
    
    func cancelEraseTimer() {
        eraseTimer?.invalidate()
        eraseTimer = nil
    }
    
    func drawingBitmapCreateIfNeeded() -> NSBitmapImageRep! {
        if drawingBitmap == nil {
            drawingBitmap = bitmapImageRepForCachingDisplayInRect(bounds)
    
            let bitmapGraphicsContext = NSGraphicsContext(bitmapImageRep: drawingBitmap!)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.setCurrentContext(bitmapGraphicsContext)
            NSColor.whiteColor().set()
            NSRectFillUsingOperation(NSMakeRect(0, 0, bounds.width, bounds.height), NSCompositingOperation.CompositeSourceOver)
            NSGraphicsContext.restoreGraphicsState()
            
        }
        
        return drawingBitmap
    }
    
    func strokeLineFromPoint(fromPoint:NSPoint, toPoint:NSPoint, pressure:CGFloat, minWidth:CGFloat, maxWidth:CGFloat) {
        let width = minWidth + (pressure * (maxWidth - minWidth))
        let bezierPath = NSBezierPath()
        bezierPath.moveToPoint(fromPoint)
        bezierPath.lineToPoint(toPoint)
        bezierPath.lineWidth = width
        bezierPath.lineCapStyle = .RoundLineCapStyle
        bezierPath.stroke()
    }
    
    func drawInBitmap(bitmap: NSBitmapImageRep, handler: () -> Void) {
        let bitmapGraphicsContext = NSGraphicsContext(bitmapImageRep: bitmap)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.setCurrentContext(bitmapGraphicsContext)

        handler()
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    func dataFromMouseEvent(event: NSEvent, pressure:CGFloat) -> (loc: NSPoint, pressure: CGFloat, isUp: Bool) {
        let loc = convertPoint(event.locationInWindow, fromView:nil)
        var isUp = false
        var outPressure = pressure
        
        switch event.type {
        case .LeftMouseUp:
            isUp = true
            break
            
        case .LeftMouseDragged:
            if event.subtype == .NSTabletPointEventSubtype {
                // Pressure is always in the range [0,1].
                outPressure = CGFloat(event.pressure)
            }
            break
            
        case .TabletPoint:
            /*
                Tablets issue pure tablet point events between the mouse down and
                the first mouse drag. After that it should be all mouse drag events.
                Pressure is always in the range [0,1].
            */
            outPressure = CGFloat(event.pressure)
            break
            
        case .EventTypePressure:
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
            } else {
                // Pressure is always in the range [0,1].
                outPressure = CGFloat(event.pressure)
            }
            break
            
        default:
            break
        }
        
        return (loc, outPressure, isUp)
    }
    
    override func mouseDown(mouseDownEvent: NSEvent) {
        
        cancelEraseTimer()
        
        let drawingBitmap = drawingBitmapCreateIfNeeded()
        
        /*
            Add the pressure event mask to the drag events mask.
            Note: This value is also used in the event coalescing loop, thus the mouseUpMask
            is not included here. It's added directly in the outer tracking loop.
        */
        let dragEventsMask: NSEventMask = [.LeftMouseDraggedMask, .TabletPointMask, .EventMaskPressure]
        
        NSEvent.setMouseCoalescingEnabled(false)
        var lastLocation = convertPoint(mouseDownEvent.locationInWindow, fromView:nil)
        
        // This may not be a force capable or tablet device. Let's start off with 1/4 pressure.
        var lastPressure: CGFloat = 0.25

        window!.trackEventsMatchingMask(dragEventsMask.union(.LeftMouseUpMask), timeout: NSEventDurationForever, mode:NSEventTrackingRunLoopMode) { (event, stop) in
            var newLocation = lastLocation
            var newPressure = lastPressure
            var isUp: Bool
            (lastLocation, newPressure, isUp) = self.dataFromMouseEvent(event, pressure: lastPressure)
            
            self.needsDisplay = true
            if isUp {
                /*
                    Avoid drawing a point for the mouse up. The pressure on the mouse up
                    will will be close to 0, and it's generally at the last mouse drag
                    location anyway.
                */
                stop.memory = true
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
                while let absorbedEvent = self.window!.nextEventMatchingMask(Int(dragEventsMask.rawValue), untilDate: NSDate.distantPast(), inMode: "DrawingView_Event_Coalescing_Mode", dequeue:true) {
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
}

class MasterDrawingView: DrawingView {
    override func awakeFromNib() {
        super.awakeFromNib()
        pressureConfiguration = NSPressureConfiguration(pressureBehavior: .PrimaryGeneric)
    }
}


