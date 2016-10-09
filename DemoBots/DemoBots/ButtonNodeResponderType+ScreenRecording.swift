/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A protocol extension that adds methods to `ButtonNodeResponderType` to enable screen recording with ReplayKit.
*/

import ReplayKit


/// The `NSUserDefaults` key used to store whether screen recording has been enabled.
let screenRecorderEnabledKey = "AppConfiguration.Defaults.screenRecorderEnabledKey"

/*
    Extend `ButtonNodeResponderType` to add methods for screen recording with ReplayKit.
    The type constraint ensures that only types that are `BaseScene` instances will
    get this additional functionality.
*/
extension ButtonNodeResponderType where Self: BaseScene {
    func toggleScreenRecording(button: ButtonNode) {

        button.isSelected = !button.isSelected
        
        UserDefaults.standard.set(button.isSelected, forKey: screenRecorderEnabledKey)
    }
    
    func displayRecordedContent() {
        guard let previewViewController = previewViewController else { fatalError("The user requested playback, but a valid preview controller does not exist.") }
        guard let rootViewController = view?.window?.rootViewController else { fatalError("The scene must be contained in a window with a root view controller.") }
        
        // `RPPreviewViewController` only supports full screen modal presentation.
        previewViewController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        
        rootViewController.present(previewViewController, animated: true, completion:nil)
    }
}
