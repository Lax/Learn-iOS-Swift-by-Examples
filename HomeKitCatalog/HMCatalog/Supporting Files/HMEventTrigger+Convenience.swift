/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `HMEventTrigger+Convenience` methods are used for analyzing and deconstructing `HMEventTrigger` objects.
*/


import HomeKit
import MapKit

extension HMEventTrigger {
    
    /// - returns:  The first `CLCircularRegion` in the location event regions.
    var firstCircularLocationEventRegion: CLCircularRegion? {
        for event in self.locationEvents {
            if let circularRegion = event.region as? CLCircularRegion {
                return circularRegion
            }
        }
        return nil
    }
    
    /// - returns:  All events in the trigger which are `HMLocationEvent`s.
    var locationEvents: [HMLocationEvent] {
        return events.filter { $0 is HMLocationEvent } as! [HMLocationEvent]
    }
    
    /// - returns:  `true` if the trigger contains a location event, `false` otherwise.
    var isLocationEvent: Bool {
        for event in events {
            if event is HMLocationEvent {
                return true
            }
        }
        return false
    }
    
    /**
        - returns:  The first `HMEvent` in the event list that is
                    an `HMLocationEvent`, `nil` otherwise.
    */
    var locationEvent: HMLocationEvent? {
        for event in events {
            if let locationEvent = event as? HMLocationEvent {
                return locationEvent
            }
        }
        return nil
    }
    
    /**
        - returns:  All `HMEvent`s in the events list that are
                    `HMCharacteristicEvent`s.
    */
    var characteristicEvents: [HMCharacteristicEvent] {
        return events.filter { $0 is HMCharacteristicEvent } as! [HMCharacteristicEvent]
    }
}