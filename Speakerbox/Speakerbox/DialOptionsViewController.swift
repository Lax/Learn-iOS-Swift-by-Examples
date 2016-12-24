/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	View controller which controls dialing an outgoing call
*/

import UIKit

class DialOptionsViewController: UIViewController {

    @IBOutlet private weak var destinationTextField: UITextField!
    @IBOutlet private weak var dialButton: UIBarButtonItem!
    @IBOutlet private weak var videoSwitch: UISwitch!
    @IBOutlet private weak var videoSwitchLabel: UILabel!

    private struct DefaultsKeys {
        static let OutgoingCallHandleKey = "OutgoingCallHandleKey"
        static let OutgoingCallVideoCallKey = "OutgoingCallVideoCallKey"
    }

    var handle: String? {
        return destinationTextField.text
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
            dialButton.isEnabled = false
            return
        }

        dialButton.isEnabled = !handle.isEmpty
    }

    private func restoreValues() {
        let defaults = UserDefaults.standard

        destinationTextField.text = defaults.string(forKey: DefaultsKeys.OutgoingCallHandleKey)
        videoSwitch.isOn = defaults.bool(forKey: DefaultsKeys.OutgoingCallVideoCallKey)

        updateDialButton()
    }

    private func saveValues() {
        let defaults = UserDefaults.standard

        defaults.set(destinationTextField.text, forKey: DefaultsKeys.OutgoingCallHandleKey)
        defaults.set(videoSwitch.isOn, forKey: DefaultsKeys.OutgoingCallVideoCallKey)
    }

    // MARK: Observers

    func textFieldDidChange(textField: UITextField?) {
        updateDialButton()
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.prompt = NSLocalizedString("DIAL_OPTIONS_NAVIGATION_PROMPT", comment: "Navigation item prompt for Dial options UI")
        videoSwitchLabel.text = NSLocalizedString("CALL_VIDEO_SWITCH_LABEL", comment: "Label for simulating outgoing video call switch")

        updateDialButton()

        destinationTextField.addTarget(self, action: #selector(textFieldDidChange), for: [.editingChanged])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        destinationTextField.becomeFirstResponder()

        restoreValues()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        saveValues()
    }

}
