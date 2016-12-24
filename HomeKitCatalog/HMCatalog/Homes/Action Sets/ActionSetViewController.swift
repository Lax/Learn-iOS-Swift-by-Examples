/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ActionSetViewController` allows users to create and modify action sets.
*/


import UIKit
import HomeKit

/// Represents table view sections of the `ActionSetViewController`.
enum ActionSetTableViewSection: Int {
    case Name, Actions, Accessories
}

/**
    A view controller that facilitates creation of Action Sets.

    It contains a cell for a name, and lists accessories within a home.
    If there are actions within the action set, it also displays a list of ActionCells displaying those actions.
    It owns an `ActionSetCreator` and routes events to the creator as appropriate.
*/
class ActionSetViewController: HMCatalogViewController {
    // MARK: Types
    
    struct Identifiers {
        static let accessoryCell = "AccessoryCell"
        static let unreachableAccessoryCell = "UnreachableAccessoryCell"
        static let actionCell = "ActionCell"
        static let showServiceSegue = "Show Services"
    }
    
    // MARK: Properties
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var actionSet: HMActionSet?
    var actionSetCreator: ActionSetCreator!
    var displayedAccessories = [HMAccessory]()
    
    // MARK: View Methods
    
    /**
        Creates the action set creator, registers the appropriate reuse identifiers in the table,
        and sets the `nameField` if appropriate.
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        actionSetCreator = ActionSetCreator(actionSet: actionSet, home: home)
        displayedAccessories = home.sortedControlAccessories

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Identifiers.accessoryCell)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Identifiers.unreachableAccessoryCell)
        tableView.registerClass(ActionCell.self, forCellReuseIdentifier: Identifiers.actionCell)
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.estimatedRowHeight = 44.0
        
        if let actionSet = actionSet {
            nameField.text = actionSet.name
            nameFieldDidChange(nameField)
        }
        
        if !home.isAdmin {
            nameField.enabled = false
        }
    }
    
    /// Reloads the data and view.
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        enableSaveButtonIfNecessary()
    }
    
    /// Dismisses the view controller if our data is invalid.
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if shouldPopViewController() {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    /// Dismisses the keyboard when we dismiss.
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }
    
    /// Passes our accessory into the `ServicesViewController`.
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        if segue.identifier == Identifiers.showServiceSegue {
            let servicesViewController = segue.intendedDestinationViewController as! ServicesViewController
            servicesViewController.onlyShowsControlServices = true
            servicesViewController.cellDelegate = actionSetCreator

            let index = tableView.indexPathForCell(sender as! UITableViewCell)!.row
            
            servicesViewController.accessory = displayedAccessories[index]
            servicesViewController.cellDelegate = actionSetCreator
        }
    }
    
    // MARK: IBAction Methods
    
    /// Dismisses the view controller.
    @IBAction func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    /// Saves the action set, adds it to the home, and dismisses the view.
    @IBAction func saveAndDismiss() {
        saveButton.enabled = false

        actionSetCreator.saveActionSetWithName(trimmedName) { error in
            self.saveButton.enabled = true
        
            if let error = error {
                self.displayError(error)
            }
            else {
                self.dismiss()
            }
        }
    }
    
    /// Prompts an update to the save button enabled state.
    @IBAction func nameFieldDidChange(field: UITextField) {
        enableSaveButtonIfNecessary()
    }
    
    // MARK: Table View Methods
    
    /// We do not allow the creation of action sets in a shared home.
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return home.isAdmin ? 3 : 2
    }
    
    /**
        - returns:  In the Actions section: the number of actions this set will contain upon saving.
                    In the Accessories section: The number of accessories in the home.
    */
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch ActionSetTableViewSection(rawValue: section) {
            case .Name?:
                return super.tableView(tableView, numberOfRowsInSection: section)
                
            case .Actions?:
                return max(actionSetCreator.allCharacteristics.count, 1)
                
            case .Accessories?:
                return displayedAccessories.count
                
            case nil:
                fatalError("Unexpected `ActionSetTableViewSection` raw value.")
        }
    }
    
    /**
        Required override to allow for a tableView with both static and dynamic content.
        Basically, since the superclass's indentationLevelForRowAtIndexPath is only
        expecting 1 row per section, just call the super class's implementation 
        for the first row.
    */
    override func tableView(tableView: UITableView, indentationLevelForRowAtIndexPath indexPath: NSIndexPath) -> Int {
        return super.tableView(tableView, indentationLevelForRowAtIndexPath: NSIndexPath(forRow: 0, inSection: indexPath.section))
    }
    
    /// Removes the action associated with the index path.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let characteristic = actionSetCreator.allCharacteristics[indexPath.row]
            actionSetCreator.removeTargetValueForCharacteristic(characteristic) {
                if self.actionSetCreator.containsActions {
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
                else {
                    tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
            }
        }
    }
    
    /// - returns:  `true` for the Actions section; `false` otherwise.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return ActionSetTableViewSection(rawValue: indexPath.section) == .Actions && home.isAdmin
    }
    
    /// - returns:  `UITableViewAutomaticDimension` for dynamic sections, otherwise the superclass's implementation.
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch ActionSetTableViewSection(rawValue: indexPath.section) {
            case .Name?:
                return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
                
            case .Actions?, .Accessories?:
                return UITableViewAutomaticDimension
                
            case nil:
                fatalError("Unexpected `ActionSetTableViewSection` raw value.")
        }
    }
    
    /// - returns:  An action cell for the actions section, an accessory cell for the accessory section, or the superclass's implementation.
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch ActionSetTableViewSection(rawValue: indexPath.section) {
            case .Name?:
                return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
                
            case .Actions?:
                if actionSetCreator.containsActions {
                    return self.tableView(tableView, actionCellForRowAtIndexPath: indexPath)
                }
                else {
                    return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
                }
                
            case .Accessories?:
                return self.tableView(tableView, accessoryCellForRowAtIndexPath: indexPath)
            
            case nil:
                fatalError("Unexpected `ActionSetTableViewSection` raw value.")
        }
    }
    
    // MARK: Helper Methods
    
    /// Enables the save button if there is a valid name and at least one action.
    private func enableSaveButtonIfNecessary() {
        saveButton.enabled = home.isAdmin && trimmedName.characters.count > 0 && actionSetCreator.containsActions
    }
    
    /// - returns:  The contents of the nameField, with whitespace trimmed from the beginning and end.
    private var trimmedName: String {
        return nameField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
    
    /**
        - returns:  `true` if there are no accessories in the home, we have no set action set,
                    or if our home no longer exists; `false` otherwise
    */
    private func shouldPopViewController() -> Bool {
        if homeStore.home?.accessories.count == 0 && actionSet == nil {
            return true
        }
        
        return !homeStore.homeManager.homes.contains { $0 == homeStore.home }
    }
    
    /// - returns:  An `ActionCell` instance with the target value for the characteristic at the specified index path.
    private func tableView(tableView: UITableView, actionCellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.actionCell, forIndexPath: indexPath) as! ActionCell
        let characteristic = actionSetCreator.allCharacteristics[indexPath.row] as HMCharacteristic

        if let target = actionSetCreator.targetValueForCharacteristic(characteristic) {
            cell.setCharacteristic(characteristic, targetValue: target)
        }
        
        return cell
    }
    
    /// - returns:  An Accessory cell that contains an accessory's name.
    private func tableView(tableView: UITableView, accessoryCellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        /*
            These cells are static, the identifiers are defined in the Storyboard,
            but they're not recognized here. In viewDidLoad:, we're registering 
            `UITableViewCell` as the class for "AccessoryCell" and "UnreachableAccessoryCell". 
            We must configure these cells manually, the cells in the Storyboard 
            are just for reference.
        */
        
        let accessory = displayedAccessories[indexPath.row]
        let cellIdentifier = accessory.reachable ? Identifiers.accessoryCell : Identifiers.unreachableAccessoryCell
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        cell.textLabel?.text = accessory.name
        
        if accessory.reachable {
            cell.textLabel?.textColor = UIColor.darkTextColor()
            cell.accessoryType = .DisclosureIndicator
            cell.selectionStyle = .Default
        }
        else {
            cell.textLabel?.textColor = UIColor.lightGrayColor()
            cell.accessoryType = .None
            cell.selectionStyle = .None
        }
        
        return cell
    }
    
    /// Shows the services in the selected accessory.
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        if cell.selectionStyle == .None {
            return
        }

        if ActionSetTableViewSection(rawValue: indexPath.section) == .Accessories {
            performSegueWithIdentifier(Identifiers.showServiceSegue, sender: cell)
        }
    }
    
    // MARK: HMHomeDelegate Methods
    
    /**
        Pops the view controller if our configuration is invalid;
        reloads the view otherwise.
    */
    func home(home: HMHome, didRemoveAccessory accessory: HMAccessory) {
        if shouldPopViewController() {
            dismissViewControllerAnimated(true, completion: nil)
        }
        else {
            tableView.reloadData()
        }
    }
    
    /// Reloads the table view data.
    func home(home: HMHome, didAddAccessory accessory: HMAccessory) {
        tableView.reloadData()
    }
    
    /// If our action set was removed, dismiss the view.
    func home(home: HMHome, didRemoveActionSet actionSet: HMActionSet) {
        if actionSet == self.actionSet {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
}
