/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Base view controller for views with a single button and a "Press Count" text field.
*/

import Cocoa

class ButtonBaseViewController: NSViewController {

    var pressCount = 0
    
    @IBOutlet var pressCountTextField: NSTextField!
    @IBOutlet var button: NSView!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updatePressCountTextField()
    }
    
    fileprivate func updatePressCountTextField () {
        let formatter = NSLocalizedString("PressCountFormatter", comment: "Press count formatter")
        let numberString = NumberFormatter.localizedString(from: NSNumber(value: pressCount), number: NumberFormatter.Style.none)
        pressCountTextField.stringValue = String(format: formatter, numberString)
    }
    
    // MARK: - Actions
    
    @IBAction func pressButton(_ sender: Any) {
        pressCount += 1
        updatePressCountTextField()
    }

}

