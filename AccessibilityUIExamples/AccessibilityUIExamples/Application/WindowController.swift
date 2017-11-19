/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample's main window controller.
*/

import Cocoa
import Foundation

class WindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Let the window accept (and distribute) mouse-moved events.
        window?.acceptsMouseMovedEvents = true
        
        // Window is not transparent to mouse events.
        window?.ignoresMouseEvents = false
    }

}
