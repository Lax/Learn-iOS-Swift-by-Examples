/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to use UIDatePicker.
*/

import UIKit

class DatePickerController: UIViewController {
    // MARK: Properties

    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var dateLabel: UILabel!

    /// A date formatter to format the `date` property of `datePicker`.
    lazy var dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .ShortStyle
        
        return dateFormatter
    }()

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureDatePicker()
    }

    // MARK: Configuration

    func configureDatePicker() {
        datePicker.datePickerMode = .DateAndTime

        // Set min/max date for the date picker.
        // As an example we will limit the date between now and 7 days from now.
        let now = NSDate()
        datePicker.minimumDate = now

        let currentCalendar = NSCalendar.currentCalendar()

        let dateComponents = NSDateComponents()
        dateComponents.day = 7

        let sevenDaysFromNow = currentCalendar.dateByAddingComponents(dateComponents, toDate: now, options: nil)
        datePicker.maximumDate = sevenDaysFromNow

        datePicker.minuteInterval = 2

        datePicker.addTarget(self, action: "updateDatePickerLabel", forControlEvents: .ValueChanged)

        updateDatePickerLabel()
    }

    // MARK: Actions

    func updateDatePickerLabel() {
        dateLabel.text = dateFormatter.stringFromDate(datePicker.date)
    }
}
