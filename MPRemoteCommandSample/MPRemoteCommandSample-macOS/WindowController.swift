/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	`WindowController` is an `NSWindowController` subclass
 */

import Cocoa

class WindowController: NSWindowController {
    
    // MARK: Window Lifecycle
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.setFrameAutosaveName("WindowController")
    }
}
