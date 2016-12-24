/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ZoneViewController` lists the rooms in a zone.
*/

import UIKit
import HomeKit

/// A view controller that lists the rooms within a provided zone.
class ZoneViewController: HMCatalogViewController {
    // MARK: Types
    
    struct Identifiers {
        static let roomCell = "RoomCell"
        static let addCell = "AddCell"
        static let disabledAddCell = "DisabledAddCell"
        static let addRoomsSegue = "Add Rooms"
    }
    
    // MARK: Properties
    
    var homeZone: HMZone!
    var rooms = [HMRoom]()
    
    // MARK: View Methods
    
    /// Reload the data and configure the view.
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        title = homeZone.name
        reloadData()
    }
    
    /// If our data is invalid, pop the view controller.
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if shouldPopViewController() {
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    /// Provide the zone to `AddRoomViewController`.
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        if segue.identifier == Identifiers.addRoomsSegue {
            let addViewController = segue.intendedDestinationViewController as! AddRoomViewController
            addViewController.homeZone = homeZone
        }
    }
    
    // MARK: Helper Methods
    
    /// Resets the internal list of rooms and reloads the table view.
    private func reloadData() {
        rooms = homeZone.rooms.sortByLocalizedName()
        tableView.reloadData()
    }
    
    /// Sorts the internal list of rooms by localized name.
    private func sortRooms() {
        rooms = rooms.sortByLocalizedName()
    }
    
    /// - returns:  The `NSIndexPath` where the 'Add Cell' should be located.
    private var addIndexPath: NSIndexPath {
        return NSIndexPath(forRow: rooms.count, inSection: 0)
    }
    
    /**
        - parameter indexPath: The index path in question.
        
        - returns:  `true` if the indexPath should contain
                    an 'add' cell, `false` otherwise
    */
    private func indexPathIsAdd(indexPath: NSIndexPath) -> Bool {
        return indexPath.row == addIndexPath.row
    }
    
    /**
        Reloads the `addIndexPath`.
        
        This is typically used when something has changed to allow
        the user to add a room.
    */
    private func reloadAddIndexPath() {
        tableView.reloadRowsAtIndexPaths([addIndexPath], withRowAnimation: .Automatic)
    }
    
    /**
        Adds a room to the internal array of rooms and inserts new row
        into the table view.
        
        - parameter room: The new `HMRoom` to add.
    */
    private func didAddRoom(room: HMRoom) {
        rooms.append(room)

        sortRooms()
        
        if let newRoomIndex = rooms.indexOf(room) {
            let newRoomIndexPath = NSIndexPath(forRow: newRoomIndex, inSection: 0)
            tableView.insertRowsAtIndexPaths([newRoomIndexPath], withRowAnimation: .Automatic)
        }
        
        reloadAddIndexPath()
    }
    
    /**
        Removes a room from the internal array of rooms and deletes
        the row from the table view.
        
        - parameter room: The `HMRoom` to remove.
    */
    private func didRemoveRoom(room: HMRoom) {
        if let roomIndex = rooms.indexOf(room) {
            rooms.removeAtIndex(roomIndex)
            let roomIndexPath = NSIndexPath(forRow: roomIndex, inSection: 0)
            tableView.deleteRowsAtIndexPaths([roomIndexPath], withRowAnimation: .Automatic)
        }

        reloadAddIndexPath()
    }
    
    /**
        Reloads the cell corresponding a given room.
        
        - parameter room: The `HMRoom` to reload.
    */
    private func didUpdateRoom(room: HMRoom) {
        if let roomIndex = rooms.indexOf(room) {
            let roomIndexPath = NSIndexPath(forRow: roomIndex, inSection: 0)
            tableView.reloadRowsAtIndexPaths([roomIndexPath], withRowAnimation: .Automatic)
        }
    }
    
    /**
        Removes a room from HomeKit and updates the view.
        
        - parameter room: The `HMRoom` to remove.
    */
    private func removeRoom(room: HMRoom) {
        didRemoveRoom(room)
        homeZone.removeRoom(room) { error in
            if let error = error {
                self.displayError(error)
                self.didAddRoom(room)
            }
        }
    }
    
    /**
        - returns:  `true` if our current home no longer
                    exists, `false` otherwise.
    */
    private func shouldPopViewController() -> Bool {
        for zone in home.zones {
            if zone == homeZone {
                return false
            }
        }
        return true
    }
    
    /**
        - returns:  `true` if more rooms can be added to this zone;
                    `false` otherwise.
    */
    private var canAddRoom: Bool {
        return rooms.count < home.rooms.count
    }
    
    // MARK: Table View Methods
    
    /// - returns:  The number of rooms in the zone, plus 1 for the 'add' row.
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rooms.count + 1
    }
    
    /// - returns:  A cell containing the name of an HMRoom.
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPathIsAdd(indexPath) {
            let reuseIdentifier = home.isAdmin && canAddRoom ? Identifiers.addCell : Identifiers.disabledAddCell

            return tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)
        }

        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.roomCell, forIndexPath: indexPath)
        
        cell.textLabel?.text = rooms[indexPath.row].name
        
        return cell
    }
    
    /**
        - returns:  `true` if the cell is anything but an 'add' cell;
                    `false` otherwise.
    */
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return home.isAdmin && !indexPathIsAdd(indexPath)
    }
    
    /// Deletes the room at the provided index path.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let room = rooms[indexPath.row]

            removeRoom(room)
        }
    }
    
    // MARK: HMHomeDelegate Methods
    
    /// If our zone was removed, pop the view controller.
    func home(home: HMHome, didRemoveZone zone: HMZone) {
        if zone == homeZone{
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    /// If our zone was renamed, update the title.
    func home(home: HMHome, didUpdateNameForZone zone: HMZone) {
        if zone == homeZone {
            title = zone.name
        }
    }

    /// Update the row for the room.
    func home(home: HMHome, didUpdateNameForRoom room: HMRoom) {
        didUpdateRoom(room)
    }
    
    /**
        A room has been added, we may be able to add it to the zone.
        Reload the 'addIndexPath'
    */
    func home(home: HMHome, didAddRoom room: HMRoom) {
        reloadAddIndexPath()
    }
    
    /**
        A room has been removed, attempt to remove it from the room.
        This will always reload the 'addIndexPath'.
    */
    func home(home: HMHome, didRemoveRoom room: HMRoom) {
        didRemoveRoom(room)
    }
    
    /// If the room was added to our zone, add it to the view.
    func home(home: HMHome, didAddRoom room: HMRoom, toZone zone: HMZone) {
        if zone == homeZone {
            didAddRoom(room)
        }
    }
    
    /// If the room was removed from our zone, remove it from the view.
    func home(home: HMHome, didRemoveRoom room: HMRoom, fromZone zone: HMZone) {
        if zone == homeZone {
            didRemoveRoom(room)
        }
    }
}
