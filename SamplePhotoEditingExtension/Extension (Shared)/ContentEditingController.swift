/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class provides the core photo editing functionality for both OS X and iOS extensions.
 */

import Photos
import PhotosUI
import AVFoundation
#if os(iOS)
import MobileCoreServices
#endif

/// Protocol for communication back to the view controller that owns the ContentEditingController.
protocol ContentEditingDelegate {
    var preselectedFilterIndex: Int? { get set }
    var previewImage: CIImage? { get set }
    @available(OSXApplicationExtension 10.12, *)
    var previewLivePhoto: PHLivePhoto? { get set }
}

/// Provides photo editing functions for both OS X and iOS photo extension view controllers.
class ContentEditingController: NSObject {

    var input: PHContentEditingInput!
    var delegate: ContentEditingDelegate!

    // Wrap in a lazy var so it can be hidden from earlier OS with @available.
    @available(OSXApplicationExtension 10.12, iOSApplicationExtension 10.0, *)
    lazy var livePhotoContext: PHLivePhotoEditingContext = {
        return PHLivePhotoEditingContext(livePhotoEditingInput: self.input)!
    }()

    static let wwdcLogo: CIImage = {
        guard let url = Bundle(for: ContentEditingController.self).url(forResource: "Logo_WWDC2016", withExtension: "png")
            else { fatalError("missing watermark image") }
        guard let image = CIImage(contentsOf: url)
            else { fatalError("can't load watermark image") }
        return image
    }()

    lazy var formatIdentifier = Bundle(for: ContentEditingController.self).bundleIdentifier!
    let formatVersion = "1.0"

    var selectedFilterName: String?
    let wwdcFilter = "WWDC16"
    let filterNames = ["WWDC16", "CISepiaTone", "CIPhotoEffectChrome", "CIPhotoEffectInstant", "CIColorInvert", "CIColorPosterize"]
    var previewImages: [CIImage]?

    // MARK: PHContentEditingController

    func canHandle(_ adjustmentData: PHAdjustmentData) -> Bool {
        // Check the adjustment's identifier and version to allow resuming prior edits.
        return adjustmentData.formatIdentifier == formatIdentifier && adjustmentData.formatVersion == formatVersion
    }

    func startContentEditing(with contentEditingInput: PHContentEditingInput) {
        input = contentEditingInput

        // Create preview images for all filters.
        // If adjustment data is compatbile, these start from the last edit's pre-filter image.
        updateImagePreviews()

        // Read adjustment data to choose (again) the last chosen filter.
        if let adjustmentData = input.adjustmentData {
            do {
                selectedFilterName = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(adjustmentData.data as NSData) as? String
            } catch {
                print("can't unarchive adjustment data, reverting to default filter")
            }
        }

        // Show filter previews for the input image in the UI.
        if let filterName = selectedFilterName, let index = filterNames.index(of: filterName) {
            delegate.preselectedFilterIndex = index
            delegate.previewImage = previewImages![index]
        }
        // ...including for Live Photo, if editing that kind of asset.
        if #available(OSXApplicationExtension 10.12, iOSApplicationExtension 10.0, *) {
            updateLivePhotoIfNeeded()
        }
    }

    func finishContentEditing(completionHandler: @escaping (PHContentEditingOutput?) -> Void) {
        // Update UI to reflect that editing has finished and output is being rendered.

        let output = PHContentEditingOutput(contentEditingInput: input)

        // All this extension needs for resuming edits is a filter name, so that's the adjustment data.
        output.adjustmentData = PHAdjustmentData(
            formatIdentifier: formatIdentifier, formatVersion: formatVersion,
            data: NSKeyedArchiver.archivedData(withRootObject: (selectedFilterName ?? "") as NSString)
        )

        if #available(OSXApplicationExtension 10.12, iOSApplicationExtension 10.0, *), input.livePhoto != nil {
            // PHLivePhotoEditingContext already uses a background queue, so no dispatch
            livePhotoContext.saveLivePhoto(to: output) { success, error in
                if success {
                    completionHandler(output)
                } else {
                    NSLog("can't output live photo")
                    completionHandler(nil)
                }
            }
            return
        }

        // Render and provide output on a background queue.
        DispatchQueue.global(qos: .userInitiated).async {
            switch self.input.mediaType {
                case .image:
                    self.processImage(to: output, completionHandler: completionHandler)
                case .video:
                    self.processVideo(to: output, completionHandler: completionHandler)
                default:
                    NSLog("can't handle media type \(self.input.mediaType)")
                    completionHandler(nil)
            }
        }
    }

    var shouldShowCancelConfirmation: Bool {
        /*
         This extension doesn't involve any major editing, just picking a filter,
         so there's no need to confirm cancellation -- all you lose when canceling 
         is your choice of filter, which you can restore with one click.

         If your extension UI involves lots of adjusting parameters, or "painting"
         edits onto the image like brush strokes, the user doesn't want to lose those
         with a stray tap/click of the Cancel button, so return true if your state
         reflects such invested user effort.
         */
        return false
    }

    func cancelContentEditing() {
        // Nothing to clean up in this extension. If your extension creates temporary 
        // files, etc, destroy them here.
    }

    // MARK: Media processing

    func updateImagePreviews() {
        previewImages = filterNames.map { filterName in

            // Load preview-size image to process from input.
            let inputImage: CIImage
            if input.mediaType == .video {
                guard let avAsset = input.audiovisualAsset
                    else { fatalError("can't get input AV asset") }
                inputImage = avAsset.thumbnailImage
            } else { // mediaType == .photo
                guard let image = input.displaySizeImage
                    else { fatalError("missing input image") }
                guard let ciImage = CIImage(image: image)
                    else { fatalError("can't load input image to apply edit") }
                inputImage = ciImage
            }

            // Define output image with Core Image edits.
            if filterName == wwdcFilter {
                return inputImage.applyingWWDCDemoEffect(shouldWatermark: false)
            } else {
                return inputImage.applyingFilter(filterName, withInputParameters: nil)
            }
        }
    }

    @available(OSXApplicationExtension 10.12, iOSApplicationExtension 10.0, *)
    func updateLivePhotoIfNeeded() {
        if input.livePhoto != nil {
            switch self.selectedFilterName {
                case .some(wwdcFilter):
                    setupWWDCDemoProcessor()
                case .some(let filterName):
                    livePhotoContext.frameProcessor = { frame, _ in
                        return frame.image.applyingFilter(filterName, withInputParameters: nil)
                    }
                default:
                    // Passthru to preview the unedited Live Photo at display size.
                    livePhotoContext.frameProcessor = { frame, _ in
                        return frame.image
                    }
            }
            let size = input.displaySizeImage!.size
            livePhotoContext.prepareLivePhotoForPlayback(withTargetSize: size, options: nil, completionHandler: { livePhoto, error in
                self.delegate.previewLivePhoto = livePhoto
            })
        }
    }

    /// Advanced Live Photo processing shown at WWDC16 session 505
    @available(OSXApplicationExtension 10.12, iOSApplicationExtension 10.0, *)
    func setupWWDCDemoProcessor() {

        /**
         Simple linear ramp to convert frame times
         from the range 0 ... photoTime ... duration)
         to the range -1 ... 0 ... +1
         */
        let photoTime = CMTimeGetSeconds(livePhotoContext.photoTime)
        let duration = CMTimeGetSeconds(livePhotoContext.duration)
        func convertTime(_ time: Float64) -> CGFloat {
            if time < photoTime {
                return CGFloat((time - photoTime) / photoTime)
            } else {
                return CGFloat((time - photoTime) / (duration - photoTime))
            }
        }

        livePhotoContext.frameProcessor = { frame, _ in
            return frame.image.applyingWWDCDemoEffect(
                // Normalized frame time for animating the effect:
                time: convertTime(CMTimeGetSeconds(frame.time)),
                // Scale factor for pixel-size-dependent effects:
                scale: frame.renderScale,
                // Add watermark only to the still photo frame in the Live Photo:
                shouldWatermark: frame.type == .photo)
        }
    }

    func processImage(to output: PHContentEditingOutput, completionHandler: ((PHContentEditingOutput?) -> Void)) {

        // Load full-size image to process from input.
        guard let url = input.fullSizeImageURL
            else { fatalError("missing input image url") }
        guard let inputImage = CIImage(contentsOf: url)
            else { fatalError("can't load input image to apply edit") }

        // Define output image with Core Image edits.
        let orientedImage = inputImage.applyingOrientation(input.fullSizeImageOrientation)
        let outputImage: CIImage
        switch selectedFilterName {
            case .some(wwdcFilter):
                outputImage = orientedImage.applyingWWDCDemoEffect()
            case .some(let filterName):
                outputImage = orientedImage.applyingFilter(filterName, withInputParameters: nil)
            default:
                outputImage = orientedImage
        }

        // Usually you want to create a CIContext early and reuse it, but
        // this extension uses one (explicitly) only on exit.
        let context = CIContext()
        // Render the filtered image to the expected output URL.
        if #available(OSXApplicationExtension 10.12, iOSApplicationExtension 10.0, *) {
            // Use Core Image convenience method to write JPEG where supported.
            do {
                try context.writeJPEGRepresentation(of: outputImage, to: output.renderedContentURL, colorSpace: inputImage.colorSpace!)
                completionHandler(output)
            } catch let error {
                NSLog("can't write image: \(error)")
                completionHandler(nil)
            }
        } else {
            // Use CGImageDestination to write JPEG in older OS.
            guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
                else { fatalError("can't create CGImage") }
            guard let destination = CGImageDestinationCreateWithURL(output.renderedContentURL as CFURL, kUTTypeJPEG, 1, nil)
                else { fatalError("can't create CGImageDestination") }
            CGImageDestinationAddImage(destination, cgImage, nil)
            let success = CGImageDestinationFinalize(destination)
            if success {
                completionHandler(output)
            } else {
                completionHandler(nil)
            }
        }

    }

    func processVideo(to output: PHContentEditingOutput, completionHandler: @escaping ((PHContentEditingOutput?) -> Void)) {

        // Load AVAsset to process from input.
        guard let avAsset = input.audiovisualAsset
            else { fatalError("can't get input AV asset") }
        let duration = CMTimeGetSeconds(avAsset.duration)

        // Set up a video composition to apply the filter.
        let composition = AVVideoComposition(
            asset: avAsset,
            applyingCIFiltersWithHandler: { request in
                let filtered: CIImage
                switch self.selectedFilterName {
                    case .some(self.wwdcFilter):
                        let frameTime = CGFloat(CMTimeGetSeconds(request.compositionTime) / duration)
                        filtered = request.sourceImage.applyingWWDCDemoEffect(time: frameTime)
                    case .some(let filterName):
                        filtered = request.sourceImage.applyingFilter(filterName, withInputParameters: nil)
                    default:
                        filtered = request.sourceImage // Passthru if no filter is selected
                }
                request.finish(with: filtered, context: nil)
        })

        // Write the processed asset to the output URL.
        guard let export = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetHighestQuality)
            else { fatalError("can't set up AV export session") }

        export.outputFileType = AVFileTypeQuickTimeMovie
        export.outputURL = output.renderedContentURL
        export.videoComposition = composition
        export.exportAsynchronously {
            completionHandler(output)
        }
    }

}

private extension CIImage {

    func applyingWWDCDemoEffect(time: CGFloat = 0, scale: CGFloat = 1, shouldWatermark: Bool = true) -> CIImage {

        // Demo step 1: Crop to square, animating crop position.
        let length = min(extent.width, extent.height)
        let cropOrigin = CGPoint(x: (1 + time) * (extent.width - length) / 2,
                                 y: (1 + time) * (extent.height - length) / 2)
        let cropRect = CGRect(origin: cropOrigin,
                              size: CGSize(width: length, height: length))
        let cropped = self.cropping(to: cropRect)

        // Demo step 2: Add vignette effect.
        let vignetted = cropped.applyingFilter("CIVignetteEffect", withInputParameters:
            [ kCIInputCenterKey: CIVector(x: cropped.extent.midX, y: cropped.extent.midY),
              kCIInputRadiusKey: length * CGFloat(M_SQRT1_2),
              ])

        // Demo step 3: Add line screen effect.
        let screen = vignetted.applyingFilter("CILineScreen", withInputParameters:
            [ kCIInputAngleKey : CGFloat.pi * 3/4,
              kCIInputCenterKey : CIVector(x: vignetted.extent.midX, y: vignetted.extent.midY),
              kCIInputWidthKey : 50 * scale
            ])
        let screened = screen.applyingFilter("CIMultiplyCompositing", withInputParameters: [kCIInputBackgroundImageKey: self])

        // Demo step 5: Add watermark if desired.
        if shouldWatermark {
            // Scale logo to rendering resolution and position it for compositing.
            let logoWidth = ContentEditingController.wwdcLogo.extent.width
            let logoScale = screened.extent.width * 0.7 / logoWidth
            let scaledLogo = ContentEditingController.wwdcLogo
                .applying(CGAffineTransform(scaleX: logoScale, y: logoScale))
            let logo = scaledLogo
                .applying(CGAffineTransform(translationX: screened.extent.minX + (screened.extent.width - scaledLogo.extent.width) / 2, y: screened.extent.minY + scaledLogo.extent.height))
            // Composite logo over the main image.
            return logo.applyingFilter("CILinearDodgeBlendMode", withInputParameters: [kCIInputBackgroundImageKey: screened])
        } else {
            return screened
        }
    }

#if os(OSX)
    // CIImage.init(NSImage) is missing from Swift in the WWDC seed.
    // Use this extension as a temporary workaround.
    convenience init?(image: NSImage) {
        guard let imageRep = image.representations.first as? NSBitmapImageRep
            else { return nil }
        guard let cgImage = imageRep.cgImage
            else { return nil }
        self.init(cgImage: cgImage)
    }
#endif
}

private extension AVAsset {
    var thumbnailImage: CIImage {
        let imageGenerator = AVAssetImageGenerator(asset: self)
        imageGenerator.appliesPreferredTrackTransform = true

        let cgImage = try! imageGenerator.copyCGImage(at: CMTime(seconds: 0, preferredTimescale: 30), actualTime: nil)
        return CIImage(cgImage: cgImage)
    }
}
