/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Export transcodes the contents of a given asset to create an output of the form specified by the export preset.
 */

import Foundation
import AVFoundation
import Photos

// Protocol for exporting that conforming types must implement.
protocol APLExportStatus {
    func updateProgress(_ timer: Timer)
    func exportCompleted()
}

class APLExport {

    /// The export session object used to transcode the contents of a given asset to create an output of the form specified by the export preset.
    private var exportSession: AVAssetExportSession

    /// The progress view.
    weak var controller: APLViewController?

    // The progress timer used to inform the client of the export progress.
    fileprivate var progressTimer: Timer?

    init?(_ composition: AVMutableComposition, videoComposition: AVMutableVideoComposition, presetName: String, controller: APLViewController) {

        // Create an export session using the given asset and preset.
        guard let session = AVAssetExportSession(asset: composition, presetName: presetName) else { return nil }
        session.videoComposition = videoComposition

        exportSession = session

        self.controller = controller
    }

    // Called when the export operation has completed.
    private func exportCompleted() {

        guard let outputURL = exportSession.outputURL else { return }

        guard let progressTimer = progressTimer else { return }
        progressTimer.invalidate()

        if exportSession.status != AVAssetExportSessionStatus.completed {
            if let error = exportSession.error { print("An export error occurred: \(error.localizedDescription)") }
            return
        }

        /*
         Save the exported movie to the camera roll.
         Check authorization status.
         */
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                // Save the movie file to the photo library and cleanup.
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = true
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .video, fileURL: outputURL, options: options)
                }, completionHandler: { success, error in
                    if !success {
                        guard let theError = error else { return }
                        print("An export error occurred: \(theError.localizedDescription)")
                        return
                    }
                }
                )
            } else {
                print("Not authorized to save movie to the camera roll.")
                return
            }
        }
    }

    func export() {
        
        // Remove the file if it already exists.
        let filePath = NSTemporaryDirectory().appending("ExportedProject.mov")
        let fileExists = FileManager.default.fileExists(atPath: filePath)
        if fileExists {
            do {
                try FileManager.default.removeItem(atPath: filePath)
            } catch {
                print("An error occured deleting the file: \(error)")
            }
        }

        /*
         If a preset that is not compatible with AVFileTypeQuickTimeMovie is used, one can use
         -[AVAssetExportSession supportedFileTypes] to obtain a supported file type for the output
         file and UTTypeCreatePreferredIdentifierForTag to obtain an appropriate path extension for
         the output file type.
         */

        exportSession.outputURL = URL(fileURLWithPath: filePath)
        exportSession.outputFileType = AVFileTypeQuickTimeMovie

        exportSession.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {

                self.exportCompleted()

                guard let theController = self.controller else { return }
                theController.exportCompleted()
            }
        })

        guard let theController = self.controller else { return }

        // Update progress view with export progress.
        progressTimer =
            Timer(timeInterval: 0.5, target: theController,
                  selector: #selector(theController.updateProgress(_:)), userInfo: exportSession, repeats: true)
    }

}
