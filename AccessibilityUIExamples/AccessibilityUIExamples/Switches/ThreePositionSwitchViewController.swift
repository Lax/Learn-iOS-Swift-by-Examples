/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller demonstrating an accessible, custom three-position switch.
*/

import Cocoa

class ThreePositionSwitchViewController: NSViewController {

    @IBOutlet var currentValueLabel: NSTextField!
    @IBOutlet var threePositionSwitch: ThreePositionSwitchView!
    
    // MARK: - Actions
    
    @IBAction func changeSwitchValue(_ sender: Any) {
        if let senderSwitch = sender as? ThreePositionSwitchView,
            let description = senderSwitch.accessibilityValue() as? String {
                currentValueLabel.stringValue = description.uppercased()
        }
    }
    
}

