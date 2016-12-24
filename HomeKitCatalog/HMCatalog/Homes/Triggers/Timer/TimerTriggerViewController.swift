/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `TimerTriggerViewController` allows the user to create Timer triggers.
*/

import UIKit
import HomeKit

/// A view controller which facilitates the creation of timer triggers.
class TimerTriggerViewController: TriggerViewController {
    // MARK: Types
    
    struct Identifiers {
        static let recurrenceCell = "RecurrenceCell"
    }
    
    static let RecurrenceTitles = [
        NSLocalizedString("Every Hour", comment: "Every Hour"),
        NSLocalizedString("Every Day", comment: "Every Day"),
        NSLocalizedString("Every Week", comment: "Every Week")
    ]
    
    // MARK: Properties
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    /**
        Sets the stored fireDate to the new value.
        HomeKit only accepts dates aligned with minute boundaries,
        so we use NSDateComponents to only get the appropriate pieces of information from that date.
        Eventually we will end up with a date following this format: "MM/dd/yyyy hh:mm"
    */
    
    var timerTrigger: HMTimerTrigger? {
        return trigger as? HMTimerTrigger
    }
    
    var timerTriggerCreator: TimerTriggerCreator {
        return triggerCreator as! TimerTriggerCreator
    }
    
    // MARK: View Methods
    
    /// Configures the views and registers for table view cells.
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44.0
        triggerCreator = TimerTriggerCreator(trigger: trigger, home: home)
        datePicker.date = timerTriggerCreator.fireDate
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Identifiers.recurrenceCell)
    }
    
    // MARK: IBAction Methods
    
    /// Reset our saved fire date to the date in the picker.
    @IBAction func didChangeDate(picker: UIDatePicker) {
        timerTriggerCreator.rawFireDate = picker.date
    }
    
    // MARK: Table View Methods
    
    /**
        - returns:  The number of rows in the Recurrence section;
                    defaults to the super implementation for other sections
    */
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sectionForIndex(section) {
            case .Recurrence?:
                return TimerTriggerViewController.RecurrenceTitles.count
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    /**
        Generates a recurrence cell.
        Defaults to the super implementation for other sections
    */
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch sectionForIndex(indexPath.section) {
            case .Recurrence?:
                return self.tableView(tableView, recurrenceCellForRowAtIndexPath: indexPath)
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")

            default:
                return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        }
    }
    
    /// Creates a cell that represents a recurrence type.
    func tableView(tableView: UITableView, recurrenceCellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.recurrenceCell, forIndexPath: indexPath)
        let title = TimerTriggerViewController.RecurrenceTitles[indexPath.row]
        cell.textLabel?.text = title
        
        // The current preferred recurrence style should have a check mark.
        if indexPath.row == timerTriggerCreator.selectedRecurrenceIndex {
            cell.accessoryType = .Checkmark
        }
        else {
            cell.accessoryType = .None
        }
        return cell
    }
    
    /**
        Tell the tableView to automatically size the custom rows, while using the superclass's
        static sizing for the static cells.
    */
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch sectionForIndex(indexPath.section) {
            case .Recurrence?:
                return UITableViewAutomaticDimension
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
    }
    
    /**
        Handles recurrence cell selection.
        Defaults to the super implementation for other sections
    */
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        switch sectionForIndex(indexPath.section) {
            case .Recurrence?:
                self.tableView(tableView, didSelectRecurrenceComponentAtIndexPath: indexPath)
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        }
    }
    
    /**
        Handles selection of a recurrence cell.
        
        If the newly selected recurrence component is the previously selected
        recurrence component, reset the current selected component to `NSNotFound`
        and deselect that row.
    */
    func tableView(tableView: UITableView, didSelectRecurrenceComponentAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == timerTriggerCreator.selectedRecurrenceIndex {
            timerTriggerCreator.selectedRecurrenceIndex = NSNotFound
        }
        else {
            timerTriggerCreator.selectedRecurrenceIndex = indexPath.row
        }
        tableView.reloadSections(NSIndexSet(index: indexPath.section), withRowAnimation: .Automatic)
    }
    
    /**
        - parameter index: The section index.
        
        - returns:  The `TriggerTableViewSection` for the given index.
    */
    override func sectionForIndex(index: Int) -> TriggerTableViewSection? {
        switch index {
            case 0:
                return .Name
            
            case 1:
                return .Enabled
            
            case 2:
                return .DateAndTime
            
            case 3:
                return .Recurrence
            
            case 4:
                return .ActionSets
            
            default:
                return nil
        }
    }
    
}