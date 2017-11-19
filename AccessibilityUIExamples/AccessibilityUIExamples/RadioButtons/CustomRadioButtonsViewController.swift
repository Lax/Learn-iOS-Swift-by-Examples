/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller demonstrating accessibility provided by AppKit for NSButton.
*/

import Cocoa

class CustomRadioButtonsViewController: NSViewController {

    // MARK: - View Controller Lifecycle
    @IBOutlet var currentValueLabel: NSTextField!
    @IBOutlet var customRadios: CustomRadioButtonsView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Allow the CustomButtonView to call our own action function.
        customRadios.actionHandler = { self.changeRadioValue(self) }
    }
    
    @IBAction func changeRadioValue(_ sender: Any) {
       currentValueLabel.stringValue = NSString(format: "(Radio selected = %ld)", customRadios.selectedButton + 1) as String
    }
}

