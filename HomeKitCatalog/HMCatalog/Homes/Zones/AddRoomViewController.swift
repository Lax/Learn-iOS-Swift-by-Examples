/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `AddRoomViewController` allows the user to add rooms to a zone.
*/

import UIKit
import HomeKit

/// A view controller that lists rooms within a home and allows the user to add the rooms to a provided zone.
class AddRoomViewController: HMCatalogViewController {
    // MARK: Types
    
    struct Identifiers {
        static let roomCell = "RoomCell"
    }
    
    // MARK: Properties
    
    var homeZone: HMZone!
    
    lazy var displayedRooms = [HMRoom]()
    lazy var selectedRooms = [HMRoom]()
    
    // MARK: View Methods
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        title = homeZone.name
        resetDisplayedRooms()
    }
    
    /// Adds the selected rooms to the zone and dismisses the view.
    @IBAction func dismiss(sender: AnyObject) {
        addSelectedRoomsToZoneWithCompletionHandler {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    /**
        Creates a dispatch group, adds all of the rooms to the zone,
        and runs the provided completion once all rooms have been added.
        
        - parameter completion: A closure to call once all rooms have been added.
    */
    func addSelectedRoomsToZoneWithCompletionHandler(completion: () -> Void) {
        let group = dispatch_group_create()
        for room in selectedRooms {
            dispatch_group_enter(group)
            homeZone.addRoom(room) { error in
                if let error = error {
                    self.displayError(error)
                }
                dispatch_group_leave(group)
            }
        }
        dispatch_group_notify(group, dispatch_get_main_queue(), completion)
    }
    
    // MARK: Table View Methods
    
    /// - returns:  The number of displayed rooms.
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedRooms.count
    }
    
    /// - returns:  A cell that includes the name of a room and a checkmark if it's intended to be added to the zone.
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.roomCell, forIndexPath: indexPath)
        
        let room = displayedRooms[indexPath.row]

        cell.textLabel?.text = room.name
        cell.accessoryType = selectedRooms.contains(room)  ? .Checkmark : .None
        
        return cell
    }
    
    /// Adds the selected room to the selected rooms array and reloads that cell
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let room = displayedRooms[indexPath.row]

        if let index = selectedRooms.indexOf(room) {
            selectedRooms.removeAtIndex(index)
        }
        else {
            selectedRooms.append(room)
        }

        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    /// Resets the list of displayed rooms and reloads the table.
    func resetDisplayedRooms() {
        displayedRooms = home.roomsNotAlreadyInZone(homeZone, includingRooms: selectedRooms)
        if displayedRooms.isEmpty {
            dismissViewControllerAnimated(true, completion: nil)
        }
        else {
            tableView.reloadData()
        }
    }
    
    // MARK: HMHomeDelegate Methods
    
    /// If our zone was removed, dismiss this view.
    func home(home: HMHome, didRemoveZone zone: HMZone) {
        if zone == homeZone {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    /// If our zone was renamed, reset our title.
    func home(home: HMHome, didUpdateNameForZone zone: HMZone) {
        if zone == homeZone {
            title = zone.name
        }
    }
    
    // All home updates reset the displayed homes and reload the view.
    
    func home(home: HMHome, didUpdateNameForRoom room: HMRoom) {
        resetDisplayedRooms()
    }
    
    func home(home: HMHome, didAddRoom room: HMRoom) {
        resetDisplayedRooms()
    }
    
    func home(home: HMHome, didRemoveRoom room: HMRoom) {
        resetDisplayedRooms()
    }
    
    func home(home: HMHome, didAddRoom room: HMRoom, toZone zone: HMZone) {
        resetDisplayedRooms()
    }
    
    func home(home: HMHome, didRemoveRoom room: HMRoom, fromZone zone: HMZone) {
        resetDisplayedRooms()
    }
}
