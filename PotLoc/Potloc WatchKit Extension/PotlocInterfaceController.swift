/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Default interface controller provided by the project. The interface associated with this controller
        has two buttons, each of which use push segues to transition to action interfaces.
*/

import WatchKit
import Foundation

class PotlocInterfaceController: WKInterfaceController {
    // MARK: Properties

    /**
        Label indicating that the following button correspond to actions that are 
        performed on the Apple Watch.
    */
    @IBOutlet var appleWatchLabel: WKInterfaceLabel!
    
    /**
        Label indicating that the following button corresponds to actions that require
        sending WatchConnectivity messages to the phone to trigger actions.
    */
    @IBOutlet var iPhoneLabel: WKInterfaceLabel!
    
    /// Button that leads to the Request interface.
    @IBOutlet var requestButton: WKInterfaceButton!
    
    /// Button that leads to the Stream interface.
    @IBOutlet var streamButton: WKInterfaceButton!
    
    // MARK: Localized String Convenience

    var appleWatchText: String {
        return NSLocalizedString("Watch", comment: "Apple Watch official name")
    }
    
    var iPhoneText: String {
        return NSLocalizedString("iPhone", comment: "iPhone official name")
    }
    
    var requestTitle: String {
        return NSLocalizedString("Request", comment: "Indicates that pressing this button transitions to the Request interface")
    }
    
    var streamTitle: String {
        return NSLocalizedString("Stream", comment: "Indicates that pressing this button transitions to the Stream interface")
    }
    
    // MARK: Interface Controller
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        appleWatchLabel.setText(appleWatchText)
        iPhoneLabel.setText(iPhoneText)
        
        requestButton.setTitle(requestTitle)
        streamButton.setTitle(streamTitle)
    }
}