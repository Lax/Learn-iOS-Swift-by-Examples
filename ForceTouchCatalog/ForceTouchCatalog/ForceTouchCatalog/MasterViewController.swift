/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    View controller for the Master tab. Example of how to manually perform haptic feedback.
*/

import Cocoa

class MasterViewController: NSViewController {
    @IBOutlet weak var rotateableImage: NSImageView!
    
    @IBAction func sliderValueChanged(sender: NSSlider) {
        let rotationValue = CGFloat(sender.integerValue)
        rotateableImage.frameCenterRotation = rotationValue
        
        if rotationValue == 0 {
            NSHapticFeedbackManager.defaultPerformer().performFeedbackPattern(.Alignment, performanceTime: .Default)
        }
    }
}