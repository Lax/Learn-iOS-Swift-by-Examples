/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `TimeConditionViewController` allows the user to create a new time condition.
*/

import UIKit
import HomeKit

/// Represents a section in the `TimeConditionViewController`.
enum TimeConditionTableViewSection: Int {
    /**
        This section contains the segmented control to
        choose a time condition type.
    */
    case TimeOrSun
    
    /**
        This section contains cells to allow the selection
        of 'before', 'after', or 'at'. 'At' is only available
        when the exact time is specified.
    */
    case BeforeOrAfter
    
    /**
        If the condition type is exact time, this section will
        only have one cell, the date picker cell.
        
        If the condition type is relative to a solar event,
        this section will have two cells, one for 'sunrise' and
        one for 'sunset.
    */
    case Value
    
    static let count = 3
}

/**
    Represents the type of time condition.

    The condition can be an exact time, or relative to a solar event.
*/
enum TimeConditionType: Int {
    case Time, Sun
}

/**
    Represents the type of solar event.

    This can be sunrise or sunset.
*/
enum TimeConditionSunState: Int {
    case Sunrise, Sunset
}

/**
    Represents the condition order.

    Conditions can be before, after, or exactly at a given time.
*/
enum TimeConditionOrder: Int {
    case Before, After, At
}

/// A view controller that facilitates the creation of time conditions for triggers.
class TimeConditionViewController: HMCatalogViewController {
    // MARK: Types
    
    struct Identifiers {
        static let selectionCell = "SelectionCell"
        static let timePickerCell = "TimePickerCell"
        static let segmentedTimeCell = "SegmentedTimeCell"
    }
    
    static let timeOrSunTitles = [
        NSLocalizedString("Relative to time", comment: "Relative to time"),
        NSLocalizedString("Relative to sun", comment: "Relative to sun")
    ]
    
    static let beforeOrAfterTitles = [
        NSLocalizedString("Before", comment: "Before"),
        NSLocalizedString("After", comment: "After"),
        NSLocalizedString("At", comment: "At")
    ]
    
    static let sunriseSunsetTitles = [
        NSLocalizedString("Sunrise", comment: "Sunrise"),
        NSLocalizedString("Sunset", comment: "Sunset")
    ]
    
    // MARK: Properties
    
    private var timeType: TimeConditionType = .Time
    private var order: TimeConditionOrder = .Before
    private var sunState: TimeConditionSunState = .Sunrise
    
    private var datePicker: UIDatePicker?
    
    var triggerCreator: EventTriggerCreator?
    
    // MARK: View Methods
    
    /// Configures the table view.
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44.0
    }
    
    // MARK: Table View Methods
    
    /// - returns:  The number of `TimeConditionTableViewSection`s.
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TimeConditionTableViewSection.count
    }
    
    /**
        - returns:  The number rows based on the `TimeConditionTableViewSection`
                    and the `timeType`.
    */
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch TimeConditionTableViewSection(rawValue: section) {
            case .TimeOrSun?:
                return 1
                
            case .BeforeOrAfter?:
                // If we're choosing an exact time, we add the 'At' row.
                return (timeType == .Time) ? 3 : 2
                
            case .Value?:
                // Date picker cell or sunrise/sunset selection cells
                return (timeType == .Time) ? 1 : 2
                
            case nil:
                fatalError("Unexpected `TimeConditionTableViewSection` raw value.")
        }
    }
    
    /// Switches based on the section to generate a cell.
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch TimeConditionTableViewSection(rawValue: indexPath.section) {
            case .TimeOrSun?:
                return self.tableView(tableView, segmentedCellForRowAtIndexPath: indexPath)
                
            case .BeforeOrAfter?:
                return self.tableView(tableView, selectionCellForRowAtIndexPath: indexPath)
                
            case .Value?:
                switch timeType {
                case .Time:
                    return self.tableView(tableView, datePickerCellForRowAtIndexPath: indexPath)
                case .Sun:
                    return self.tableView(tableView, selectionCellForRowAtIndexPath: indexPath)
                }
                
            case nil:
                fatalError("Unexpected `TimeConditionTableViewSection` raw value.")
        }
    }
    
    /// - returns:  A localized string describing the section.
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch TimeConditionTableViewSection(rawValue: section) {
            case .TimeOrSun?:
                return NSLocalizedString("Condition Type", comment: "Condition Type")
                
            case .BeforeOrAfter?:
                return nil
                
            case .Value?:
                if timeType == .Time {
                    return NSLocalizedString("Time", comment: "Time")
                }
                else {
                    return NSLocalizedString("Event", comment: "Event")
                }
                
            case nil:
                fatalError("Unexpected `TimeConditionTableViewSection` raw value.")
        }
    }
    
    /// - returns:  A localized description for condition type section; `nil` otherwise.
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch TimeConditionTableViewSection(rawValue: section) {
            case .TimeOrSun?:
                return NSLocalizedString("Time conditions can relate to specific times or special events, like sunrise and sunset.", comment: "Condition Type Description")
                
            case .BeforeOrAfter?:
                return nil
                
            case .Value?:
                return nil
                
            case nil:
                fatalError("Unexpected `TimeConditionTableViewSection` raw value.")
        }
    }
    
    /// Updates internal values based on row selection.
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        if cell.selectionStyle == .None {
            return
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        switch TimeConditionTableViewSection(rawValue: indexPath.section) {
            case .TimeOrSun?:
                timeType = TimeConditionType(rawValue: indexPath.row)!
                reloadDynamicSections()
                return
                
            case .BeforeOrAfter?:
                order = TimeConditionOrder(rawValue: indexPath.row)!
                tableView.reloadSections(NSIndexSet(index: indexPath.section), withRowAnimation: .Automatic)
                
            case .Value?:
                if timeType == .Sun {
                    sunState = TimeConditionSunState(rawValue: indexPath.row)!
                }
                tableView.reloadSections(NSIndexSet(index: indexPath.section), withRowAnimation: .Automatic)
                
            case nil:
                fatalError("Unexpected `TimeConditionTableViewSection` raw value.")
        }
    }
    
    // MARK: Helper Methods
    
    /**
        Generates a selection cell based on the section.
        Ordering and sun-state sections have selections.
    */
    private func tableView(tableView: UITableView, selectionCellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.selectionCell, forIndexPath: indexPath)
        switch TimeConditionTableViewSection(rawValue: indexPath.section) {
            case .BeforeOrAfter?:
                cell.textLabel?.text = TimeConditionViewController.beforeOrAfterTitles[indexPath.row]
                cell.accessoryType = (order.rawValue == indexPath.row) ? .Checkmark : .None
                
            case .Value?:
                if timeType == .Sun {
                    cell.textLabel?.text = TimeConditionViewController.sunriseSunsetTitles[indexPath.row]
                    cell.accessoryType = (sunState.rawValue == indexPath.row) ? .Checkmark : .None
                }
                
            case nil:
                fatalError("Unexpected `TimeConditionTableViewSection` raw value.")
                
            default:
                break
        }
        return cell
    }
    
    /// Generates a date picker cell and sets the internal date picker when created.
    private func tableView(tableView: UITableView, datePickerCellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.timePickerCell, forIndexPath: indexPath) as! TimePickerCell
        // Save the date picker so we can get the result later.
        datePicker = cell.datePicker
        return cell
    }
    
    /// Generates a segmented cell and sets its target when created.
    private func tableView(tableView: UITableView, segmentedCellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.segmentedTimeCell, forIndexPath: indexPath) as! SegmentedTimeCell
        cell.segmentedControl.selectedSegmentIndex = timeType.rawValue
        cell.segmentedControl.removeTarget(nil, action: nil, forControlEvents: .AllEvents)
        cell.segmentedControl.addTarget(self, action: #selector(TimeConditionViewController.segmentedControlDidChange(_:)), forControlEvents: .ValueChanged)
        return cell
    }
    
    /// Creates date components from the date picker's date.
    var dateComponents: NSDateComponents? {
        guard let datePicker = datePicker else { return nil }
        let flags: NSCalendarUnit = [.Hour, .Minute]
        return NSCalendar.currentCalendar().components(flags, fromDate: datePicker.date)
    }
    
    /**
        Updates the time type and reloads dynamic sections.
        
        - parameter segmentedControl: The segmented control that changed.
    */
    func segmentedControlDidChange(segmentedControl: UISegmentedControl) {
        if let segmentedControlType = TimeConditionType(rawValue: segmentedControl.selectedSegmentIndex) {
            timeType = segmentedControlType
        }
        reloadDynamicSections()
    }
    
    /// Reloads the BeforeOrAfter and Value section.
    private func reloadDynamicSections() {
        if timeType == .Sun && order == .At {
            order = .Before
        }
        let reloadIndexSet = NSIndexSet(indexesInRange: NSMakeRange(TimeConditionTableViewSection.BeforeOrAfter.rawValue, 2))
        tableView.reloadSections(reloadIndexSet, withRowAnimation: .Automatic)
    }
    
    // MARK: IBAction Methods
    
    /**
        Generates a predicate based on the stored values, adds
        the condition to the trigger, then dismisses the view.
    */
    @IBAction func saveAndDismiss(sender: UIBarButtonItem) {
        var predicate: NSPredicate?
        switch timeType {
            case .Time:
                switch order {
                    case .Before:
                        predicate = HMEventTrigger.predicateForEvaluatingTriggerOccurringBeforeDateWithComponents(dateComponents!)
                        
                    case .After:
                        predicate = HMEventTrigger.predicateForEvaluatingTriggerOccurringAfterDateWithComponents(dateComponents!)
                        
                    case .At:
                        predicate = HMEventTrigger.predicateForEvaluatingTriggerOccurringOnDateWithComponents(dateComponents!)
                }
            
            case .Sun:
                let significantEventString = (sunState == .Sunrise) ? HMSignificantEventSunrise : HMSignificantEventSunset
                switch order {
                    case .Before:
                        predicate = HMEventTrigger.predicateForEvaluatingTriggerOccurringBeforeSignificantEvent(significantEventString, applyingOffset: nil)
                        
                    case .After:
                        predicate = HMEventTrigger.predicateForEvaluatingTriggerOccurringAfterSignificantEvent(significantEventString, applyingOffset: nil)
                        
                    case .At:
                        // Significant events must be specified 'before' or 'after'.
                        break
                }
        }
        if let predicate = predicate {
            triggerCreator?.addCondition(predicate)
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    /// Cancels the creation of the conditions and exits.
    @IBAction func dismiss(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}