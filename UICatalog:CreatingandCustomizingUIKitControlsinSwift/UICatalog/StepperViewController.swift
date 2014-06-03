/*
        File: StepperViewController.swift
    Abstract: 
                A view controller that demonstrates how to use UIStepper.
            
     Version: 1.0
    
    Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
    Inc. ("Apple") in consideration of your agreement to the following
    terms, and your use, installation, modification or redistribution of
    this Apple software constitutes acceptance of these terms.  If you do
    not agree with these terms, please do not use, install, modify or
    redistribute this Apple software.
    
    In consideration of your agreement to abide by the following terms, and
    subject to these terms, Apple grants you a personal, non-exclusive
    license, under Apple's copyrights in this original Apple software (the
    "Apple Software"), to use, reproduce, modify and redistribute the Apple
    Software, with or without modifications, in source and/or binary forms;
    provided that if you redistribute the Apple Software in its entirety and
    without modifications, you must retain this notice and the following
    text and disclaimers in all such redistributions of the Apple Software.
    Neither the name, trademarks, service marks or logos of Apple Inc. may
    be used to endorse or promote products derived from the Apple Software
    without specific prior written permission from Apple.  Except as
    expressly stated in this notice, no other rights or licenses, express or
    implied, are granted by Apple herein, including but not limited to any
    patent rights that may be infringed by your derivative works or by other
    works in which the Apple Software may be incorporated.
    
    The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
    MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
    THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
    OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
    
    IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
    OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
    MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
    AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
    STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
    
    Copyright (C) 2014 Apple Inc. All Rights Reserved.

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
