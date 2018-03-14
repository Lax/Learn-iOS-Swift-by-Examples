/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	`SplitViewController` is an `NSSplitViewController` subclass.
 */

import Cocoa

class SplitViewController: NSSplitViewController {

    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        splitView.autosaveName = "SplitViewControllerAutoSaveName"
        
        minimumThicknessForInlineSidebars = 10.0
    }
    
}
