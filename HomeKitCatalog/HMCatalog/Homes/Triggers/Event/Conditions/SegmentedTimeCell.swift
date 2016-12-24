/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `SegmentedTimeCell` has a segmented control, used for selecting the time type.
*/

import UIKit
/// A `UITableViewCell` subclass with a `UISegmentedControl`, used for selecting the time type.
class SegmentedTimeCell: UITableViewCell {
    // MARK: Properties
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
}