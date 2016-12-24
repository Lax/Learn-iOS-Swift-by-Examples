/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `CharacteristicTriggerViewController` allows the user to create a characteristic trigger.
*/

import UIKit
import HomeKit

/// A view controller which facilitates the creation of characteristic triggers.
class CharacteristicTriggerViewController: EventTriggerViewController {
    // MARK: Types
    
    struct Identifiers {
        static let selectCharacteristicSegue = "Select Characteristic"
    }
    
    // MARK: Properties
    
    private var characteristicTriggerCreator: CharacteristicTriggerCreator {
        return triggerCreator as! CharacteristicTriggerCreator
    }
    
    var eventTrigger: HMEventTrigger? {
        return trigger as? HMEventTrigger
    }
    
    /// An internal array of `HMCharacteristicEvent`s to save into the trigger.
    private var events = [HMCharacteristicEvent]()
    
    // MARK: View Methods
    
    /// Creates the trigger creator.
    override func viewDidLoad() {
        super.viewDidLoad()
        triggerCreator = CharacteristicTriggerCreator(trigger: eventTrigger, home: home)
    }
    
    /// Reloads the internal data.
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
    
    /// Passes our event trigger and trigger creator to the `CharacteristicSelectionViewController`
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        if segue.identifier == Identifiers.selectCharacteristicSegue {
            if let destinationVC = segue.intendedDestinationViewController as? CharacteristicSelectionViewController {
                destinationVC.eventTrigger = eventTrigger
                destinationVC.triggerCreator = characteristicTriggerCreator
            }
        }
    }
    
    // MARK: Table View Methods
    
    /**
        - returns:  The characteristic events for the Characteristics section.
                    Defaults to super implementation.
    */
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sectionForIndex(section) {
            case .Characteristics?:
                // Plus one for the add row.
                return events.count + 1
            
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    /**
        Switches based on cell type to generate the correct cell for the index path.
        Defaults to super implementation.
    */
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPathIsAdd(indexPath) {
            return self.tableView(tableView, addCellForRowAtIndexPath: indexPath)
        }
        
        switch sectionForIndex(indexPath.section) {
            case .Characteristics?:
                return self.tableView(tableView, conditionCellForRowAtIndexPath: indexPath)
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        }
    }
    
    /// - returns:  A 'condition cell' with the event at the specified index path.
    private func tableView(tableView: UITableView, conditionCellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.conditionCell, forIndexPath: indexPath) as! ConditionCell
        let event = events[indexPath.row]
        cell.setCharacteristic(event.characteristic, targetValue: event.triggerValue!)
        return cell
    }
    
    /**
        - returns:  An 'add cell' with localized text.
                    Defaults to super implementation.
    */
    override func tableView(tableView: UITableView, addCellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch sectionForIndex(indexPath.section) {
            case .Characteristics?:
                let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.addCell, forIndexPath: indexPath)
                cell.textLabel?.text = NSLocalizedString("Add Characteristic…", comment: "Add Characteristic")
                cell.textLabel?.textColor = UIColor.editableBlueColor()
                return cell
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                return super.tableView(tableView, addCellForRowAtIndexPath: indexPath)
        }
    }
    
    /**
        Handles the selection of characteristic events.
        Defaults to super implementation for other sections.
    */
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        switch sectionForIndex(indexPath.section) {
            case .Characteristics?:
                if indexPathIsAdd(indexPath) {
                    addEvent()
                    return
                }
                let cell = tableView.cellForRowAtIndexPath(indexPath)
                performSegueWithIdentifier(Identifiers.selectCharacteristicSegue, sender: cell)
            
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        }
    }
    
    /**
        - returns:  `true` for characteristic cells,
                    otherwise defaults to super implementation.
    */
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPathIsAdd(indexPath) {
            return false
        }
        switch sectionForIndex(indexPath.section) {
            case .Characteristics?:
                return true
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                return super.tableView(tableView, canEditRowAtIndexPath: indexPath)
        }
    }
    
    /**
        Removes events from the trigger creator.
        Defaults to super implementation for other sections.
    */
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            switch sectionForIndex(indexPath.section) {
                case .Characteristics?:
                    characteristicTriggerCreator.removeEvent(events[indexPath.row])
                    events = characteristicTriggerCreator.events
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    
                case nil:
                    fatalError("Unexpected `TriggerTableViewSection` raw value.")
                    
                default:
                    super.tableView(tableView, commitEditingStyle: editingStyle, forRowAtIndexPath: indexPath)
            }
        }
    }
    
    /**
        - returns:  A localized description of characteristic events
                    Defaults to super implementation for other sections.
    */
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch sectionForIndex(section) {
            case .Characteristics?:
                return NSLocalizedString("This trigger will activate when any of these characteristics change to their value. For example, 'run when the garage door is opened'.", comment: "Characteristic Trigger Description")
            
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                return super.tableView(tableView, titleForFooterInSection: section)
        }
    }
    
    // MARK: Helper Methods
    
    /// Resets the internal events array from the trigger creator.
    private func reloadData() {
        events = characteristicTriggerCreator.events
        tableView.reloadData()
    }
    
    /// Performs a segue to the `CharacteristicSelectionViewController`.
    private func addEvent() {
        characteristicTriggerCreator.mode = .Event
        self.performSegueWithIdentifier(Identifiers.selectCharacteristicSegue, sender: nil)
    }
    
    /// - returns:  `true` if the section is the Characteristic 'add row'; otherwise defaults to super implementation.
    override func indexPathIsAdd(indexPath: NSIndexPath) -> Bool {
        switch sectionForIndex(indexPath.section) {
            case .Characteristics?:
                return indexPath.row == events.count
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                return super.indexPathIsAdd(indexPath)
        }
    }
    
    // MARK: Trigger Controller Methods

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
                return .Characteristics
            
            case 3:
                return .Conditions
            
            case 4:
                return .ActionSets
            
            default:
                return nil
        }
    }
    
}