/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller demonstrating an accessible, custom view subclass that behaves like a stepper.
*/

import Cocoa

class CustomStepperViewController: NSViewController {
    
    @IBOutlet var customStepper: CustomStepperView!
    @IBOutlet var volumeLevel: NSTextField!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        customStepper.actionHandler = { self.pressStepper(self) }
        customStepper.actionHandler!()
    }
    
    fileprivate func updateVolumeLabel(volume: CGFloat) {
        let number = NSNumber(value: Float(volume / 100.0))
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.percent
        numberFormatter.maximumFractionDigits = 0
        
        let stringFormatter = NSLocalizedString("VolumeFormatter", comment: "Formatter for volume")
        var label = numberFormatter.string(from: number)
        label = String(format:stringFormatter, label!)
        
        volumeLevel.stringValue = label!
    }
    
    fileprivate func pressStepper(_ sender: Any) {
        updateVolumeLabel(volume: customStepper.value)
    }
    
}

