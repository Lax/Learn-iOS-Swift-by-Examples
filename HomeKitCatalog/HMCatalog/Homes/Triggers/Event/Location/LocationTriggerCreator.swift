/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `LocationTriggerCreator` creates Location triggers.
*/

import HomeKit
import MapKit

/**
    An `EventTriggerCreator` subclass which allows for the creation
    of location triggers.
*/
class LocationTriggerCreator: EventTriggerCreator, MapViewControllerDelegate {
    // MARK: Properties
    
    var eventTrigger: HMEventTrigger? {
        return trigger as? HMEventTrigger
    }
    var locationEvent: HMLocationEvent?
    var targetRegion: CLCircularRegion?
    var targetRegionStateIndex = 0
    
    // MARK: Trigger Creator Methods
    
    /// Initializes location event, target region, and region state.
    required init(trigger: HMTrigger?, home: HMHome) {
        super.init(trigger: trigger, home: home)
        if let eventTrigger = eventTrigger {
            self.locationEvent = eventTrigger.locationEvent
            if let region = locationEvent?.region as? CLCircularRegion {
                self.targetRegion = region
            }
            self.targetRegionStateIndex = (self.targetRegion?.notifyOnEntry ?? true) ? 0 : 1
            
        }
    }
    
    /// Generates a new region and updates the location event.
    override func updateTrigger() {
        if let region = targetRegion {
            prepareRegion()
            if let locationEvent = locationEvent {
                dispatch_group_enter(saveTriggerGroup)
                locationEvent.updateRegion(region) { error in
                    if let error = error {
                        self.errors.append(error)
                    }
                    dispatch_group_leave(self.saveTriggerGroup)
                }
            }
        }
        
        self.savePredicate()
    }
    
    /**
        - returns:  A new `HMEventTrigger` with a new generated
                    location event and predicate.
    */
    override func newTrigger() -> HMTrigger? {
        var events = [HMLocationEvent]()
        if let region = targetRegion {
            prepareRegion()
            events.append(HMLocationEvent(region: region))
        }
        return HMEventTrigger(name: name, events: events, predicate: newPredicate())
    }
    
    // MARK: Helper Methods
    
    /**
        Sets the `notifyOnEntry` and `notifyOnExit` region
        properties based on the selected state.
    */
    private func prepareRegion() {
        if let region = targetRegion {
            region.notifyOnEntry = (targetRegionStateIndex == 0)
            region.notifyOnExit = !region.notifyOnEntry
        }
    }
    
    /**
        Updates the target region from the one provided
        by the delegate.
        
        - parameter region: A new `CLCircularRegion`, provided by the delegate.
    */
    func mapViewDidUpdateRegion(region: CLCircularRegion) {
        targetRegion = region
    }
}