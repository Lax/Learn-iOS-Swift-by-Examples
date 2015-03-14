/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to use UIStepper.
*/

import UIKit

class StepperViewController: UITableViewController {
    // MARK: Properties

    @IBOutlet weak var defaultStepper: UIStepper!

    @IBOutlet weak var tintedStepper: UIStepper!
    
    @IBOutlet weak var customStepper: UIStepper!

    @IBOutlet weak var defaultStepperLabel: UILabel!
    
    @IBOutlet weak var tintedStepperLabel: UILabel!
    
    @IBOutlet weak var customStepperLabel: UILabel!

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureDefaultStepper()
        configureTintedStepper()
        configureCustomStepper()
    }

    // MARK: Configuration

    func configureDefaultStepper() {
        defaultStepper.value = 0
        defaultStepper.minimumValue = 0
        defaultStepper.maximumValue = 10
        defaultStepper.stepValue = 1

        defaultStepperLabel.text = "\(Int(defaultStepper.value))"
        defaultStepper.addTarget(self, action: "stepperValueDidChange:", forControlEvents: .ValueChanged)
    }

    func configureTintedStepper() {
        tintedStepper.tintColor = UIColor.applicationBlueColor()

        tintedStepperLabel.text = "\(Int(tintedStepper.value))"
        tintedStepper.addTarget(self, action: "stepperValueDidChange:", forControlEvents: .ValueChanged)
    }

    func configureCustomStepper() {
        // Set the background image.
        let stepperBackgroundImage = UIImage(named: "stepper_and_segment_background")
        customStepper.setBackgroundImage(stepperBackgroundImage, forState: .Normal)

        let stepperHighlightedBackgroundImage = UIImage(named: "stepper_and_segment_background_highlighted")
        customStepper.setBackgroundImage(stepperHighlightedBackgroundImage, forState: .Highlighted)

        let stepperDisabledBackgroundImage = UIImage(named: "stepper_and_segment_background_disabled")
        customStepper.setBackgroundImage(stepperDisabledBackgroundImage, forState: .Disabled)

        // Set the image which will be painted in between the two stepper segments (depends on the states of both segments).
        let stepperSegmentDividerImage = UIImage(named: "stepper_and_segment_divider")
        customStepper.setDividerImage(stepperSegmentDividerImage, forLeftSegmentState: .Normal, rightSegmentState: .Normal)

        // Set the image for the + button.
        let stepperIncrementImage = UIImage(named: "stepper_increment")
        customStepper.setIncrementImage(stepperIncrementImage, forState: .Normal)

        // Set the image for the - button.
        let stepperDecrementImage = UIImage(named: "stepper_decrement")
        customStepper.setDecrementImage(stepperDecrementImage, forState: .Normal)

        customStepperLabel.text = "\(Int(customStepper.value))"
        customStepper.addTarget(self, action: "stepperValueDidChange:", forControlEvents: .ValueChanged)
    }

    // MARK: Actions

    func stepperValueDidChange(stepper: UIStepper) {
        NSLog("A stepper changed its value: \(stepper).")

        // A mapping from a stepper to its associated label.
        let stepperMapping: [UIStepper: UILabel] = [
            defaultStepper: defaultStepperLabel,
            tintedStepper: tintedStepperLabel,
            customStepper: customStepperLabel
        ]

        stepperMapping[stepper]!.text = "\(Int(stepper.value))"
    }
}
