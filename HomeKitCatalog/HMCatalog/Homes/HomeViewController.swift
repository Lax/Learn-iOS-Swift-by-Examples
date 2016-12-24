/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `HomeViewController` displays all of the HomeKit objects in a selected home.
*/

import Foundation
import UIKit
import HomeKit

/// Distinguishes between the three types of cells in the `HomeViewController`.
enum HomeCellType {
    /// Represents an actual object in HomeKit.
    case Object
    
    /// Represents an "Add" row for users to select to create an object in HomeKit.
    case Add
    
    /// The cell is displaying text to show the user that no objects exist in this section.
    case None
}

/**
    A view controller that displays all elements within a home.
    It contains separate sections for Accessories, Rooms, Zones, Action Sets,
    Triggers, and Service Groups.
*/
class HomeViewController: HMCatalogViewController, HMAccessoryDelegate {
    // MARK: Types
    
    struct Identifiers {
        static let addCell = "AddCell"
        static let disabledAddCell = "DisabledAddCell"
        static let accessoryCell = "AccessoryCell"
        static let unreachableAccessoryCell = "UnreachableAccessoryCell"
        static let roomCell = "RoomCell"
        static let zoneCell = "ZoneCell"
        static let userCell = "UserCell"
        static let actionSetCell = "ActionSetCell"
        static let triggerCell = "TriggerCell"
        static let serviceGroupCell = "ServiceGroupCell"
        static let addTimerTriggerSegue = "Add Timer Trigger"
        static let addCharacteristicTriggerSegue = "Add Characteristic Trigger"
        static let addLocationTriggerSegue = "Add Location Trigger"
        static let addActionSetSegue = "Add Action Set"
        static let addAccessoriesSegue = "Add Accessories"
        static let showRoomSegue = "Show Room"
        static let showZoneSegue = "Show Zone"
        static let showActionSetSegue = "Show Action Set"
        static let showServiceGroupSegue = "Show Service Group"
        static let showAccessorySegue = "Show Accessory"
        static let modifyAccessorySegue = "Modify Accessory"
        static let showTimerTriggerSegue = "Show Timer Trigger"
        static let showLocationTriggerSegue = "Show Location Trigger"
        static let showCharacteristicTriggerSegue = "Show Characteristic Trigger"
    }
    
    // MARK: Properties
    
    /// A structure to maintain internal arrays of HomeKit objects.
    private var objectCollection = HomeKitObjectCollection()
    
    // MARK: View Methods
    
    /**
        Determines the destination of the segue and passes the correct
        HomeKit object onto the next view controller.
    */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let sender = sender as? UITableViewCell else { return }
        guard let indexPath = tableView.indexPathForCell(sender) else { return }
        
        let homeKitObject = homeKitObjectAtIndexPath(indexPath)
        let destinationViewController = segue.intendedDestinationViewController
        
        switch segue.identifier! {
            case Identifiers.showRoomSegue:
                let roomVC = destinationViewController as! RoomViewController
                roomVC.room = homeKitObject as? HMRoom
                
            case Identifiers.showZoneSegue:
                let zoneViewController = destinationViewController as! ZoneViewController
                zoneViewController.homeZone = homeKitObject as? HMZone
                
            case Identifiers.showActionSetSegue:
                let actionSetVC = destinationViewController as! ActionSetViewController
                actionSetVC.actionSet = homeKitObject as? HMActionSet
                
            case Identifiers.showServiceGroupSegue:
                let serviceGroupVC = destinationViewController as! ServiceGroupViewController
                serviceGroupVC.serviceGroup = homeKitObject as? HMServiceGroup
                
            case Identifiers.showAccessorySegue:
                let detailVC = destinationViewController as! ServicesViewController
                /*
                    The services view controller is generic, we need to provide 
                    `showsFavorites` to display the stars next to characteristics.
                */
                detailVC.accessory = homeKitObject as? HMAccessory
                detailVC.showsFavorites = true
                detailVC.cellDelegate = AccessoryUpdateController()
                
            case Identifiers.modifyAccessorySegue:
                let addAccessoryVC = destinationViewController as! ModifyAccessoryViewController
                addAccessoryVC.accessory = homeKitObject as? HMAccessory
                
            case Identifiers.showTimerTriggerSegue:
                let triggerVC = destinationViewController as! TimerTriggerViewController
                triggerVC.trigger = homeKitObject as? HMTimerTrigger
                
            case Identifiers.showLocationTriggerSegue:
                let triggerVC = destinationViewController as! LocationTriggerViewController
                triggerVC.trigger = homeKitObject as? HMEventTrigger
                
            case Identifiers.showCharacteristicTriggerSegue:
                let triggerVC = destinationViewController as! CharacteristicTriggerViewController
                triggerVC.trigger = homeKitObject as? HMEventTrigger
                
            default:
                print("Received unknown segue identifier: \(segue.identifier).")
        }
    }
    
    /// Configures the table view.
    override func awakeFromNib() {
        super.awakeFromNib()
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    /// Sets the navigation title and reloads view.
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = home.name
        reloadTable()
    }
    
    // MARK: Delegate Registration
    
    /**
        Registers as the delegate for the home store's current home
        and all accessories in the home.
    */
    override func registerAsDelegate() {
        super.registerAsDelegate()

        for accessory in home.accessories {
            accessory.delegate = self
        }
    }
    
    // MARK: Helper Methods
    
    /// Resets the object collection and reloads the view.
    private func reloadTable() {
        objectCollection.resetWithHome(home)
        tableView.reloadData()
    }
    
    /**
        Determines the type of the cell based on the index path.
        
        - parameter indexPath: The `NSIndexPath` of the cell.
        
        - returns:  The `HomeCellType` for cell.
    */
    private func cellTypeForIndexPath(indexPath: NSIndexPath) -> HomeCellType {
        guard let section = HomeKitObjectSection(rawValue: indexPath.section) else { return .None }
        
        let objectCount = objectCollection.objectsForSection(section).count

        if objectCount == 0 {
            // No objects -- this is either an 'Add Row' or a 'None Row'.
            return home.isAdmin ? .Add : .None
        }
        else if indexPath.row == objectCount {
            return .Add
        }
        else {
            return .Object
        }
    }
    
    /// Reloads the trigger section.
    private func updateTriggerAddRow() {
        let triggerSection = NSIndexSet(index: HomeKitObjectSection.Trigger.rawValue)
     
        tableView.reloadSections(triggerSection, withRowAnimation: .Automatic)
    }
    
    /// Reloads the action set section.
    private func updateActionSetSection() {
        let actionSetSection = NSIndexSet(index: HomeKitObjectSection.ActionSet.rawValue)
     
        tableView.reloadSections(actionSetSection, withRowAnimation: .Automatic)
        
        updateTriggerAddRow()
    }
    
    /// - returns:  `true` if there are accessories within the home; `false` otherwise.
    private var canAddActionSet: Bool {
        return !objectCollection.accessories.isEmpty
    }
    
    /// - returns:  `true` if there are action sets (with actions) within the home; `false` otherwise.
    private var canAddTrigger: Bool {
        return objectCollection.actionSets.contains { actionSet in
            return !actionSet.actions.isEmpty
        }
    }
    
    /**
        Provides the 'HomeKit object' (`AnyObject?`) at the specified index path.
        
        - parameter indexPath: The `NSIndexPath` of the object.
        
        - returns:  The HomeKit object.
    */
    private func homeKitObjectAtIndexPath(indexPath: NSIndexPath) -> AnyObject? {
        if cellTypeForIndexPath(indexPath) != .Object {
            return nil
        }
        
        if let section = HomeKitObjectSection(rawValue: indexPath.section) {
            return objectCollection.objectsForSection(section)[indexPath.row]
        }
        
        return nil
    }
    
    // MARK: Table View Methods
    
    /// - returns:  The number of `HomeKitObjectSection`s.
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return HomeKitObjectSection.count
    }
    
    /// - returns:  Localized titles for each of the HomeKit sections.
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch HomeKitObjectSection(rawValue: section) {
            case .Accessory?:
                return NSLocalizedString("Accessories", comment: "Accessories")
                
            case .Room?:
                return NSLocalizedString("Rooms", comment: "Rooms")
                
            case .Zone?:
                return NSLocalizedString("Zones", comment: "Zones")
                
            case .User?:
                return NSLocalizedString("Users", comment: "Users")
                
            case .ActionSet?:
                return NSLocalizedString("Scenes", comment: "Scenes")
                
            case .Trigger?:
                return NSLocalizedString("Triggers", comment: "Triggers")
                
            case .ServiceGroup?:
                return NSLocalizedString("Service Groups", comment: "Service Groups")
            
            case nil:
                fatalError("Unexpected `HomeKitObjectSection` raw value.")
        }
        
    }
    
    /// - returns:  Localized text for the 'add row'.
    private func titleForAddRowInSection(section: HomeKitObjectSection) -> String {
        switch section {
            case .Accessory:
                return NSLocalizedString("Add Accessory…", comment: "Add Accessory")

            case .Room:
                return NSLocalizedString("Add Room…", comment: "Add Room")
            
            case .Zone:
                return NSLocalizedString("Add Zone…", comment: "Add Zone")
            
            case .User:
                return NSLocalizedString("Manage Users…", comment: "Manage Users")
            
            case .ActionSet:
                return NSLocalizedString("Add Scene…", comment: "Add Scene")
            
            case .Trigger:
                return NSLocalizedString("Add Trigger…", comment: "Add Trigger")
            
            case .ServiceGroup:
                return NSLocalizedString("Add Service Group…", comment: "Add Service Group")
        }
    }
    
    /// - returns:  Localized text for the 'none row'.
    private func titleForNoneRowInSection(section: HomeKitObjectSection) -> String {
        switch section {
            case .Accessory:
                return NSLocalizedString("No Accessories…", comment: "No Accessories")

            case .Room:
                return NSLocalizedString("No Rooms…", comment: "No Rooms")
            
            case .Zone:
                return NSLocalizedString("No Zones…", comment: "No Zones")
            
            case .User:
                // We only ever list 'Manage Users'.
                return NSLocalizedString("Manage Users…", comment: "Manage Users")
            
            case .ActionSet:
                return NSLocalizedString("No Scenes…", comment: "No Scenes")
            
            case .Trigger:
                return NSLocalizedString("No Triggers…", comment: "No Triggers")
            
            case .ServiceGroup:
                return NSLocalizedString("No Service Groups…", comment: "No Service Groups")
        }
    }
    
    /// - returns:  Localized descriptions for HomeKit object types.
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch HomeKitObjectSection(rawValue: section) {
            case .Zone?:
                return NSLocalizedString("Zones are optional collections of rooms.", comment: "Zones Description")
                
            case .User?:
                return NSLocalizedString("Users can control the accessories in your home. You can share your home with anybody with an iCloud account.", comment: "Users Description")
                
            case .ActionSet?:
                return NSLocalizedString("Scenes (action sets) represent a state of your home. You must have at least one paired accessory to create a scene.", comment: "Scenes Description")
                
            case .Trigger?:
                return NSLocalizedString("Triggers set scenes at specific times, when you get to locations, or when a characteristic is in a specific state. You must have created at least one scene with an action to create a trigger.", comment: "Trigger Description")
                
            case .ServiceGroup?:
                return NSLocalizedString("Service groups organize services in a custom way. For example, add a subset of lights in your living room to control them without controlling all the lights in the living room.", comment: "Service Group Description")

            case nil:
                fatalError("Unexpected `HomeKitObjectSection` raw value.")
            
            default:
                return nil
        }
    }
    
    /**
        Provides the number of rows in each HomeKit object section.
        Most sections just return the object count, but we also handle special cases.
    */
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionEnum = HomeKitObjectSection(rawValue: section)!
        
        // Only "Manage Users" button is in the Users section
        if sectionEnum == .User {
            return 1
        }
        
        let objectCount = objectCollection.objectsForSection(sectionEnum).count
        if home.isAdmin {
            // For add row.
            return objectCount + 1
        }
        else {
            // Always show at least one row in the section.
            return max(objectCount, 1)
        }
    }
    
    /// Generates a cell based on it's computed type.
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch cellTypeForIndexPath(indexPath) {
            case .Add:
                return self.tableView(tableView, addCellForRowAtIndexPath: indexPath)
            
            case .Object: 
                return self.tableView(tableView, homeKitObjectCellForRowAtIndexPath: indexPath)
            
            case .None: 
                return self.tableView(tableView, noneCellForRowAtIndexPath: indexPath)
        }
    }
    
    /// Generates a 'none cell' with a localized title.
    private func tableView(tableView: UITableView, noneCellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.disabledAddCell, forIndexPath: indexPath)

        let section = HomeKitObjectSection(rawValue: indexPath.section)!
        
        cell.textLabel!.text = titleForNoneRowInSection(section)
        
        return cell
    }
    
    /**
        Generates an 'add cell' with a localized title.
        
        In some cases, the 'add cell' will be 'disabled' because the user is not
        allowed to perform the action.
    */
    private func tableView(tableView: UITableView, addCellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var reuseIdentifier = Identifiers.addCell

        let section = HomeKitObjectSection(rawValue: indexPath.section)

        if (!canAddActionSet && section == .ActionSet) ||
            (!canAddTrigger && section == .Trigger) || !home.isAdmin {
                reuseIdentifier = Identifiers.disabledAddCell
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)
        
        cell.textLabel!.text = titleForAddRowInSection(section!)
        
        return cell
    }
    
    /**
        Produces the cell reuse identifier based on the section.
        
        - parameter indexPath: The `NSIndexPath` of the cell.
        
        - returns:  The cell reuse identifier.
    */
    private func reuseIdentifierForIndexPath(indexPath: NSIndexPath) -> String {
        switch HomeKitObjectSection(rawValue: indexPath.section) {
            case .Accessory?:
                let accessory = homeKitObjectAtIndexPath(indexPath) as! HMAccessory
                return accessory.reachable ? Identifiers.accessoryCell : Identifiers.unreachableAccessoryCell
                
            case .Room?:
                return Identifiers.roomCell
                
            case .Zone?:
                return Identifiers.zoneCell
                
            case .User?:
                return Identifiers.userCell
                
            case .ActionSet?:
                return Identifiers.actionSetCell
                
            case .Trigger?:
                return Identifiers.triggerCell
                
            case .ServiceGroup?:
                return Identifiers.serviceGroupCell
                
            case nil:
                fatalError("Unexpected `HomeKitObjectSection` raw value.")
        }
    }
    
    /// Generates a cell for the HomeKit object at the specified index path.
    private func tableView(tableView: UITableView, homeKitObjectCellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Grab the object associated with this indexPath.
        let homeKitObject = homeKitObjectAtIndexPath(indexPath)
        
        // Get the name of the object.
        let name: String
        switch HomeKitObjectSection(rawValue: indexPath.section) {
            case .Accessory?:
                let accessory = homeKitObject as! HMAccessory
                name = accessory.name
                
            case .Room?:
                let room = homeKitObject as! HMRoom
                name = self.home.nameForRoom(room)
                
            case .Zone?:
                let zone = homeKitObject as! HMZone
                name = zone.name
            case .User?:
                name = ""
                
            case .ActionSet?:
                let actionSet = homeKitObject as! HMActionSet
                name = actionSet.name
                
            case .Trigger?:
                let trigger = homeKitObject as! HMTrigger
                name = trigger.name
                
            case .ServiceGroup?:
                let serviceGroup = homeKitObject as! HMServiceGroup
                name = serviceGroup.name
                
            case nil:
                fatalError("Unexpected `HomeKitObjectSection` raw value.")
        }

        
        // Grab the appropriate reuse identifier for this index path.
        let reuseIdentifier = reuseIdentifierForIndexPath(indexPath)
        
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)
        cell.textLabel?.text = name

        return cell
    }
    
    /// Allows users to remove HomeKit object rows if they are the admin of the home.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let homeKitObject = homeKitObjectAtIndexPath(indexPath)

        if !home.isAdmin {
            return false
        }
        
        if let actionSet = homeKitObject as? HMActionSet where actionSet.isBuiltIn {
            // We cannot remove built-in action sets.
            return false
        }
        
        // Any row that is not an 'add' row, and is not the roomForEntireHome, can be removed.
        return !(homeKitObject as? NSObject == home.roomForEntireHome() || cellTypeForIndexPath(indexPath) == .Add)
    }
    
    /// Removes the HomeKit object at the specified index path.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let homeKitObject = homeKitObjectAtIndexPath(indexPath)!
            
            // Remove the object from the data structure. If it fails put it back.
            didRemoveHomeKitObject(homeKitObject)
            removeHomeKitObject(homeKitObject) { error in
                guard let error = error else { return }

                self.displayError(error)
                self.didAddHomeKitObject(homeKitObject)
            }
        }
    }
    
    /// Handles cell selection based on the cell type.
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let cell = tableView.cellForRowAtIndexPath(indexPath)!

        guard cell.selectionStyle != .None else { return }
        
        guard let section = HomeKitObjectSection(rawValue: indexPath.section) else {
            fatalError("Unexpected `HomeKitObjectSection` raw value.")
        }
        
        if cellTypeForIndexPath(indexPath) == .Add{
            switch section {
                case .Accessory:
                    browseForAccessories()

                case .Room:
                    addNewRoom()
                
                case .Zone:
                    addNewZone()
                
                case .User:
                    manageUsers()
                
                case .ActionSet:
                    addNewActionSet()
                
                case .Trigger:
                    addNewTrigger()
                
                case .ServiceGroup:
                    addNewServiceGroup()
            }
        }
        else if section == .ActionSet {
            let selectedActionSet = homeKitObjectAtIndexPath(indexPath) as! HMActionSet
            executeActionSet(selectedActionSet)
        }
    }
    
    /// Handles an accessory button tap based on the section.
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)

        if HomeKitObjectSection(rawValue: indexPath.section) == .Trigger {
            let trigger = homeKitObjectAtIndexPath(indexPath)

            switch trigger {
                case is HMTimerTrigger:
                    performSegueWithIdentifier(Identifiers.showTimerTriggerSegue, sender: cell)

                case let eventTrigger as HMEventTrigger:
                    if eventTrigger.isLocationEvent {
                        performSegueWithIdentifier(Identifiers.showLocationTriggerSegue, sender: cell)
                    }
                    else {
                        performSegueWithIdentifier(Identifiers.showCharacteristicTriggerSegue, sender: cell)
                    }
                
                default: break
            }
        }
    }
    
    // MARK: Action Methods
    
    /// Presents an alert controller to allow the user to choose a trigger type.
    private func addNewTrigger() {
        let title = NSLocalizedString("Add Trigger", comment: "Add Trigger")
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .ActionSheet)
        
        // Timer trigger
        let timeAction = UIAlertAction(title: NSLocalizedString("Time", comment: "Time"), style: .Default) { _ in
            self.performSegueWithIdentifier(Identifiers.addTimerTriggerSegue, sender: self)
        }
        alertController.addAction(timeAction)
        
        // Characteristic trigger
        let eventAction = UIAlertAction(title: NSLocalizedString("Characteristic", comment: "Characteristic"), style: .Default) { _ in
            self.performSegueWithIdentifier(Identifiers.addCharacteristicTriggerSegue, sender: self)
        }
        alertController.addAction(eventAction)
        
        // Location trigger
        let locationAction = UIAlertAction(title: NSLocalizedString("Location", comment: "Location"), style: .Default) { _ in
            self.performSegueWithIdentifier(Identifiers.addLocationTriggerSegue, sender: self)
        }
        alertController.addAction(locationAction)
        
        // Cancel
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // Present alert
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    /// Navigates into the action set view controller.
    private func addNewActionSet() {
        performSegueWithIdentifier(Identifiers.addActionSetSegue, sender: self)
    }
    
    /// Navigates into the browse accessory view controller.
    private func browseForAccessories() {
        performSegueWithIdentifier(Identifiers.addAccessoriesSegue, sender: self)
    }
    
    // MARK: Dialog Creation Methods
    
    /// Presents a dialog to name a new room and generates the HomeKit object if committed.
    private func addNewRoom() {
        presentAddAlertWithAttributeType(NSLocalizedString("Room", comment: "Room"),
            placeholder: NSLocalizedString("Living Room", comment: "Living Room")) { roomName in
                self.addRoomWithName(roomName)
        }
    }
    
    /// Presents a dialog to name a new service group and generates the HomeKit object if committed.
    private func addNewServiceGroup() {
        presentAddAlertWithAttributeType(NSLocalizedString("Service Group", comment: "Service Group"),
            placeholder: NSLocalizedString("Group", comment: "Group")) { groupName in
                self.addServiceGroupWithName(groupName)
        }
    }
    
    /// Presents a dialog to name a new zone and generates the HomeKit object if committed.
    private func addNewZone() {
        presentAddAlertWithAttributeType(NSLocalizedString("Zone", comment: "Zone"),
            placeholder: NSLocalizedString("Upstairs", comment: "Upstairs")) { zoneName in
                self.addZoneWithName(zoneName)
        }
    }
    
    // MARK: HomeKit Object Creation and Deletion
    
    /**
        Switches based on the type of object attempts to remove the HomeKit object
        from the curret home.
        
        - parameter object: The HomeKit object to remove.
        - parameter completionHandler: The closure to invote when the removal has been completed.
    */
    private func removeHomeKitObject(object: AnyObject, completionHandler: NSError? -> Void) {
        switch object {
            case let actionSet as HMActionSet:
                home.removeActionSet(actionSet) { error in
                    completionHandler(error)
                    self.updateActionSetSection()
                }
                
            case let accessory as HMAccessory:
                home.removeAccessory(accessory, completionHandler: completionHandler)
                
            case let room as HMRoom:
                home.removeRoom(room, completionHandler: completionHandler)
                
            case let zone as HMZone:
                home.removeZone(zone, completionHandler: completionHandler)
                
            case let trigger as HMTrigger:
                home.removeTrigger(trigger, completionHandler: completionHandler)
                
            case let serviceGroup as HMServiceGroup:
                home.removeServiceGroup(serviceGroup, completionHandler: completionHandler)
                
            default:
                fatalError("Attempted to remove unknown HomeKit object.")
        }
    }
    
    /**
        Adds a room to the current home.
        
        - parameter name: The name of the new room.
    */
    private func addRoomWithName(name: String) {
        home.addRoomWithName(name) { newRoom, error in
            if let error = error {
                self.displayError(error)
                return
            }

            self.didAddHomeKitObject(newRoom)
        }
    }
    
    /**
        Adds a service group to the current home.
        
        - parameter name: The name of the new service group.
    */
    private func addServiceGroupWithName(name: String) {
        home.addServiceGroupWithName(name) { newGroup, error in
            if let error = error {
                self.displayError(error)
                return
            }

            self.didAddHomeKitObject(newGroup)
        }
    }
    
    /**
        Adds a zone to the current home.
        
        - parameter name: The name of the new zone.
    */
    private func addZoneWithName(name: String) {
        home.addZoneWithName(name) { newZone, error in
            if let error = error {
                self.displayError(error)
                return
            }

            self.didAddHomeKitObject(newZone)
        }
    }
    
    /// Presents modal view for managing users.
    private func manageUsers() {
        home.manageUsersWithCompletionHandler { error in
            if let error = error {
                self.displayError(error)
            }
        }
    }
    
    /**
        Checks to see if an action set has any actions.
        If actions exists, the action set will be executed.
        Otherwise, the user will be alerted.
        
        - parameter actionSet: The `HMActionSet` to evaluate and execute.
    */
    private func executeActionSet(actionSet: HMActionSet) {
        if actionSet.actions.isEmpty {
            let alertTitle = NSLocalizedString("Empty Scene", comment: "Empty Scene")

            let alertMessage = NSLocalizedString("This scene is empty. To set this scene, first add some actions to it.", comment: "Empty Scene Description")
            
            displayMessage(alertTitle, message: alertMessage)
            
            return
        }

        home.executeActionSet(actionSet) { error in
            guard let error = error else { return }
            
            self.displayError(error)
        }
    }
    
    /**
        Adds the HomeKit object into the object collection and inserts the new row into the section.
    
        - parameter object: The HomeKit object to add.
    */
    private func didAddHomeKitObject(object: AnyObject?) {
        if let object = object {
            objectCollection.append(object)
            if let newObjectIndexPath = objectCollection.indexPathOfObject(object) {
                tableView.insertRowsAtIndexPaths([newObjectIndexPath], withRowAnimation: .Automatic)
            }
        }
    }
    
    /**
        Finds the `NSIndexPath` of the specified object and reloads it in the table view.
    
        - parameter object: The HomeKit object that was modified.
    */
    private func didModifyHomeKitObject(object: AnyObject?) {
        if let object = object,
               objectIndexPath = objectCollection.indexPathOfObject(object) {
            tableView.reloadRowsAtIndexPaths([objectIndexPath], withRowAnimation: .Automatic)
        }
    }
    
    /**
        Removes the HomeKit object from the object collection and then deletes the row from the section.
        
        - parameter object: The HomeKit object to remove.
    */
    private func didRemoveHomeKitObject(object: AnyObject?) {
        if let object = object,
               objectIndexPath = objectCollection.indexPathOfObject(object) {
            objectCollection.remove(object)
            tableView.deleteRowsAtIndexPaths([objectIndexPath], withRowAnimation: .Automatic)
        }
    }
    
    /*
        The following methods call the above helper methds to handle
        the addition, removal, and modification of HomeKit objects.
    */
    
    // MARK: HMHomeDelegate Methods
    
    func homeDidUpdateName(home: HMHome) {
        navigationItem.title = home.name
        reloadTable()
    }
    
    func home(home: HMHome, didAddAccessory accessory: HMAccessory) {
        didAddHomeKitObject(accessory)
        accessory.delegate = self
    }
    
    func home(home: HMHome, didRemoveAccessory accessory: HMAccessory) {
        didRemoveHomeKitObject(accessory)
    }
    
    // MARK: Triggers
    
    func home(home: HMHome, didAddTrigger trigger: HMTrigger) {
        didAddHomeKitObject(trigger)
    }
    
    func home(home: HMHome, didRemoveTrigger trigger: HMTrigger) {
        didRemoveHomeKitObject(trigger)
    }
    
    func home(home: HMHome, didUpdateNameForTrigger trigger: HMTrigger) {
        didModifyHomeKitObject(trigger)
    }
    
    // MARK: Service Groups
    
    func home(home: HMHome, didAddServiceGroup group: HMServiceGroup) {
        didAddHomeKitObject(group)
    }
    
    func home(home: HMHome, didRemoveServiceGroup group: HMServiceGroup) {
        didRemoveHomeKitObject(group)
    }
    
    func home(home: HMHome, didUpdateNameForServiceGroup group: HMServiceGroup) {
        didModifyHomeKitObject(group)
    }
    
    // MARK: Action Sets
    
    func home(home: HMHome, didAddActionSet actionSet: HMActionSet) {
        didAddHomeKitObject(actionSet)
    }
    
    func home(home: HMHome, didRemoveActionSet actionSet: HMActionSet) {
        didRemoveHomeKitObject(actionSet)
    }
    
    func home(home: HMHome, didUpdateNameForActionSet actionSet: HMActionSet) {
        didModifyHomeKitObject(actionSet)
    }
    
    // MARK: Zones
    
    func home(home: HMHome, didAddZone zone: HMZone) {
        didAddHomeKitObject(zone)
    }
    
    func home(home: HMHome, didRemoveZone zone: HMZone) {
        didRemoveHomeKitObject(zone)
    }
    
    func home(home: HMHome, didUpdateNameForZone zone: HMZone) {
        didModifyHomeKitObject(zone)
    }
    
    // MARK: Rooms
    
    func home(home: HMHome, didAddRoom room: HMRoom) {
        didAddHomeKitObject(room)
    }
    
    func home(home: HMHome, didRemoveRoom room: HMRoom) {
        didRemoveHomeKitObject(room)
    }
    
    func home(home: HMHome, didUpdateNameForRoom room: HMRoom) {
        didModifyHomeKitObject(room)
    }

    // MARK: Accessories
    
    func accessoryDidUpdateReachability(accessory: HMAccessory) {
        didModifyHomeKitObject(accessory)
    }
    
    func accessoryDidUpdateName(accessory: HMAccessory) {
        didModifyHomeKitObject(accessory)
    }
}
