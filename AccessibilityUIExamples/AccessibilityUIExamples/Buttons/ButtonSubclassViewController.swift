/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller demonstrating an accessible, custom NSButton subclass.
*/

import Cocoa

class ButtonSubclassViewController: ButtonBaseViewController {

    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        button.setAccessibilityLabel(NSLocalizedString("My label", comment: "label to use for this button"))
    }
    
}

