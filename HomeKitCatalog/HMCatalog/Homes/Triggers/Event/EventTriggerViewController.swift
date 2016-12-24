/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `EventTriggerViewController` is a superclass that helps users create Characteristic and Location triggers.
*/

import UIKit
import HomeKit

/**
    A superclass for all event-based view controllers.

    It handles the process of creating and managing trigger conditions.
*/
class EventTriggerViewController: TriggerViewController {
    // MARK: Types
    
    struct Identifiers {
        static let addCell = "AddCell"
        static let conditionCell = "ConditionCell"
        static let showTimeConditionSegue = "Show Time Condition"
    }
    
    // MARK: Properties
    
    private var eventTriggerCreator: EventTriggerCreator {
        return triggerCreator as! EventTriggerCreator
    }
    
    // MARK: View Methods
    
    /// Registers table view for cells.
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier:Identifiers.addCell)
        tableView.registerClass(ConditionCell.self, forCellReuseIdentifier:Identifiers.conditionCell)
    }
    
    /// Hands off the trigger creator to the condition view controllers.
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.intendedDestinationViewController {
            case let timeVC as TimeConditionViewController:
                timeVC.triggerCreator = eventTriggerCreator

            case let characteristicEventVC as CharacteristicSelectionViewController:
                let characteristicTriggerCreator = triggerCreator as! EventTriggerCreator
                characteristicEventVC.triggerCreator = characteristicTriggerCreator
            
            default:
                break
        }
    }
    
    // MARK: Table View Methods
    
    /**
        - returns:  In the conditions section: the number of conditions, plus one 
                    for the add row. Defaults to the super implementation.
    */
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sectionForIndex(section) {
            case .Conditions?:
                // Add row.
                return eventTriggerCreator.conditions.count + 1
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    /**
        Launchs "Add Condition" if the 'add index path' is selected.
        Defaults to the super implementation.
    */
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        switch sectionForIndex(indexPath.section) {
            case .Conditions?:
                if indexPathIsAdd(indexPath) {
                    addCondition()
                }
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        }
    }
    
    /**
        Switches to select the correct type of cell for the section.
        Defaults to the super implementation.
    */
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPathIsAdd(indexPath) {
            return self.tableView(tableView, addCellForRowAtIndexPath: indexPath)
        }
        
        switch sectionForIndex(indexPath.section) {
            case .Conditions?:
                return self.tableView(tableView, conditionCellForRowAtIndexPath: indexPath)
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        }
    }
    
    /**
        The conditions can be removed, the 'add index path' cannot.
        For all others, default to super implementation.
    */
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPathIsAdd(indexPath) {
            return false
        }
        
        switch sectionForIndex(indexPath.section) {
            case .Conditions?:
                return true
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                return false
        }
    }
    
    /// Remove the selected condition from the trigger creator.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let predicate = eventTriggerCreator.conditions[indexPath.row]
            eventTriggerCreator.removeCondition(predicate)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    /// - returns:  An 'add cell' with 'Add Condition' text.
    func tableView(tableView: UITableView, addCellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.addCell, forIndexPath: indexPath)
        let cellText: String
        switch sectionForIndex(indexPath.section) {
            case .Conditions?:
                cellText = NSLocalizedString("Add Condition…", comment: "Add Condition")
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                cellText = NSLocalizedString("Add…", comment: "Add")
        }

        cell.textLabel?.text = cellText
        cell.textLabel?.textColor = UIColor.editableBlueColor()
     
        return cell
    }
    
    /// - returns:  A localized description of a trigger. Falls back to super implementation.
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch sectionForIndex(section) {
            case .Conditions?:
                return NSLocalizedString("When a trigger is activated by an event, it checks these conditions. If all of them are true, it will set its scenes.", comment: "Trigger Conditions Description")
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                return super.tableView(tableView, titleForFooterInSection: section)
        }
    }
    
    // MARK: Helper Methods
    
    /// - returns:  A 'condition cell', which displays information about the condition.
    private func tableView(tableView: UITableView, conditionCellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.conditionCell) as! ConditionCell
        let condition = eventTriggerCreator.conditions[indexPath.row]

        switch condition.homeKitConditionType {
            case .Characteristic(let characteristic, let value):
                cell.setCharacteristic(characteristic, targetValue: value)

            case .ExactTime(let order, let dateComponents):
                cell.setOrder(order, dateComponents: dateComponents)
            
            case .SunTime(let order, let sunState):
                cell.setOrder(order, sunState: sunState)
            
            case .Unknown:
                cell.setUnknown()
        }

        return cell
    }
    
    /// Presents an alert controller to choose the type of trigger.
    private func addCondition() {
        let title = NSLocalizedString("Add Condition", comment: "Add Condition")
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .ActionSheet)
        
        // Time Condition.
        let timeAction = UIAlertAction(title: NSLocalizedString("Time", comment: "Time"), style: .Default) { _ in
            self.performSegueWithIdentifier(Identifiers.showTimeConditionSegue, sender: self)
        }
        alertController.addAction(timeAction)
        
        // Characteristic trigger.
        let eventActionTitle = NSLocalizedString("Characteristic", comment: "Characteristic")

        let eventAction = UIAlertAction(title: eventActionTitle, style: .Default, handler: { _ in
            if let triggerCreator = self.triggerCreator as? CharacteristicTriggerCreator {
                triggerCreator.mode = .Condition
            }
            self.performSegueWithIdentifier("Select Characteristic", sender: self)
        })

        alertController.addAction(eventAction)
        
        // Cancel.
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // Present alert.
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    /// - returns:  `true` if the index path is the 'add row'; `false` otherwise.
    func indexPathIsAdd(indexPath: NSIndexPath) -> Bool {
        switch sectionForIndex(indexPath.section) {
            case .Conditions?:
                return indexPath.row == eventTriggerCreator.conditions.count
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                return false
        }
    }
}