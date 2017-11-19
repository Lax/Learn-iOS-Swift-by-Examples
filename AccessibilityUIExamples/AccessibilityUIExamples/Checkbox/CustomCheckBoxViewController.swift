/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller demonstrating accessibility provided by AppKit for NSButton.
*/

import Cocoa

class CustomCheckBoxViewController: NSViewController {

    // MARK: - View Controller Lifecycle
    @IBOutlet var currentValueLabel: NSTextField!
    @IBOutlet var customCheckbox: CustomCheckBoxView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Allow the CustomCheckBoxView to call our own action function.
        customCheckbox.actionHandler = { self.changeCheckBoxValue(self) }
    }
    
    func changeCheckBoxValue(_ sender: Any) {
        currentValueLabel.stringValue = NSString(format: "(State = %@)", customCheckbox.checked ? "checked" : "unchecked") as String
    }
}

