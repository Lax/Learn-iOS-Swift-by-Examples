/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A view controller that demonstrates how to use UISlider.
            
*/

import UIKit

class SliderViewController: UITableViewController {
    // MARK: Properties

    @IBOutlet weak var defaultSlider: UISlider!

    @IBOutlet weak var tintedSlider: UISlider!
    
    @IBOutlet weak var customSlider: UISlider!

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureDefaultSlider()
        configureTintedSlider()
        configureCustomSlider()
    }

    // MARK: Configuration

    func configureDefaultSlider() {
        defaultSlider.minimumValue = 0
        defaultSlider.maximumValue = 100
        defaultSlider.value = 42
        defaultSlider.continuous = true

        defaultSlider.addTarget(self, action: "sliderValueDidChange:", forControlEvents: .ValueChanged)
    }

    func configureTintedSlider() {
        tintedSlider.minimumTrackTintColor = UIColor.applicationBlueColor()
        tintedSlider.maximumTrackTintColor = UIColor.applicationPurpleColor()

        tintedSlider.addTarget(self, action: "sliderValueDidChange:", forControlEvents: .ValueChanged)
    }

    func configureCustomSlider() {
        let leftTrackImage = UIImage(named: "slider_blue_track")
        customSlider.setMinimumTrackImage(leftTrackImage, forState: .Normal)

        let rightTrackImage = UIImage(named: "slider_green_track")
        customSlider.setMaximumTrackImage(rightTrackImage, forState: .Normal)

        let thumbImage = UIImage(named: "slider_thumb")
        customSlider.setThumbImage(thumbImage, forState: .Normal)

        customSlider.minimumValue = 0
        customSlider.maximumValue = 100
        customSlider.continuous = false
        customSlider.value = 84

        customSlider.addTarget(self, action: "sliderValueDidChange:", forControlEvents: .ValueChanged)
    }

    // MARK: Actions

    func sliderValueDidChange(slider: UISlider) {
        NSLog("A slider changed its value: \(slider).")
    }
}
