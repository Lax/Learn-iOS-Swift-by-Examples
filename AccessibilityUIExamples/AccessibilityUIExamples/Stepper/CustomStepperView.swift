/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example demonstrating adding accessibility to custom MTKView subclass that behaves
 like a stepper by implementing the NSAccessibilityStepper protocol.
*/

import Cocoa
import MetalKit

/*
 IMPORTANT: This is not a template for developing a custom stepper.
 This sample is intended to demonstrate how to add accessibility to
 existing custom controls that are not implemented using the preferred methods.
 For information on how to create custom controls please visit http://developer.apple.com
 */

class CustomStepperView: MTKView, NSAccessibilityStepper {
    
    // MARK: - Internals
    
    fileprivate struct LayoutInfo {
        static let stepperMinValue = CGFloat(0.0)
        static let stepperMaxValue = CGFloat(100.0)
        static let stepperStepSize = CGFloat(5.0)
    }
    
    var upButtonMouseDown = false
    var upButtonShowDepressed = false
    
    var downButtonMouseDown = false
    var downButtonShowDepressed = false
    
    var value = CGFloat(0.0) {
        didSet {
            if value < minValue {
                value = minValue
            }
            if value > maxValue {
                value = maxValue
            }
            needsDisplay = true
        }
    }
    
    var minValue = CGFloat(0.0)
    var maxValue = CGFloat(0.0)
    var stepSize = CGFloat(0.0)
    
    // MARK: - Metal Internals
    
    enum BufferIndices: Int {
        case vertices = 0
        case viewportSize
        case color
    }
    
    var trianglePipelineState: MTLRenderPipelineState?
    var backgroundPipelineState: MTLRenderPipelineState?
    var texture: MTLTexture?
    var commandQueue: MTLCommandQueue?
    var viewportSize: vector_uint2 = vector_uint2(0, 0)
    
    // MARK: - View Lifecycle
    
    required override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        commonInit()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    fileprivate func commonInit() {
        loadMetal()
        
        minValue = LayoutInfo.stepperMinValue
        maxValue = LayoutInfo.stepperMaxValue
        stepSize = LayoutInfo.stepperStepSize
        
        // Register for mouse events that affect drawing.
        let trackingArea = NSTrackingArea(rect: bounds,
                                          options: [NSTrackingArea.Options.activeWhenFirstResponder, NSTrackingArea.Options.mouseEnteredAndExited],
                                          owner: self,
                                          userInfo: nil)
        addTrackingArea(trackingArea)
    }
    
    // MARK: - Events
    
    // Set to allow keyDown to be called.
    override var acceptsFirstResponder: Bool { return true }
    
    var actionHandler: (() -> Void)?
    
    fileprivate func performAfterDelay(delay: Double, onCompletion: @escaping() -> Void) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay, execute: {
            onCompletion()
        })
    }
    
    fileprivate func performIncrementButtonPress() {
        upButtonShowDepressed = true
        downButtonShowDepressed = false
        needsDisplay = true
        
        let delayInSeconds = 0.1
        performAfterDelay(delay: delayInSeconds) {
            self.upButtonShowDepressed = false
            self.downButtonShowDepressed = false
            self.needsDisplay = true
            self.increment()
        }
    }
    
    fileprivate func performDecrementButtonPress() {
        upButtonShowDepressed = false
        downButtonShowDepressed = true
        needsDisplay = true
        
        let delayInSeconds = 0.1
        performAfterDelay(delay: delayInSeconds) {
            self.upButtonShowDepressed = false
            self.downButtonShowDepressed = false
            self.needsDisplay = true
            self.decrement()
        }
    }
    
    fileprivate func increment() {
        value += stepSize
        actionHandler!()
    }
    
    fileprivate func decrement() {
        value -= stepSize
        actionHandler!()
    }
    
    // MARK: - Layout
    
    fileprivate func upButtonRect() -> NSRect {
        return NSRect(x: bounds.origin.x, y: bounds.midY, width: bounds.size.width, height: bounds.size.height / 2.0)
    }
    
    fileprivate func downButtonRect() -> NSRect {
        return NSRect(x: bounds.origin.x, y: bounds.origin.y, width: bounds.size.width, height: bounds.size.height / 2.0)
    }
    
    // MARK: - Mouse Events
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        let mouseDownPoint = convert(event.locationInWindow, from: nil)
        if upButtonRect().contains(mouseDownPoint) {
            upButtonMouseDown = true
            upButtonShowDepressed = true
            downButtonMouseDown = false
            downButtonShowDepressed = false
        } else if downButtonRect().contains(mouseDownPoint) {
            upButtonMouseDown = false
            upButtonShowDepressed = false
            downButtonMouseDown = true
            downButtonShowDepressed = true
        }
        needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        let mouseUpPoint = convert(event.locationInWindow, from: nil)
        if upButtonMouseDown &&
            upButtonShowDepressed &&
            upButtonRect().contains(mouseUpPoint) {
            increment()
        } else if downButtonMouseDown &&
            downButtonShowDepressed &&
            downButtonRect().contains(mouseUpPoint) {
            decrement()
        }
        
        upButtonMouseDown = false
        upButtonShowDepressed = false
        downButtonMouseDown = false
        downButtonShowDepressed = false
        
        needsDisplay = true
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        
        let mousePoint = convert(event.locationInWindow, from:nil)
        if upButtonRect().contains(mousePoint) {
            upButtonShowDepressed = upButtonMouseDown
        } else if downButtonRect().contains(mousePoint) {
            downButtonShowDepressed = downButtonMouseDown
        }
        needsDisplay = true
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        
        upButtonShowDepressed = false
        downButtonShowDepressed = false
        
        needsDisplay = true
    }
    
    // MARK: - Keyboard Events
    
    override func keyDown(with event: NSEvent) {
        // Increment value on spacebar.
        if event.characters == " " {
            performIncrementButtonPress()
        } else {
            // Arrow keys are associated with the numeric keypad
            if event.modifierFlags.contains(.numericPad) {
                interpretKeyEvents([event])
            } else {
                super.keyDown(with: event)
            }
        }
    }
    
    override func moveUp(_ sender: Any?) {
        performIncrementButtonPress()
    }
    
    override func moveDown(_ sender: Any?) {
        performDecrementButtonPress()
    }
    
    // MARK: - MetalKit
    
    func loadMetal() {
        device = MTLCreateSystemDefaultDevice()
        do {
            // Indicate we would like to use the RGBAPixel format.
            colorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
            
            // Load all the shader files with a metal file extension in the project.
            let defaultLibrary = device!.makeDefaultLibrary()
            
            // Load the vertex function from the library.
            let vertexFunction = defaultLibrary!.makeFunction(name: "vertexShader")!
            
            // Set up a descriptor for creating a pipeline state object.
            let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
            pipelineStateDescriptor.label = "colored triangle pipeline"
            pipelineStateDescriptor.vertexFunction = vertexFunction
            pipelineStateDescriptor.fragmentFunction = defaultLibrary!.makeFunction(name: "triangleFragmentShader")
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = super.colorPixelFormat
            
            try trianglePipelineState = device!.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
            
            pipelineStateDescriptor.label = "background quad pipeline"
            pipelineStateDescriptor.fragmentFunction = defaultLibrary!.makeFunction(name: "backgroundFragmentShader")
            
            try backgroundPipelineState = device!.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
            
            let textureLoader = MTKTextureLoader(device: device!)
            try texture = textureLoader.newTexture(name: "Background", scaleFactor: 1.0, bundle: nil, options: nil)
            
            // Create the command queue.
            commandQueue = device?.makeCommandQueue()
        } catch {
            fatalError("Failed to setup Metal.")
        }
    }
    
    // MARK: - Drawing
    
    override func drawFocusRingMask() {
        bounds.fill()
    }
    
    override var focusRingMaskBounds: NSRect {
        return bounds
    }

    override func draw(_ dirtyRect: NSRect) {
        var whiteColor = vector_float4(1.0, 1.0, 1.0, 1.0)
        var pinkDiffusedColor = vector_float4(1.0, 0.0, 1.0, 1.0)
        var yellowDiffusedColor = vector_float4(1.0, 1.0, 0.0, 1.0)
        var halfViewportSize = vector_float2(Float(drawableSize.width) / 2.0,
                                             Float(drawableSize.height) / 2.0)
        
        var quadVertices: [Vertex] = [
            // Pixel Positions
            Vertex(position: vector_float4(x: -halfViewportSize.x, y: halfViewportSize.y, z: 0, w: 1),
                       // TexCoords
                texcoord: vector_float4(x: 0, y: 1, z: 0, w: 1)),
            Vertex(position: vector_float4(x: halfViewportSize.x, y: halfViewportSize.y, z: 0, w: 1),
                       texcoord: vector_float4(x: 1, y: 1, z: 0, w: 1)),
            Vertex(position: vector_float4(x: halfViewportSize.x, y: -halfViewportSize.y, z: 0, w: 1),
                       texcoord: vector_float4(x: 1, y: 0, z: 0, w: 1)),
            Vertex(position: vector_float4(x: halfViewportSize.x, y: -halfViewportSize.y, z: 0, w: 1),
                       texcoord: vector_float4(x: 1, y: 0, z: 0, w: 1)),
            Vertex(position: vector_float4(x: -halfViewportSize.x, y: -halfViewportSize.y, z: 0, w: 1),
                       texcoord: vector_float4(x: 0, y: 0, z: 0, w: 1)),
            Vertex(position: vector_float4(x: -halfViewportSize.x, y: halfViewportSize.y, z: 0, w: 1),
                       texcoord: vector_float4(x: 0, y: 1, z: 0, w: 1))
            ]
        
        var outlineVertices: [Vertex] = [
            // Note, value of texcoords doesn't matter as the pipeline these triangles are paired with don't
            // sample from a texture. (But we need to fill them in since the vertex shader expects them).
            
            // Top Triangle (Volume Up)
            Vertex(position: vector_float4(x: -halfViewportSize.x + 6, y: 4, z: 0, w: 1),
                       texcoord: vector_float4(x: 0, y: 0, z: 0, w: 1)),
            Vertex(position: vector_float4(x: 0, y: halfViewportSize.y - 3, z: 0, w: 1),
                       texcoord: vector_float4(x: 0, y: 0, z: 0, w: 1)),
            Vertex(position: vector_float4(x: halfViewportSize.x - 6, y: 4, z: 0, w: 1),
                       texcoord: vector_float4(x: 0, y: 0, z: 0, w: 1)),
            
            // Bottom Triangle (Volume Down).
            Vertex(position: vector_float4(x: -halfViewportSize.x + 6, y: -4, z: 0, w: 1),
                       texcoord: vector_float4(x: 0, y: 0, z: 0, w: 1)),
            Vertex(position: vector_float4(x: halfViewportSize.x - 6, y: -4, z: 0, w: 1),
                       texcoord: vector_float4(x: 0, y: 0, z: 0, w: 1)),
            Vertex(position: vector_float4(x: 0, y: -halfViewportSize.y + 3, z: 0, w: 1),
                       texcoord: vector_float4(x: 0, y: 0, z: 0, w: 1))
            ]
        
        var foregroundVertices: [Vertex] = [
            // Note, value of texcoords doesn't matter as the pipeline these triangles are paired with don't
            // sample from a texture. (But we need to fill them in since the vertex shader expects them).
            
            // Top Triangle (Volume Up).
            Vertex(position: vector_float4(x: -halfViewportSize.x + 9, y: 6, z: 0, w: 1),
                       texcoord: vector_float4(x: 0, y: 0, z: 0, w: 1)),
            Vertex(position: vector_float4(x: 0, y: halfViewportSize.y - 6, z: 0, w: 1),
                       texcoord: vector_float4(x: 0, y: 0, z: 0, w: 1)),
            Vertex(position: vector_float4(x: halfViewportSize.x - 9, y: 6, z: 0, w: 1),
                       texcoord: vector_float4(x: 0, y: 0, z: 0, w: 1)),
            
            // Bottom Triangle (Volume Down).
            Vertex(position: vector_float4(x: -halfViewportSize.x + 9, y: -6, z: 0, w: 1),
                       texcoord: vector_float4(x: 0, y: 0, z: 0, w: 1)),
            Vertex(position: vector_float4(x: halfViewportSize.x - 9, y: -6, z: 0, w: 1),
                       texcoord: vector_float4(x: 0, y: 0, z: 0, w: 1)),
            Vertex(position: vector_float4(x: 0, y: -halfViewportSize.y + 6, z: 0, w: 1),
                       texcoord: vector_float4(x: 0, y: 0, z: 0, w: 1))
            ]
        
        // Create a new command buffer for each renderpass to the current drawable.
        let commandBuffer = commandQueue?.makeCommandBuffer()
        commandBuffer?.label = "MyCommand"
        
        // Obtain a renderPassDescriptor generated from the view's drawable textures.
        let renderPassDescriptor = currentRenderPassDescriptor
        
        if let renderPassDescriptor = renderPassDescriptor {
            // Create a render command encoder so we can render into something.
            let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            renderEncoder?.label = "MyRenderEncoder"
            
            renderEncoder?.setCullMode(.back)
            
            renderEncoder?.setRenderPipelineState(backgroundPipelineState!)
            
            renderEncoder?.setVertexBytes(quadVertices,
                                          length: MemoryLayout.size(ofValue: quadVertices[0]) * quadVertices.count,
                                          index: Int(BufferIndexVertices.rawValue))
            
            renderEncoder?.setVertexBytes(&halfViewportSize,
                                          length: MemoryLayout.size(ofValue: halfViewportSize),
                                          index: Int(BufferIndexViewportSize.rawValue))
            
            renderEncoder?.setFragmentTexture(texture, index: 0)
            
            renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            
            renderEncoder?.setRenderPipelineState(trianglePipelineState!)
            
            renderEncoder?.setVertexBytes(outlineVertices,
                                          length: MemoryLayout.size(ofValue: outlineVertices[0]) * outlineVertices.count,
                                          index: BufferIndices.vertices.rawValue)
            
            renderEncoder?.setFragmentBytes(&whiteColor,
                                            length: MemoryLayout<vector_float4>.size,
                                            index: BufferIndices.color.rawValue)
            
            // Draw or 2 triangles.
            renderEncoder?.drawPrimitives(type: .triangle, vertexStart:0, vertexCount:6)
            
            renderEncoder?.setVertexBytes(foregroundVertices,
                                          length: MemoryLayout.size(ofValue: foregroundVertices[0]) * foregroundVertices.count,
                                          index: BufferIndices.vertices.rawValue)
            
            // Draw upper triangle.
            if upButtonShowDepressed {
                renderEncoder?.setFragmentBytes(&pinkDiffusedColor,
                                                length: MemoryLayout.size(ofValue: pinkDiffusedColor),
                                                index: BufferIndices.color.rawValue)
            } else {
                renderEncoder?.setFragmentBytes(&yellowDiffusedColor,
                                                length: MemoryLayout.size(ofValue: yellowDiffusedColor),
                                                index: BufferIndices.color.rawValue)
            }
            
            renderEncoder?.drawPrimitives(type: .triangle, vertexStart:0, vertexCount:3)
            
            // Draw lower triangle.
            if downButtonShowDepressed {
                renderEncoder?.setFragmentBytes(&pinkDiffusedColor,
                                                length: MemoryLayout.size(ofValue: pinkDiffusedColor),
                                                index: BufferIndices.color.rawValue)
            } else {
                renderEncoder?.setFragmentBytes(&yellowDiffusedColor,
                                                length: MemoryLayout.size(ofValue: yellowDiffusedColor),
                                                index: BufferIndices.color.rawValue)
            }
            
            renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 3, vertexCount: 3)
            
            renderEncoder?.endEncoding()
            
            if let drawable = currentDrawable {
                commandBuffer?.present(drawable)
            }
        }
        
        commandBuffer?.commit()
    }
}

// MARK: -

extension CustomStepperView {
    
    // MARK: NSAccessibilityStepper
    
    override func accessibilityLabel() -> String? {
        return NSLocalizedString("Volume", comment: "accessibility label for the volume stepper")
    }
    
    override func accessibilityHelp() -> String? {
        return NSLocalizedString("Adjusts the volume", comment: "accessibility help for the volume stepper")
    }
    
    override func accessibilityPerformIncrement() -> Bool {
        performIncrementButtonPress()
        return true
    }
    
    override func accessibilityPerformDecrement() -> Bool {
        performDecrementButtonPress()
        return true
    }
}
