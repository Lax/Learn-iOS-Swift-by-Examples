/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `HMHome+Properties` methods provide convenience methods for deconstructing `HMHome` objects.
*/

import HomeKit

extension HMHome {
    /// All the services within all the accessories within the home.
    var allServices: [HMService] {
        return accessories.reduce([], combine: { (accumulator, accessory) -> [HMService] in
            return accumulator + accessory.services.filter { return !accumulator.contains($0) }
        })
    }
    
    /// All the characteristics within all of the services within the home.
    var allCharacteristics: [HMCharacteristic] {
        return allServices.reduce([], combine: { (accumulator, service) -> [HMCharacteristic] in
            return accumulator + service.characteristics.filter { return !accumulator.contains($0) }
        })
    }
    
    /**
        - returns:  A dictionary mapping localized service types to an array
                    of all services of that type.
    */
    var serviceTable: [String: [HMService]] {
        var serviceDictionary = [String: [HMService]]()
        for service in self.allServices {
            if !service.isControlType {
                continue
            }
            
            let serviceType = service.localizedDescription
            var existingServices: [HMService] = serviceDictionary[serviceType] ?? [HMService]()
            existingServices.append(service)
            serviceDictionary[service.localizedDescription] = existingServices
        }
        
        for (serviceType, services) in serviceDictionary {
            serviceDictionary[serviceType] = services.sort {
                return $0.accessory!.name.localizedCompare($1.accessory!.name) == .OrderedAscending
            }
        }
        return serviceDictionary
    }
    
    /// - returns:  All rooms in the home, including `roomForEntireHome`.
    var allRooms: [HMRoom] {
        let allRooms = [self.roomForEntireHome()] + self.rooms
        return allRooms.sortByLocalizedName()
    }
   
    /// - returns:  `true` if the current user is the admin of this home; `false` otherwise.
    var isAdmin: Bool {
        return self.homeAccessControlForUser(currentUser).administrator
    }
    
    /// - returns:  All accessories which are 'control accessories'.
    var sortedControlAccessories: [HMAccessory] {
        let filteredAccessories = self.accessories.filter { accessory -> Bool in
            for service in accessory.services {
                if service.isControlType {
                    return true
                }
            }
            return false
        }
        return filteredAccessories.sortByLocalizedName()
    }
    
    /**
        - parameter identifier: The UUID to look up.
        
        - returns:  The accessory within the receiver that matches the given UUID,
                    or nil if there is no accessory with that UUID.
    */
    func accessoryWithIdentifier(identifier: NSUUID) -> HMAccessory? {
        for accessory in self.accessories {
            if accessory.uniqueIdentifier == identifier {
                return accessory
            }
        }
        return nil
    }
    
    /**
        - parameter identifiers: An array of `NSUUID`s that match accessories in the receiver.
        
        - returns:  An array of `HMAccessory` instances corresponding to
                    the UUIDs passed in.
    */
    func accessoriesWithIdentifiers(identifiers: [NSUUID]) -> [HMAccessory] {
        return self.accessories.filter { accessory in
            identifiers.contains(accessory.uniqueIdentifier) 
        }
    }
    
    /**
        Searches through the home's accessories to find the accessory
        that is bridging the provided accessory.
        
        - parameter accessory: The bridged accessory.
        
        - returns:  The accessory bridging the bridged accessory.
    */
    func bridgeForAccessory(accessory: HMAccessory) -> HMAccessory? {
        if !accessory.bridged {
            return nil
        }
        for bridge in self.accessories {
            if let identifiers = bridge.uniqueIdentifiersForBridgedAccessories where identifiers.contains(accessory.uniqueIdentifier)  {
                return bridge
            }
        }
        return nil
    }
    
    /**
        - parameter room: The room.
        
        - returns:  The name of the room, appending "Default Room" if the room
                    is the home's `roomForEntireHome`
    */
    func nameForRoom(room: HMRoom) -> String {
        if room == self.roomForEntireHome() {
            let defaultRoom = NSLocalizedString("Default Room", comment: "Default Room")
            return room.name + " (\(defaultRoom))"
        }
        return room.name
    }
    
    /**
        - parameter zone:  The zone.
        - parameter rooms: A list of rooms to add to the final list.
        
        - returns:  A list of rooms that exist in the home and have not
                    yet been added to this zone.
    */
    func roomsNotAlreadyInZone(zone: HMZone, includingRooms rooms: [HMRoom]? = nil) -> [HMRoom] {
        var filteredRooms = self.rooms.filter { room in
            return !zone.rooms.contains(room) 
        }
        if let rooms = rooms {
            filteredRooms += rooms
        }
        return filteredRooms
    }
    
    /**
        - parameter home:         The home.
        - parameter serviceGroup: The service group.
        - parameter services:     A list of services to add to the final list.
        
        - returns:  A list of services that exist in the home and have not yet been added to this service group.
    */
    func servicesNotAlreadyInServiceGroup(serviceGroup: HMServiceGroup, includingServices services: [HMService]? = nil) -> [HMService] {
        var filteredServices = self.allServices.filter { service in
            /*
                Exclude services that are already in the service group
                and the accessory information service.
            */
            return !serviceGroup.services.contains(service) && service.serviceType != HMServiceTypeAccessoryInformation
        }
        if let services = services {
            filteredServices += services
        }
        return filteredServices
    }
}