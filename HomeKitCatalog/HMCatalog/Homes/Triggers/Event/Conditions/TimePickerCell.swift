/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `TimePickerCell` has a date picker, used for selecting a specific time of day.
*/

import UIKit

/// A `UITableViewCell` subclass with a `UIDatePicker`, used for selecting a specific time of day.
class TimePickerCell: UITableViewCell {
    // MARK: Properties
    
    @IBOutlet weak var datePicker: UIDatePicker!
}