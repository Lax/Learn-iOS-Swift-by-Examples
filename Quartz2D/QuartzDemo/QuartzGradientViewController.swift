/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UIViewController subclass that manages a QuartzGradientView and a UI to allow for the selection of gradient type and if the gradient extends past its start or end point.
 */

import UIKit

class QuartzGradientViewController: UIViewController {

    @IBOutlet weak var quartzGradientView: QuartzGradientView!

    @IBOutlet weak var gradientTypeSegmentedControl: UISegmentedControl!

    @IBOutlet weak var extendsPastStartSwitch: UISwitch!

    @IBOutlet weak var extendsPastEndSwitch: UISwitch!


    override func viewDidLoad() {
        super.viewDidLoad()

        self.quartzGradientView.gradientTypeToDisplay = QuartzGradientView.GradientType(rawValue: self.gradientTypeSegmentedControl.selectedSegmentIndex)!
        self.quartzGradientView.extendsPastStart = self.extendsPastStartSwitch.isOn
        self.quartzGradientView.extendsPastEnd = self.extendsPastEndSwitch.isOn
    }



    @IBAction func takeGradientTypeFrom(_ sender: UISegmentedControl) {
        self.quartzGradientView.gradientTypeToDisplay = QuartzGradientView.GradientType(rawValue: self.gradientTypeSegmentedControl.selectedSegmentIndex)!
    }



    @IBAction func takeExtendsPastStartFrom(_ sender: UISegmentedControl) {
        self.quartzGradientView.extendsPastStart = self.extendsPastStartSwitch.isOn
    }



    @IBAction func takeExtendsPastEndFrom(_ sender: UISlider) {
        self.quartzGradientView.extendsPastEnd = self.extendsPastEndSwitch.isOn
    }

}





