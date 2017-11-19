/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller demonstrating an accessible, custom NSView subclass that behaves like a button.
*/

import Cocoa

class ButtonViewSubclassViewController: ButtonBaseViewController {

    // MARK: - View Controller Lifecycle
    
    @IBOutlet var customButton: CustomButtonView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Allow the CustomButtonView to call our own action function.
        customButton.actionHandler = { self.pressButton(self) }
    }
    
}

