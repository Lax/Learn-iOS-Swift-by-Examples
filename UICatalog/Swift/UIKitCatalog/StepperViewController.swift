/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to use UIStepper.
*/

import UIKit

class StepperViewController: UITableViewController {
    // MARK: - Properties

    @IBOutlet weak var defaultStepper: UIStepper!

    @IBOutlet weak var tintedStepper: UIStepper!
    
    @IBOutlet weak var customStepper: UIStepper!

    @IBOutlet weak var defaultStepperLabel: UILabel!
    
    @IBOutlet weak var tintedStepperLabel: UILabel!
    
    @IBOutlet weak var customStepperLabel: UILabel!

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureDefaultStepper()
        configureTintedStepper()
        configureCustomStepper()
    }

    // MARK: - Configuration

    func configureDefaultStepper() {
        defaultStepper.value = 0
        defaultStepper.minimumValue = 0
        defaultStepper.maximumValue = 10
        defaultStepper.stepValue = 1

        defaultStepperLabel.text = "\(Int(defaultStepper.value))"
        defaultStepper.addTarget(self, action: #selector(StepperViewController.stepperValueDidChange(_:)), for: .valueChanged)
    }

    func configureTintedStepper() {
        tintedStepper.tintColor = UIColor.applicationBlueColor

        tintedStepperLabel.text = "\(Int(tintedStepper.value))"
        tintedStepper.addTarget(self, action: #selector(StepperViewController.stepperValueDidChange(_:)), for: .valueChanged)
    }

    func configureCustomStepper() {
        // Set the background image.
        let stepperBackgroundImage = UIImage(named: "stepper_and_segment_background")
        customStepper.setBackgroundImage(stepperBackgroundImage, for: UIControlState())

        let stepperHighlightedBackgroundImage = UIImage(named: "stepper_and_segment_background_highlighted")
        customStepper.setBackgroundImage(stepperHighlightedBackgroundImage, for: .highlighted)

        let stepperDisabledBackgroundImage = UIImage(named: "stepper_and_segment_background_disabled")
        customStepper.setBackgroundImage(stepperDisabledBackgroundImage, for: .disabled)

        /*
            Set the image which will be painted in between the two stepper segments
            (depends on the states of both segments).
        */
        let stepperSegmentDividerImage = UIImage(named: "stepper_and_segment_divider")
        customStepper.setDividerImage(stepperSegmentDividerImage, forLeftSegmentState: UIControlState(), rightSegmentState: UIControlState())

        // Set the image for the + button.
        let stepperIncrementImage = UIImage(named: "stepper_increment")
        customStepper.setIncrementImage(stepperIncrementImage, for: UIControlState())

        // Set the image for the - button.
        let stepperDecrementImage = UIImage(named: "stepper_decrement")
        customStepper.setDecrementImage(stepperDecrementImage, for: UIControlState())

        customStepperLabel.text = "\(Int(customStepper.value))"
        customStepper.addTarget(self, action: #selector(StepperViewController.stepperValueDidChange(_:)), for: .valueChanged)
    }

    // MARK: - Actions

    func stepperValueDidChange(_ stepper: UIStepper) {
        NSLog("A stepper changed its value: \(stepper).")

        // A mapping from a stepper to its associated label.
        let stepperMapping = [
            defaultStepper: defaultStepperLabel,
            tintedStepper: tintedStepperLabel,
            customStepper: customStepperLabel
        ]

        stepperMapping[stepper]!?.text = "\(Int(stepper.value))"
    }
}
