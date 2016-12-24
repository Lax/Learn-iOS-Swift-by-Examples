/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `TriggerViewController` is a superclass which allows users to create triggers.
*/

import UIKit
import HomeKit

/// Represents all possible sections in a `TriggerViewController` subclass.
enum TriggerTableViewSection: Int {
    // All triggers have these sections.
    case Name, Enabled, ActionSets
    
    // Timer triggers only.
    case DateAndTime, Recurrence
    
    // Location and Characteristic triggers only.
    case Conditions

    // Location triggers only.
    case Location, Region

    // Characteristic triggers only.
    case Characteristics
}

/**
    A superclass for all trigger view controllers.

    It manages the name, enabled state, and action set components of the view,
    as these are shared components.
*/
class TriggerViewController: HMCatalogViewController {
    // MARK: Types
    
    struct Identifiers {
        static let actionSetCell = "ActionSetCell"
    }
    
    // MARK: Properties
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var enabledSwitch: UISwitch!
    
    var trigger: HMTrigger?
    var triggerCreator: TriggerCreator?
    
    /// An internal array of all action sets in the home.
    var actionSets: [HMActionSet]!
    
    /**
        An array of all action sets that the user has selected.
        This will be used to save the trigger when it is finalized.
    */
    lazy var selectedActionSets = [HMActionSet]()
    
    // MARK: View Methods
    
    /// Resets internal data, sets initial UI, and configures the table view.
    override func viewDidLoad() {
        super.viewDidLoad()
        let filteredActionSets = home.actionSets.filter { actionSet in
            return !actionSet.actions.isEmpty
        }

        actionSets = filteredActionSets.sortByTypeAndLocalizedName()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44.0
        
        /*
            If we have a trigger, set the saved properties to the current properties
            of the passed-in trigger.
        */
        if let trigger = trigger {
            selectedActionSets = trigger.actionSets
            nameField.text = trigger.name
            enabledSwitch.on = trigger.enabled
        }

        enableSaveButtonIfApplicable()
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Identifiers.actionSetCell)
    }
    
    // MARK: IBAction Methods
    
    /**
        Any time the name field changed, reevaluate whether or not
        to enable the save button.
    */
    @IBAction func nameFieldDidChange(sender: UITextField) {
        enableSaveButtonIfApplicable()
    }
    
    /// Saves the trigger and dismisses this view controller.
    @IBAction func saveAndDismiss() {
        saveButton.enabled = false
        triggerCreator?.saveTriggerWithName(trimmedName, actionSets: selectedActionSets) { trigger, errors in
            self.trigger = trigger
            self.saveButton.enabled = true
            
            if !errors.isEmpty {
                self.displayErrors(errors)
                return
            }

            self.enableTrigger(self.trigger!) {
                self.dismiss()
            }
        }
    }
    
    @IBAction func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Subclass Methods
    
    /**
        Generates the section for the index.
        
        This allows for the subclasses to lay out their content in different sections 
        while still maintaining common code in the `TriggerViewController`.
        
        - parameter index: The index of the section
        
        - returns:  The `TriggerTableViewSection` for the provided index.
    */
    func sectionForIndex(index: Int) -> TriggerTableViewSection? {
        return nil
    }
    
    // MARK: Helper Methods
    
    /// Enable the trigger if necessary.
    func enableTrigger(trigger: HMTrigger, completion: Void -> Void) {
        if trigger.enabled == enabledSwitch.on {
            completion()
            return
        }

        trigger.enable(enabledSwitch.on) { error in
            if let error = error {
                self.displayError(error)
            }
            else {
                completion()
            }
        }
    }
    
    /**
        Enables the save button if:
        
        1. The name field is not empty, and
        2. There will be at least one action set in the trigger after saving.
    */
    private func enableSaveButtonIfApplicable() {
        saveButton.enabled = !trimmedName.characters.isEmpty &&
            (!selectedActionSets.isEmpty || trigger?.actionSets.count > 0)
    }
    
    /// - returns:  The name from the `nameField`, stripping newline and whitespace characters.
    var trimmedName: String {
        return nameField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
    
    // MARK: Table View Methods
    
    /// Creates a cell that represents either a selected or unselected action set cell.
    private func tableView(tableView: UITableView, actionSetCellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.actionSetCell, forIndexPath: indexPath)
        let actionSet = actionSets[indexPath.row]

        if selectedActionSets.contains(actionSet)  {
            cell.accessoryType = .Checkmark
        }
        else {
            cell.accessoryType = .None
        }
        
        cell.textLabel?.text = actionSet.name
        
        return cell
    }
    
    
    /// Only handles the ActionSets case, defaults to super.
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sectionForIndex(section) == .ActionSets {
            return actionSets.count ?? 0
        }

        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    /// Only handles the ActionSets case, defaults to super.
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if sectionForIndex(indexPath.section) == .ActionSets {
            return self.tableView(tableView, actionSetCellForRowAtIndexPath: indexPath)
        }

        return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
    }
    
    /**
        This is necessary for mixing static and dynamic table view cells.
        We return a fake index path because otherwise the superclass's implementation (which does not
        know about the extra cells we're adding) will cause an error.
        
        - returns:  The superclass's indentationLevel for the first row in the provided section,
                    instead of the provided row.
    */
    override func tableView(tableView: UITableView, indentationLevelForRowAtIndexPath indexPath: NSIndexPath) -> Int {
        let newIndexPath = NSIndexPath(forRow: 0, inSection: indexPath.section)

        return super.tableView(tableView, indentationLevelForRowAtIndexPath: newIndexPath)
    }
    
    /**
        Tell the tableView to automatically size the custom rows, while using the superclass's
        static sizing for the static cells.
    */
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch sectionForIndex(indexPath.section) {
            case .Name?, .Enabled?:
                return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                return UITableViewAutomaticDimension
        }
    }
    
    /// Handles row selction for action sets, defaults to super implementation.
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if sectionForIndex(indexPath.section) == .ActionSets {
            self.tableView(tableView, didSelectActionSetAtIndexPath: indexPath)
        }
    }
    
    /**
        Manages footer titles for higher-level sections. Superclasses should fall back
        on this implementation after attempting to handle any special trigger sections.
    */
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch sectionForIndex(section) {
            case .ActionSets?:
                return NSLocalizedString("When this trigger is activated, it will set these scenes. You can only select scenes which have at least one action.", comment: "Scene Trigger Description")
                
            case .Enabled?:
                return NSLocalizedString("This trigger will only activate if it is enabled. You can disable triggers to temporarily stop them from running.", comment: "Trigger Enabled Description")
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                return super.tableView(tableView, titleForFooterInSection: section)
        }
    }
    
    /**
        Handle selection of an action set cell. If the action set is already part of the selected action sets,
        then remove it from the selected list. Otherwise, add it to the selected list.
    */
    func tableView(tableView: UITableView, didSelectActionSetAtIndexPath indexPath: NSIndexPath) {
        let actionSet = actionSets[indexPath.row]
        if let index = selectedActionSets.indexOf(actionSet) {
            selectedActionSets.removeAtIndex(index)
        }
        else {
            selectedActionSets.append(actionSet)
        }

        enableSaveButtonIfApplicable()
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    // MARK: HMHomeDelegate Methods
    
    /**
        If our trigger has been removed from the home,
        dismiss the view controller.
    */
    func home(home: HMHome, didRemoveTrigger trigger: HMTrigger) {
        if self.trigger == trigger{
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    /// If our trigger has been updated, reload our data.
    func home(home: HMHome, didUpdateTrigger trigger: HMTrigger) {
        if self.trigger == trigger{
            tableView.reloadData()
        }
    }
}
