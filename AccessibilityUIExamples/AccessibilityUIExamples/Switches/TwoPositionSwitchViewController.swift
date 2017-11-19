/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller demonstrating an accessible, custom two-position switch.
*/

import Cocoa

class TwoPositionSwitchViewController: NSViewController {

    @IBOutlet var placeHolderView: NSView!
    var twoPositionSwitch: TwoPositionSwitchView!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        twoPositionSwitch = TwoPositionSwitchView(frame: placeHolderView.frame)
        placeHolderView.addSubview(twoPositionSwitch)
    }
    
}

