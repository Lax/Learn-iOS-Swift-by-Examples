/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    View controller for the Squire tab. Examples of high-level Force Touch API. Force Touch and spring loaded Buttons
*/

import Cocoa

class SquireViewController: NSViewController {
    @IBOutlet weak var nextPhotoButton: NSButton!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var pressureIndicator: NSLevelIndicator!
    @IBOutlet weak var levelIndicator: NSLevelIndicator!

    static let imageBaseName = "Lola"
    static let maxPhotoIndex = 4

    var photoIndex = 1

    override func viewDidLoad() {
        super.viewDidLoad()

        /*
            This is how you manually set a continuous accelerator button.
            The other buttons are set in the IB Attributes Inspector for that button.
        */
        nextPhotoButton.setButtonType(.AcceleratorButton)
        nextPhotoButton.continuous = true
    }
    
    func nextPhotoName() -> String {
        photoIndex++
        if photoIndex > SquireViewController.maxPhotoIndex {
            photoIndex = 1
        }
        
        return "\(SquireViewController.imageBaseName)\(photoIndex)"
    }

    @IBAction func nextPhotoAction(sender: NSButton) {
        var startFrame = imageView.frame
        let nextPhoto = NSImage(named: nextPhotoName())
        startFrame.origin.x = -startFrame.size.width
        let newImageView = NSImageView(frame: startFrame)
        newImageView.image = nextPhoto
        
        view.addSubview(newImageView)
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            newImageView.animator().frame = self.imageView.frame
        }, completionHandler: {
            self.imageView.image = nextPhoto
            newImageView.removeFromSuperviewWithoutNeedingDisplay()
        })
    }
    
    @IBAction func acceleratorChanged(sender: NSButton) {
        if sender.doubleValue >= 1 {
            pressureIndicator.integerValue = Int((sender.doubleValue - 1.0) * 1000.0)
        } else {
            pressureIndicator.integerValue = 0
        }
    }
    
    @IBAction func multiLevelAcceleratorChanged(sender: NSButton) {
        levelIndicator.integerValue = sender.integerValue
    }
    
    @IBAction func beepAction(sender: NSButton) {
        NSBeep()
    }
    
}


