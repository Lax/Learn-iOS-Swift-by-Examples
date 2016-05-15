/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ExtensionDelegate` that manages app level behavior for the WatchKit extension.
*/

import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    // MARK: Properties
    
    /**
        The extension's main interface controller; who is responsible for assigning itself to this property. In
        order to enable appropriate messages to be relayed to it from the extension delegate.
    */
    var mainInterfaceController: WKInterfaceController?
    
    // MARK: WKExtensionDelegate
    
    func handleUserActivity(userInfo: [NSObject : AnyObject]?) {
        mainInterfaceController?.handleUserActivity(userInfo)
    }
}
