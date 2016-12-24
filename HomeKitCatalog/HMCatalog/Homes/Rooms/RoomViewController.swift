/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `RoomViewController` lists the accessory within a room.
*/


import UIKit
import HomeKit

/// A view controller that lists the accessories within a room.
class RoomViewController: HMCatalogViewController, HMAccessoryDelegate {
    // MARK: Types
    
    struct Identifiers {
        static let accessoryCell = "AccessoryCell"
        static let unreachableAccessoryCell = "UnreachableAccessoryCell"
        static let modifyAccessorySegue = "Modify Accessory"
    }
    
    // MARK: Properties
    
    var room: HMRoom! {
        didSet {
            navigationItem.title = room.name
        }
    }
    
    var accessories = [HMAccessory]()
    
    // MARK: View Methods
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
    
    // MARK: Table View Methods
    
    /// - returns:  The number of accessories within this room.
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rows = accessories.count
        if rows == 0 {
            let message = NSLocalizedString("No Accessories", comment: "No Accessories")
            setBackgroundMessage(message)
        }
        else {
            setBackgroundMessage(nil)
        }

        return rows
    }
    
    /// - returns:  `true` if the current room is not the home's roomForEntireHome; `false` otherwise.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return room != home.roomForEntireHome()
    }
    
    /// - returns:  Localized "Unassign".
    override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return NSLocalizedString("Unassign", comment: "Unassign")
    }
    
    /// Assigns the 'deleted' room to the home's roomForEntireHome.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            unassignAccessory(accessories[indexPath.row])
        }
    }
    
    /// - returns:  A cell representing an accessory.
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let accessory = accessories[indexPath.row]

        var reuseIdentifier = Identifiers.accessoryCell
        
        if !accessory.reachable {
            reuseIdentifier = Identifiers.unreachableAccessoryCell
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)
        
        cell.textLabel?.text = accessory.name
        
        return cell
    }
    
    /// - returns:  A localized description, "Accessories" if there are accessories to list.
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if accessories.isEmpty {
            return nil
        }

        return NSLocalizedString("Accessories", comment: "Accessories")
    }
    
    // MARK: Helper Methods
    
    /// Updates the internal array of accessories and reloads the table view.
    private func reloadData() {
        accessories = room.accessories.sortByLocalizedName()
        tableView.reloadData()
    }
    
    /// Sorts the internal list of accessories by localized name.
    private func sortAccessories() {
        accessories = accessories.sortByLocalizedName()
    }
    
    /**
        Registers as the delegate for the current home and
        all accessories in our room.
    */
    override func registerAsDelegate() {
        super.registerAsDelegate()
        for accessory in room.accessories {
            accessory.delegate = self
        }
    }
    
    /// Sets the accessory and home of the modifyAccessoryViewController that will be presented.
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        let indexPath = tableView.indexPathForCell(sender as! UITableViewCell)!
        if segue.identifier == Identifiers.modifyAccessorySegue {
            let modifyViewController = segue.intendedDestinationViewController as! ModifyAccessoryViewController
            modifyViewController.accessory = room.accessories[indexPath.row]
        }
    }
    
    /**
        Adds an accessory into the internal list of accessories
        and inserts the row into the table view.
    
        - parameter accessory: The `HMAccessory` to add.
    */
    private func didAssignAccessory(accessory: HMAccessory) {
        accessories.append(accessory)
        sortAccessories()
        if let newAccessoryIndex = accessories.indexOf(accessory) {
            let newAccessoryIndexPath = NSIndexPath(forRow: newAccessoryIndex, inSection: 0)
            tableView.insertRowsAtIndexPaths([newAccessoryIndexPath], withRowAnimation: .Automatic)
        }
    }
    
    /**
        Removes an accessory from the internal list of accessory (if it
        exists) and deletes the row from the table view.
    
        - parameter accessory: The `HMAccessory` to remove.
    */
    private func didUnassignAccessory(accessory: HMAccessory) {
        if let accessoryIndex = accessories.indexOf(accessory) {
            accessories.removeAtIndex(accessoryIndex)
            let accessoryIndexPath = NSIndexPath(forRow: accessoryIndex, inSection: 0)
            tableView.deleteRowsAtIndexPaths([accessoryIndexPath], withRowAnimation: .Automatic)
        }
    }
    
    /**
        Assigns an accessory to the current room.
    
        - parameter accessory: The `HMAccessory` to assign to the room.
    */
    private func assignAccessory(accessory: HMAccessory) {
        didAssignAccessory(accessory)
        home.assignAccessory(accessory, toRoom: room) { error in
            if let error = error {
                self.displayError(error)
                self.didUnassignAccessory(accessory)
            }
        }
    }
    
    /**
        Assigns the current room back into `roomForEntireHome`.
    
        - parameter accessory: The `HMAccessory` to reassign.
    */
    private func unassignAccessory(accessory: HMAccessory) {
        didUnassignAccessory(accessory)
        home.assignAccessory(accessory, toRoom: home.roomForEntireHome()) { error in
            if let error = error {
                self.displayError(error)
                self.didAssignAccessory(accessory)
            }
        }
    }
    
    /**
        Finds an accessory in the internal array of accessories
        and updates its row in the table view.
    
        - parameter accessory: The `HMAccessory` to reload.
    */
    func didModifyAccessory(accessory: HMAccessory){
        if let index = accessories.indexOf(accessory) {
            let indexPaths = [
                NSIndexPath(forRow: index, inSection: 0)
            ]
            
            tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
        }
    }
    
    // MARK: HMHomeDelegate Methods
    
    /// If the accessory was added to this room, insert it.
    func home(home: HMHome, didAddAccessory accessory: HMAccessory) {
        if accessory.room == room {
            accessory.delegate = self
            didAssignAccessory(accessory)
        }
    }
    
    /// Remove the accessory from our room, if required.
    func home(home: HMHome, didRemoveAccessory accessory: HMAccessory) {
        didUnassignAccessory(accessory)
    }
    
    /**
        Handles the update.
        
        We act based on one of three options:
        
        1. A new accessory is being added to this room.
        2. An accessory is being assigned from this room to another room.
        3. We can ignore this message.
    */
    func home(home: HMHome, didUpdateRoom room: HMRoom, forAccessory accessory: HMAccessory) {
        if room == self.room {
            didAssignAccessory(accessory)
        }
        else if accessories.contains(accessory)  {
            didUnassignAccessory(accessory)
        }
    }
    
    /// If our room was removed, pop back.
    func home(home: HMHome, didRemoveRoom room: HMRoom) {
        if room == self.room {
            navigationController!.popViewControllerAnimated(true)
        }
    }
    
    /// If our room was renamed, reload our title.
    func home(home: HMHome, didUpdateNameForRoom room: HMRoom) {
        if room == self.room {
            navigationItem.title = room.name
        }
    }
    
    // MARK: HMAccessoryDelegate Methods
    
    // Accessory updates will reload the cell for the accessory.

    func accessoryDidUpdateReachability(accessory: HMAccessory) {
        didModifyAccessory(accessory)
    }
    
    func accessoryDidUpdateName(accessory: HMAccessory) {
        didModifyAccessory(accessory)
    }
}
