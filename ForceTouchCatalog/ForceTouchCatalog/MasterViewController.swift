/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    View controller for the Master tab. Example of how to manually perform haptic feedback.
*/

import Cocoa

class MasterViewController: NSViewController {
    @IBOutlet weak var rotatableImage: NSImageView!
    
    @IBAction func sliderValueChanged(_ sender: NSSlider) {
        let rotationValue = CGFloat(sender.integerValue)
        rotatableImage.frameCenterRotation = rotationValue

        guard rotationValue == 0 else { return }

        /*
            Use the `NSHapticFeedbackManager` class to perform alignment haptic
            feedback on the Force Touch trackpad.
            
            Note: You can call this even if this Macintosh doesn't have a Force
            Touch Trackpad Haptic feedback should be used sparingly. Here we are
            performing it when the user aligns the photo to 0 degrees. A more
            real world example would be when the user aligns the photo to when 
            the horizon is level.
            
            Ideally, the velocity of slider value changes would be considered such
            that haptic feedback is only performed when the user is trying to find
            the alignment point (aka moving slowly). This is left as an exercise
            for the reader.
        */
        NSHapticFeedbackManager.defaultPerformer().perform(.alignment, performanceTime: .default)
    }
}
