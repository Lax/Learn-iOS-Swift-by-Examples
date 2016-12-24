/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `HomeKitObjectCollection` is a model object for the `HomeViewController`.
                It manages arrays of HomeKit objects.
*/

import HomeKit

/// Represents the all different types of HomeKit objects.
enum HomeKitObjectSection: Int {
    case Accessory, Room, Zone, User, ActionSet, Trigger, ServiceGroup
    
    static let count = 7
}

/**
    Manages internal lists of HomeKit objects to allow for
    save insertion into a table view.
*/
class HomeKitObjectCollection {
    // MARK: Properties
    
    var accessories = [HMAccessory]()
    var rooms = [HMRoom]()
    var zones = [HMZone]()
    var actionSets = [HMActionSet]()
    var triggers = [HMTrigger]()
    var serviceGroups = [HMServiceGroup]()
    
    /**
        Adds an object to the collection by finding its corresponding 
        array and appending the object to it.
    
        - parameter object: The HomeKit object to append.
    */
    func append(object: AnyObject) {
        switch object {
            case let actionSet as HMActionSet:
                actionSets.append(actionSet)
                actionSets = actionSets.sortByTypeAndLocalizedName()
                
            case let accessory as HMAccessory:
                accessories.append(accessory)
                accessories = accessories.sortByLocalizedName()
                
            case let room as HMRoom:
                rooms.append(room)
                rooms = rooms.sortByLocalizedName()
                
            case let zone as HMZone:
                zones.append(zone)
                zones = zones.sortByLocalizedName()
                
            case let trigger as HMTrigger:
                triggers.append(trigger)
                triggers = triggers.sortByLocalizedName()
                
            case let serviceGroup as HMServiceGroup:
                serviceGroups.append(serviceGroup)
                serviceGroups = serviceGroups.sortByLocalizedName()
                
            default:
                break
        }
    }
    
    /**
        Creates an `NSIndexPath` representing the location of the
        HomeKit object in the table view.
    
        - parameter object: The HomeKit object to find.
    
        - returns:  The `NSIndexPath` representing the location of
                    the HomeKit object in the table view.
    */
    func indexPathOfObject(object: AnyObject) -> NSIndexPath? {
        switch object {
            case let actionSet as HMActionSet:
                if let index = actionSets.indexOf(actionSet) {
                    return NSIndexPath(forRow: index, inSection: HomeKitObjectSection.ActionSet.rawValue)
                }
                
            case let accessory as HMAccessory:
                if let index = accessories.indexOf(accessory) {
                    return NSIndexPath(forRow: index, inSection: HomeKitObjectSection.Accessory.rawValue)
                }
                
            case let room as HMRoom:
                if let index = rooms.indexOf(room) {
                    return NSIndexPath(forRow: index, inSection: HomeKitObjectSection.Room.rawValue)
                }
                
            case let zone as HMZone:
                if let index = zones.indexOf(zone) {
                    return NSIndexPath(forRow: index, inSection: HomeKitObjectSection.Zone.rawValue)
                }
                
            case let trigger as HMTrigger:
                if let index = triggers.indexOf(trigger) {
                    return NSIndexPath(forRow: index, inSection: HomeKitObjectSection.Trigger.rawValue)
                }
                
            case let serviceGroup as HMServiceGroup:
                if let index = serviceGroups.indexOf(serviceGroup) {
                    return NSIndexPath(forRow: index, inSection: HomeKitObjectSection.ServiceGroup.rawValue)
                }
                
            default: break
        }

        return nil
    }
    
    /**
        Removes a HomeKit object from the collection.
    
        - parameter object: The HomeKit object to remove.
    */
    func remove(object: AnyObject) {
        switch object {
            case let actionSet as HMActionSet:
                if let index = actionSets.indexOf(actionSet) {
                    actionSets.removeAtIndex(index)
                }
                
            case let accessory as HMAccessory:
                if let index = accessories.indexOf(accessory) {
                    accessories.removeAtIndex(index)
                }
                
            case let room as HMRoom:
                if let index = rooms.indexOf(room) {
                    rooms.removeAtIndex(index)
                }
                
            case let zone as HMZone:
                if let index = zones.indexOf(zone) {
                    zones.removeAtIndex(index)
                }
                
            case let trigger as HMTrigger:
                if let index = triggers.indexOf(trigger) {
                    triggers.removeAtIndex(index)
                }
                
            case let serviceGroup as HMServiceGroup:
                if let index = serviceGroups.indexOf(serviceGroup) {
                    serviceGroups.removeAtIndex(index)
                }
                
            default:
                break
        }
    }
    
    /**
        Provides the array of `NSObject`s corresponding to the provided section.
    
        - parameter section: A `HomeKitObjectSection`.
    
        - returns:  An array of `NSObject`s corresponding to the provided section.
    */
    func objectsForSection(section: HomeKitObjectSection) -> [NSObject] {
        switch section {
            case .ActionSet:
                return actionSets
                
            case .Accessory:
                return accessories
                
            case .Room:
                return rooms
                
            case .Zone:
                return zones
                
            case .Trigger:
                return triggers
                
            case .ServiceGroup:
                return serviceGroups
                
            default:
                return []
        }
    }
    
    /**
        Provides an `HomeKitObjectSection` for a given object.
    
        - parameter object: A HomeKit object.
    
        - returns:  The corrosponding `HomeKitObjectSection`
    */
    class func sectionForObject(object: AnyObject?) -> HomeKitObjectSection? {
        switch object {
            case is HMActionSet:
                return .ActionSet
                
            case is HMAccessory:
                return .Accessory
                
            case is HMZone:
                return .Zone
                
            case is HMRoom:
                return .Room
                
            case is HMTrigger:
                return .Trigger
                
            case is HMServiceGroup:
                return .ServiceGroup
                
            default:
                return nil
        }
    }
    
    /**
        Reloads all internal structures based on the provided home.
        
        - parameter home: The `HMHome` with which to reset the collection.
    */
    func resetWithHome(home: HMHome) {
        accessories = home.accessories.sortByLocalizedName()
        rooms = home.allRooms
        zones = home.zones.sortByLocalizedName()
        actionSets = home.actionSets.sortByTypeAndLocalizedName()
        triggers = home.triggers.sortByLocalizedName()
        serviceGroups = home.serviceGroups.sortByLocalizedName()
    }
}
