/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Custom video compositor class implementing the AVVideoCompositing protocol.
 */

import Foundation
import AVFoundation
import CoreVideo

class APLCustomVideoCompositor: NSObject, AVVideoCompositing {

    /// Returns the pixel buffer attributes required by the video compositor for new buffers created for processing.
    var requiredPixelBufferAttributesForRenderContext: [String : Any] =
        [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]

    /// The pixel buffer attributes of pixel buffers that will be vended by the adaptor’s CVPixelBufferPool.
    var sourcePixelBufferAttributes: [String : Any]? =
        [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]

    /// Set if all pending requests have been cancelled.
    var shouldCancelAllRequests = false

    /// Dispatch Queue used to issue custom compositor rendering work requests.
    private var renderingQueue = DispatchQueue(label: "com.apple.aplcustomvideocompositor.renderingqueue")
    /// Dispatch Queue used to synchronize notifications that the composition will switch to a different render context.
    private var renderContextQueue = DispatchQueue(label: "com.apple.aplcustomvideocompositor.rendercontextqueue")

    /// The current render context within which the custom compositor will render new output pixels buffers.
    private var renderContext: AVVideoCompositionRenderContext?

    /// Maintain the state of render context changes.
    private var internalRenderContextDidChange = false
    /// Actual state of render context changes.
    private var renderContextDidChange: Bool {
        get {
            return renderContextQueue.sync { internalRenderContextDidChange }
        }
        set (newRenderContextDidChange) {
            renderContextQueue.sync { internalRenderContextDidChange = newRenderContextDidChange }
        }
    }

    /// Instance of `APLMetalRenderer` used to issue rendering commands to subclasses.
    private var metalRenderer: APLMetalRenderer

    fileprivate init(metalRenderer: APLMetalRenderer) {
        self.metalRenderer = metalRenderer
    }

    // MARK: AVVideoCompositing protocol functions

    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        renderContextQueue.sync { renderContext = newRenderContext }
        renderContextDidChange = true
    }

    enum PixelBufferRequestError: Error {
        case newRenderedPixelBufferForRequestFailure
    }

    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {

        autoreleasepool {
            renderingQueue.async {
                // Check if all pending requests have been cancelled.
                if self.shouldCancelAllRequests {
                    asyncVideoCompositionRequest.finishCancelledRequest()
                } else {

                    guard let resultPixels =
                        self.newRenderedPixelBufferForRequest(asyncVideoCompositionRequest) else {
                            asyncVideoCompositionRequest.finish(with: PixelBufferRequestError.newRenderedPixelBufferForRequestFailure)
                            return
                    }

                    // The resulting pixelbuffer from Metal renderer is passed along to the request.
                    asyncVideoCompositionRequest.finish(withComposedVideoFrame: resultPixels)
                }
            }
        }
    }

    func cancelAllPendingVideoCompositionRequests() {

        /*
         Pending requests will call finishCancelledRequest, those already rendering will call
         finishWithComposedVideoFrame.
         */
        renderingQueue.sync { shouldCancelAllRequests = true }
        renderingQueue.async {
            // Start accepting requests again.
            self.shouldCancelAllRequests = false
        }
    }

    // MARK: Utilities

    func factorForTimeInRange( _ time: CMTime, range: CMTimeRange) -> Float64 { /* 0.0 -> 1.0 */

        let elapsed = CMTimeSubtract(time, range.start)

        return CMTimeGetSeconds(elapsed) / CMTimeGetSeconds(range.duration)
    }

    func newRenderedPixelBufferForRequest(_ request: AVAsynchronousVideoCompositionRequest) -> CVPixelBuffer? {

        /*
         tweenFactor indicates how far within that timeRange are we rendering this frame. This is normalized to vary
         between 0.0 and 1.0. 0.0 indicates the time at first frame in that videoComposition timeRange. 1.0 indicates
         the time at last frame in that videoComposition timeRange.
         */
        let tweenFactor =
            factorForTimeInRange(request.compositionTime, range: request.videoCompositionInstruction.timeRange)

        guard let currentInstruction =
            request.videoCompositionInstruction as? APLCustomVideoCompositionInstruction else {
            return nil
        }

        // Source pixel buffers are used as inputs while rendering the transition.
        guard let foregroundSourceBuffer = request.sourceFrame(byTrackID: currentInstruction.foregroundTrackID) else {
            return nil
        }
        guard let backgroundSourceBuffer = request.sourceFrame(byTrackID: currentInstruction.backgroundTrackID) else {
            return nil
        }

        // Destination pixel buffer into which we render the output.
        guard let dstPixels = renderContext?.newPixelBuffer() else { return nil }

        if renderContextDidChange { renderContextDidChange = false }

        metalRenderer.renderPixelBuffer(dstPixels, usingForegroundSourceBuffer:foregroundSourceBuffer,
                                        andBackgroundSourceBuffer:backgroundSourceBuffer,
                                        forTweenFactor:Float(tweenFactor))

        return dstPixels
    }
}

class APLCrossDissolveCompositor: APLCustomVideoCompositor {

    init?() {
        guard let newRenderer = APLCrossDissolveRenderer() else { return nil }
        super.init(metalRenderer: newRenderer)
    }
}

class APLDiagonalWipeCompositor: APLCustomVideoCompositor {

    init?() {
        guard let newRenderer = APLDiagonalWipeRenderer() else { return nil }
        super.init(metalRenderer: newRenderer)
    }
}

