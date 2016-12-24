/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The  `ModifyAccessoryViewController` allows the user to modify a HomeKit accessory.
*/

import UIKit
import HomeKit

/// Represents the sections in the `ModifyAccessoryViewController`.
enum AddAccessoryTableViewSection: Int {
    case Name, Rooms, Identify
    
    static let count = 3
}

/// Contains a method for notifying the delegate that the accessory was saved.
protocol ModifyAccessoryDelegate {
    func accessoryViewController(accessoryViewController: ModifyAccessoryViewController, didSaveAccessory accessory: HMAccessory)
}

/// A view controller that allows for renaming, reassigning, and identifying accessories before and after they've been added to a home.
class ModifyAccessoryViewController: HMCatalogViewController, HMAccessoryDelegate {
    // MARK: Types
    
    struct Identifiers {
        static let roomCell = "RoomCell"
    }
    
    // MARK: Properties
    
    // Update this if the acessory failed in any way.
    private var didEncounterError = false
    
    private var selectedIndexPath: NSIndexPath?
    private var selectedRoom: HMRoom!
    
    @IBOutlet weak var nameField: UITextField!
    private lazy var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
    private let saveAccessoryGroup = dispatch_group_create()
    
    private var editingExistingAccessory = false
    
    // Strong reference, because we will replace the button with an activity indicator.
    @IBOutlet /* strong */ var addButton: UIBarButtonItem!
    var delegate: ModifyAccessoryDelegate?
    var rooms = [HMRoom]()
    
    var accessory: HMAccessory!
    
    // MARK: View Methods
    
    /// Configures the table view and initializes view elements.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        selectedRoom = accessory.room ?? home.roomForEntireHome()
        
        // If the accessory belongs to the home already, we are in 'edit' mode.
        editingExistingAccessory = accessoryHasBeenAddedToHome()
        if editingExistingAccessory {
            // Show 'save' instead of 'add.'
            addButton.title = NSLocalizedString("Save", comment: "Save")
        }
        else {
            /*
                If we're not editing an existing accessory, then let the back
                button show in the left.
            */
            navigationItem.leftBarButtonItem = nil
        }
        
        // Put the accessory's name in the 'name' field.
        resetNameField()
        
        // Register a cell for the rooms.
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Identifiers.roomCell)
    }
    
    /**
        Registers as the delegate for the current home
        and the accessory.
    */
    override func registerAsDelegate() {
        super.registerAsDelegate()
        accessory.delegate = self
    }
    
    /// Replaces the activity indicator with the 'Add' or 'Save' button.
    func hideActivityIndicator() {
        activityIndicator.stopAnimating()
        navigationItem.rightBarButtonItem = addButton
    }
    
    /// Temporarily replaces the 'Add' or 'Save' button with an activity indicator.
    func showActivityIndicator() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        activityIndicator.startAnimating()
    }
    
    /**
        Called whenever the user taps the 'add' button.
        
        This method:
        1. Adds the accessory to the home, if not already added.
        2. Updates the accessory's name, if necessary.
        3. Assigns the accessory to the selected room, if necessary.
    */
    @IBAction func didTapAddButton() {
        let name = trimmedName
        showActivityIndicator()
        
        if editingExistingAccessory {
            home(home, assignAccessory: accessory, toRoom: selectedRoom)
            updateName(name, forAccessory: accessory)
        }
        else {
            dispatch_group_enter(saveAccessoryGroup)
            home.addAccessory(accessory) { error in
                if let error = error {
                    self.hideActivityIndicator()
                    self.displayError(error)
                    self.didEncounterError = true
                }
                else {
                    // Once it's successfully added to the home, add it to the room that's selected.
                    self.home(self.home, assignAccessory:self.accessory, toRoom: self.selectedRoom)
                    self.updateName(name, forAccessory: self.accessory)
                }
                dispatch_group_leave(self.saveAccessoryGroup)
            }
        }
        
        dispatch_group_notify(saveAccessoryGroup, dispatch_get_main_queue()) {
            self.hideActivityIndicator()
            if !self.didEncounterError {
                self.dismiss(nil)
            }
        }
    }
    
    /**
        Informs the delegate that the accessory has been saved, and
        dismisses the view controller.
    */
    @IBAction func dismiss(sender: AnyObject?) {
        delegate?.accessoryViewController(self, didSaveAccessory: accessory)
        if editingExistingAccessory {
            presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        }
        else {
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    /**
        - returns: `true` if the accessory has already been added to
                    the home; `false` otherwise.
    */
    func accessoryHasBeenAddedToHome() -> Bool {
        return home.accessories.contains(accessory) 
    }
    
    /**
        Updates the accessories name. This function will enter and leave the saved dispatch group.
        If the accessory's name is already equal to the passed-in name, this method does nothing.
        
        - parameter name:      The new name for the accessory.
        - parameter accessory: The accessory to rename.
    */
    func updateName(name: String, forAccessory accessory: HMAccessory) {
        if accessory.name == name {
            return
        }
        dispatch_group_enter(saveAccessoryGroup)
        accessory.updateName(name) { error in
            if let error = error {
                self.displayError(error)
                self.didEncounterError = true
            }
            dispatch_group_leave(self.saveAccessoryGroup)
        }
    }
    
    /**
        Assigns the given accessory to the provided room. This method will enter and leave the saved dispatch group.
        
        - parameter home:      The home to assign.
        - parameter accessory: The accessory to be assigned.
        - parameter room:      The room to which to assign the accessory.
    */
    func home(home: HMHome, assignAccessory accessory: HMAccessory, toRoom room: HMRoom) {
        if accessory.room == room {
            return
        }
        dispatch_group_enter(saveAccessoryGroup)
        home.assignAccessory(accessory, toRoom: room) { error in
            if let error = error {
                self.displayError(error)
                self.didEncounterError = true
            }
            dispatch_group_leave(self.saveAccessoryGroup)
        }
    }
    
    /// Tells the current accessory to identify itself.
    func identifyAccessory() {
        accessory.identifyWithCompletionHandler { error in
            if let error = error {
                self.displayError(error)
            }
        }
    }
    
    /// Enables the name field if the accessory's name changes.
    func resetNameField() {
        var action: String
        if editingExistingAccessory {
            action = NSLocalizedString("Edit %@", comment: "Edit Accessory")
        }
        else {
            action = NSLocalizedString("Add %@", comment: "Add Accessory")
        }
        navigationItem.title = NSString(format: action, accessory.name) as String
        nameField.text = accessory.name
        nameField.enabled = home.isAdmin
        enableAddButtonIfApplicable()
    }
    
    /// Enables the save button if the name field is not empty.
    func enableAddButtonIfApplicable() {
        addButton.enabled = home.isAdmin && trimmedName.characters.count > 0
    }
    
    /// - returns:  The `nameField`'s text, trimmed of newline and whitespace characters.
    var trimmedName: String {
        return nameField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
    
    /// Enables or disables the add button.
    @IBAction func nameFieldDidChange(sender: AnyObject) {
        enableAddButtonIfApplicable()
    }
    
    // MARK: Table View Methods
    
    /// - returns:  The number of `AddAccessoryTableViewSection`s.
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return AddAccessoryTableViewSection.count
    }
    
    /// - returns: The number rows for the rooms section. All other sections are static.
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch AddAccessoryTableViewSection(rawValue: section) {
            case .Rooms?:
                return home.allRooms.count
                
            case nil:
                fatalError("Unexpected `AddAccessoryTableViewSection` raw value.")
                
            default:
                return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    /// - returns:  `UITableViewAutomaticDimension` for dynamic cell, super otherwise.
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch AddAccessoryTableViewSection(rawValue: indexPath.section) {
            case .Rooms?:
                return UITableViewAutomaticDimension
                
            case nil:
                fatalError("Unexpected `AddAccessoryTableViewSection` raw value.")
                
            default:
                return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
    }
    
    /// - returns:  A 'room cell' for the rooms section, super otherwise.
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch AddAccessoryTableViewSection(rawValue: indexPath.section) {
            case .Rooms?:
                return self.tableView(tableView, roomCellForRowAtIndexPath: indexPath)
                
            case nil:
                fatalError("Unexpected `AddAccessoryTableViewSection` raw value.")
                
            default:
                return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        }
    }
    
    /**
        Creates a cell with the name of each room within the home, displaying a checkmark if the room
        is the currently selected room.
    */
    func tableView(tableView: UITableView, roomCellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.roomCell, forIndexPath: indexPath)
        let room = home.allRooms[indexPath.row] as HMRoom
        
        cell.textLabel?.text = home.nameForRoom(room)
        
        // Put a checkmark on the selected room.
        cell.accessoryType = room == selectedRoom ? .Checkmark : .None
        if !home.isAdmin {
            cell.selectionStyle = .None
        }
        return cell
    }
    
    
    /// Handles row selection based on the section.
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        switch AddAccessoryTableViewSection(rawValue: indexPath.section) {
            case .Rooms?:
                guard home.isAdmin else { return }

                selectedRoom = home.allRooms[indexPath.row]

                let sections = NSIndexSet(index: AddAccessoryTableViewSection.Rooms.rawValue)
                
                tableView.reloadSections(sections, withRowAnimation: .Automatic)
                
            case .Identify?:
                identifyAccessory()
                
            case nil:
                fatalError("Unexpected `AddAccessoryTableViewSection` raw value.")
                
            default: break
        }
    }
    
    /// Required override.
    override func tableView(tableView: UITableView, indentationLevelForRowAtIndexPath indexPath: NSIndexPath) -> Int {
        return super.tableView(tableView, indentationLevelForRowAtIndexPath: NSIndexPath(forRow: 0, inSection: indexPath.section))
    }
    
    // MARK: HMHomeDelegate Methods
    
    // All home changes reload the view.
    
    func home(home: HMHome, didUpdateNameForRoom room: HMRoom) {
        tableView.reloadData()
    }
    
    func home(home: HMHome, didAddRoom room: HMRoom) {
        tableView.reloadData()
    }
    
    func home(home: HMHome, didRemoveRoom room: HMRoom)  {
        if selectedRoom == room {
            // Reset the selected room if ours was deleted.
            selectedRoom = homeStore.home!.roomForEntireHome()
        }
        tableView.reloadData()
    }
    
    func home(home: HMHome, didAddAccessory accessory: HMAccessory) {
        /*
            Bridged accessories don't call the original completion handler if their 
            bridges are added to the home. We must respond to `HMHomeDelegate`'s 
            `home(_:didAddAccessory:)` and assign bridged accessories properly.
        */
        if selectedRoom != nil {
            self.home(home, assignAccessory: accessory, toRoom: selectedRoom)
        }
    }
    
    func home(home: HMHome, didUnblockAccessory accessory: HMAccessory) {
        tableView.reloadData()
    }
    
    // MARK: HMAccessoryDelegate Methods
    
    /// If the accessory's name changes, we update the name field.
    func accessoryDidUpdateName(accessory: HMAccessory) {
        resetNameField()
    }
}
