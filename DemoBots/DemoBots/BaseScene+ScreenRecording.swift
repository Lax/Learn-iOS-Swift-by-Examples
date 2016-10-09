/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An extension on `BaseScene` to manage the recording of a level's gameplay with `ReplayKit`. This extension is only included in the iOS version of the project.
*/

import ReplayKit

extension BaseScene: RPPreviewViewControllerDelegate, RPScreenRecorderDelegate {
    // MARK: Computed Properties
    
    var screenRecordingToggleEnabled: Bool {
        return UserDefaults.standard.bool(forKey: screenRecorderEnabledKey)
    }
    
    // MARK: Start/Stop Screen Recording
    
    func startScreenRecording() {
        // Do nothing if screen recording hasn't been enabled.
        guard screenRecordingToggleEnabled else { return }
        
        let sharedRecorder = RPScreenRecorder.shared()
        
        // Register as the recorder's delegate to handle errors.
        sharedRecorder.delegate = self
        
        sharedRecorder.startRecording() { error in
            if let error = error {
                self.showScreenRecordingAlert(message: error.localizedDescription)
            }
        }
    }
    
    func stopScreenRecording(withHandler handler:@escaping (() -> Void)) {
        let sharedRecorder = RPScreenRecorder.shared()

        sharedRecorder.stopRecording { previewViewController, error in
            if let error = error {
                // If an error has occurred, display an alert to the user.
                self.showScreenRecordingAlert(message: error.localizedDescription)
                return
            }
            
            if let previewViewController = previewViewController {
                // Set delegate to handle view controller dismissal.
                previewViewController.previewControllerDelegate = self
                
                /*
                    Keep a reference to the `previewViewController` to
                    present when the user presses on preview button.
                */
                self.previewViewController = previewViewController
            }
    
            handler()
        }
    }
    
    func showScreenRecordingAlert(message: String) {
        // Pause the scene and un-pause after the alert returns.
        isPaused = true
        
        // Show an alert notifying the user that there was an issue with starting or stopping the recorder.
        let alertController = UIAlertController(title: "ReplayKit Error", message: message, preferredStyle: .alert)
        
        let alertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.`default`) { _ in
            self.isPaused = false
        }
        alertController.addAction(alertAction)
        
        /*
            `ReplayKit` event handlers may be called on a background queue. Ensure
            this alert is presented on the main queue.
        */
        DispatchQueue.main.async() {
            self.view?.window?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    func discardRecording() {
        // When we no longer need the `previewViewController`, tell `ReplayKit` to discard the recording and nil out our reference
        RPScreenRecorder.shared().discardRecording {
            self.previewViewController = nil
        }
    }
    
    // MARK: RPScreenRecorderDelegate
    
    func screenRecorder(_ screenRecorder: RPScreenRecorder, didStopRecordingWithError error: Error, previewViewController: RPPreviewViewController?) {
        // Display the error the user to alert them that the recording failed.
        showScreenRecordingAlert(message: error.localizedDescription)
        
        /// Hold onto a reference of the `previewViewController` if not nil.
        if previewViewController != nil {
            self.previewViewController = previewViewController
        }
    }
    
    // MARK: RPPreviewViewControllerDelegate
    
    func previewControllerDidFinish(previewController: RPPreviewViewController) {
        previewViewController?.dismiss(animated: true, completion: nil)
    }
}
