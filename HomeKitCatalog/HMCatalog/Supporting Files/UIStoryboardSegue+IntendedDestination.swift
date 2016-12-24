/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `UIStoryboardSegue+IntendedDestination` method allows for the selection of a segue's destination.
*/

import UIKit

extension UIStoryboardSegue {
    
    /// - returns:  The intended `UIViewController` from the segue's destination.
    var intendedDestinationViewController: UIViewController {
        if let navigationController = self.destinationViewController as? UINavigationController {
            return navigationController.topViewController!
        }
        return self.destinationViewController
    }
}