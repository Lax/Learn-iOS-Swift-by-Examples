/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	View controller which controls simulating an call
*/

import UIKit

class SimulateIncomingCallViewController: UIViewController {

    @IBOutlet private weak var destinationTextField: UITextField!
    @IBOutlet private weak var doneButton: UIBarButtonItem!
    @IBOutlet private weak var videoSwitch: UISwitch!
    @IBOutlet private weak var videoSwitchLabel: UILabel!
    @IBOutlet private weak var delayStepper: UIStepper!
    @IBOutlet private weak var delayStepperLabel: UILabel!
    @IBOutlet private weak var delayExplanationLabel: UILabel!

    private let delayLabelTextFormat = NSLocalizedString("CALL_DELAY_STEPPER_LABEL", comment: "Label for simulating delayed incoming call switch")

    private struct DefaultsKeys {
        static let IncomingCallDelayInSecondsKey = "IncomingCallDelayInSecondsKey"
        static let IncomingCallHandleKey = "IncomingCallHandleKey"
        static let IncomingCallVideoCallKey = "IncomingCallVideoCallKey"
    }

    var handle: String? {
        return destinationTextField.text
    }

    var delay: TimeInterval {
        return delayStepper.value
    }

    var video: Bool {
        return videoSwitch.isOn
    }

    // MARK: Actions

    @IBAction func cancel(_ cancel: UIBarButtonItem?) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: Helpers

    private func updateDialButton() {
        guard let handle = handle else {
            doneButton?.isEnabled = false
            return
        }

        doneButton?.isEnabled = !handle.isEmpty
    }

    private func updateDelayStepperLabelText() {
        let delayInSeconds = delayStepper.value
        let delayLabelText = String(format: delayLabelTextFormat, delayInSeconds)

        delayStepperLabel.text = delayLabelText
    }

    private func restoreValues() {
        let defaults = UserDefaults.standard

        destinationTextField.text = defaults.string(forKey: DefaultsKeys.IncomingCallHandleKey)

        delayStepper.value = defaults.double(forKey: DefaultsKeys.IncomingCallDelayInSecondsKey)
        updateDelayStepperLabelText()

        videoSwitch.isOn = defaults.bool(forKey: DefaultsKeys.IncomingCallVideoCallKey)

        updateDialButton()
    }

    private func saveValues() {
        let defaults = UserDefaults.standard

        defaults.set(destinationTextField.text, forKey: DefaultsKeys.IncomingCallHandleKey)
        defaults.set(videoSwitch.isOn, forKey: DefaultsKeys.IncomingCallVideoCallKey)
        defaults.set(delayStepper.value, forKey: DefaultsKeys.IncomingCallDelayInSecondsKey)
    }

    // MARK: Observers

    func textFieldDidChange(textField: UITextField?) {
        updateDialButton()
    }

    @IBAction func stepperValueChanged(_ sender: AnyObject) {
        updateDelayStepperLabelText()
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.prompt = NSLocalizedString("SIMULATE_INCOMING_CALL_NAVIGATION_PROMPT", comment: "Navigation item prompt for Incoming call options UI")
        videoSwitchLabel.text = NSLocalizedString("CALL_VIDEO_SWITCH_LABEL", comment: "Label for simulating incoming video call switch")
        delayExplanationLabel.text = NSLocalizedString("DELAY_EXPLANATION_LABEL", comment: "Label for explaining delay stepper usage")
        destinationTextField.addTarget(self, action: #selector(textFieldDidChange), for: [.editingChanged])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        destinationTextField?.becomeFirstResponder()

        restoreValues()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        saveValues()
    }

}
