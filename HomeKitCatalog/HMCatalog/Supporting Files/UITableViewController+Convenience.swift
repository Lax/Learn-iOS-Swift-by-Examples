/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `UITableViewController+Convenience` methods allow for the configuration of a background label.
*/

import HomeKit
import UIKit

extension UITableViewController {
    
    /**
        Displays or hides a label in the background of the table view.
    
        - parameter message:    The String message to display. The message is hidden
                                if `nil` is provided.
    */
    func setBackgroundMessage(message: String?) {
        if let message = message {
            // Display a message when the table is empty
            let messageLabel = UILabel()
            
            messageLabel.text = message
            messageLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            messageLabel.textColor = UIColor.lightGrayColor()
            messageLabel.textAlignment = .Center
            messageLabel.sizeToFit()
            
            tableView.backgroundView = messageLabel
            tableView.separatorStyle = .None
        }
        else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .SingleLine
        }
    }
}