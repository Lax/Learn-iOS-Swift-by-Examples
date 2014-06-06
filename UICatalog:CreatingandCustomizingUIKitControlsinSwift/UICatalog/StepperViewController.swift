/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A view controller that demonstrates how to use UIStepper.
            
*/

import UIKit

class StepperViewController: UITableViewController {
    // MARK: Properties

    @IBOutlet var defaultStepper: UIStepper
    @IBOutlet var tintedStepper: UIStepper
    @IBOutlet var customStepper: UIStepper

    @IBOutlet var defaultStepperLabel: UILabel
    @IBOutlet var tintedStepperLabel: UILabel
    @IBOutlet var customStepperLabel: UILabel

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
        customStepper.setBackgroundImage(UIImage(named: "stepper_and_segment_background"), forState: .Normal)
        customStepper.setBackgroundImage(UIImage(named: "stepper_and_segment_background_highlighted"), forState: .Highlighted)
        customStepper.setBackgroundImage(UIImage(named: "stepper_and_segment_background_disabled"), forState: .Disabled)

        // Set the image which will be painted in between the two stepper segments (depends on the states of both segments).
        customStepper.setDividerImage(UIImage(named: "stepper_and_segment_divider"), forLeftSegmentState: .Normal, rightSegmentState: .Normal)

        // Set the image for the + button.
        customStepper.setIncrementImage(UIImage(named: "stepper_increment"), forState: .Normal)

        // Set the image for the - button.
        customStepper.setDecrementImage(UIImage(named: "stepper_decrement"), forState: .Normal)

        customStepperLabel.text = "\(Int(customStepper.value))"
        customStepper.addTarget(self, action: "stepperValueDidChange:", forControlEvents: .ValueChanged)
    }

    // MARK: Actions

    func stepperValueDidChange(stepper: UIStepper) {
        NSLog("A stepper changed its value: \(stepper).")

        // A mapping from a stepper to its associated label.
        let stepperMapping: Dictionary<UIStepper, UILabel> = [
            defaultStepper: defaultStepperLabel,
            tintedStepper: tintedStepperLabel,
            customStepper: customStepperLabel
        ]

        stepperMapping[stepper]!.text = "\(Int(stepper.value))"
    }
}
