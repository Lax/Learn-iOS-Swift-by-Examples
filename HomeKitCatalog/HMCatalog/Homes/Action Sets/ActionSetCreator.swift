/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ActionSetCreator` builds `HMActionSet`s.
*/

import HomeKit

/// A `CharacteristicCellDelegate` that builds an `HMActionSet` when it receives delegate callbacks.
class ActionSetCreator: CharacteristicCellDelegate {
    // MARK: Properties
    
    var actionSet: HMActionSet?
    var home: HMHome
    
    var saveError: NSError?
    
    /// The structure we're going to use to hold the target values.
    let targetValueMap = NSMapTable.strongToStrongObjectsMapTable()
    
    /// A dispatch group to wait for all of the individual components of the saving process.
    let saveActionSetGroup = dispatch_group_create()
    
    required init(actionSet: HMActionSet?, home: HMHome) {
        self.actionSet = actionSet
        self.home = home
    }
    
    /**
        If there is an action set, saves the action set and then updates its name.
        Otherwise creates a new action set and adds all actions to it.
        
        - parameter name:              The new name for the action set.
        - parameter completionHandler: A closure to call once the action set has been completely saved.
    */
    func saveActionSetWithName(name: NSString, completionHandler: (error: NSError?) -> Void) {
        if let actionSet = actionSet {
            saveActionSet(actionSet)
            updateNameIfNecessary(name)
        }
        else {
            createActionSetWithName(name)
        }
        dispatch_group_notify(saveActionSetGroup, dispatch_get_main_queue()) {
            completionHandler(error: self.saveError)
            self.saveError = nil
        }
    }
    
    /**
        Adds all of the actions that have been requested to the Action Set, then runs a completion block.
        
        - parameter completion: A closure to be called when all of the actions have been added.
    */
    func saveActionSet(actionSet: HMActionSet) {
        let actions = actionsFromMapTable(targetValueMap)
        for action in actions {
            dispatch_group_enter(saveActionSetGroup)
            addAction(action, toActionSet: actionSet) { error in
                if let error = error {
                    print("HomeKit: Error adding action: \(error.localizedDescription)")
                    self.saveError = error
                }
                dispatch_group_leave(self.saveActionSetGroup)
            }
        }
    }
    
    /**
        Sets the name of an existing action set.
        
        - parameter name: The new name for the action set.
    */
    func updateNameIfNecessary(name: NSString) {
        if actionSet?.name == name {
            return
        }
        dispatch_group_enter(saveActionSetGroup)
        actionSet?.updateName(name as String) { error in
            if let error = error {
                print("HomeKit: Error updating name: \(error.localizedDescription)")
                self.saveError = error
            }
            dispatch_group_leave(self.saveActionSetGroup)
        }
    }
    
    /**
        Creates and saves an action set with the provided name.
        
        - parameter name: The name for the new action set.
    */
    func createActionSetWithName(name: NSString) {
        dispatch_group_enter(saveActionSetGroup)
        home.addActionSetWithName(name as String) { actionSet, error in
            if let error = error {
                print("HomeKit: Error creating action set: \(error.localizedDescription)")
                self.saveError = error
            }
            else {
                // There is no error, so the action set has a value.
                self.saveActionSet(actionSet!)
            }
            dispatch_group_leave(self.saveActionSetGroup)
        }
    }
    
    /**
        Checks to see if an action already exists to modify the same characteristic 
        as the action passed in. If such an action exists, the method tells the 
        existing action to update its target value. Otherwise, the new action is
        simply added to the action set.
        
        - parameter action:     The action to add or update.
        - parameter actionSet:  The action set to which to add the action.
        - parameter completion: A closure to call when the addition has finished.
    */
    func addAction(action: HMCharacteristicWriteAction, toActionSet actionSet: HMActionSet, completion: (NSError?) -> Void) {
        if let existingAction = existingActionInActionSetMatchingAction(action) {
            existingAction.updateTargetValue(action.targetValue, completionHandler: completion)
        }
        else {
            actionSet.addAction(action, completionHandler: completion)
        }
    }
    
    /**
        Checks to see if there is already an HMCharacteristicWriteAction in
        the action set that matches the provided action.
        
        - parameter action: The action in question.
        
        - returns: The existing action that matches the characteristic or nil if
                   there is no existing action.
    */
    func existingActionInActionSetMatchingAction(action: HMCharacteristicWriteAction) -> HMCharacteristicWriteAction? {
        if let actionSet = actionSet {
            for existingAction in Array(actionSet.actions) as! [HMCharacteristicWriteAction] {
                if action.characteristic == existingAction.characteristic {
                    return existingAction
                }
            }
        }
        return nil
    }
    
    /**
        Iterates over a map table of HMCharacteristic -> id objects and creates
        an array of HMCharacteristicWriteActions based on those targets.
        
        - parameter table: An NSMapTable mapping HMCharacteristics to id's.
        
        - returns:  An array of HMCharacteristicWriteActions.
    */
    func actionsFromMapTable(table: NSMapTable) -> [HMCharacteristicWriteAction] {
        return targetValueMap.keyEnumerator().allObjects.map { characteristic in
            let targetValue =  targetValueMap.objectForKey(characteristic) as! NSCopying
            return HMCharacteristicWriteAction(characteristic: characteristic as! HMCharacteristic, targetValue: targetValue)
        }
    }
    
    /**
        - returns:  `true` if the characteristic count is greater than zero;
                    `false` otherwise.
    */
    var containsActions: Bool {
        return !allCharacteristics.isEmpty
    }
    
    /**
        All existing characteristics within `HMCharacteristiWriteActions`
        and target values in the target value map.
    */
    var allCharacteristics: [HMCharacteristic] {
        var characteristics = Set<HMCharacteristic>()

        if let actionSet = actionSet, actions = Array(actionSet.actions) as? [HMCharacteristicWriteAction] {
            let actionSetCharacteristics = actions.map { action -> HMCharacteristic in
                return action.characteristic
            }
            characteristics.unionInPlace(actionSetCharacteristics)
        }
        
        characteristics.unionInPlace(targetValueMap.keyEnumerator().allObjects as! [HMCharacteristic])

        return Array(characteristics)
    }
    
    /**
        Searches through the target value map and existing `HMCharacteristicWriteActions`
        to find the target value for the characteristic in question.
        
        - parameter characteristic: The characteristic in question.
        
        - returns:  The target value for this characteristic, or nil if there is no target.
    */
    func targetValueForCharacteristic(characteristic: HMCharacteristic) -> AnyObject? {
        if let value = targetValueMap.objectForKey(characteristic) {
            return value
        }
        else if let actions = actionSet?.actions {
            for action in actions {
                if let writeAction = action as? HMCharacteristicWriteAction
                    where writeAction.characteristic == characteristic {
                        return writeAction.targetValue
                }
            }
        }

        return nil
    }
    
    /**
        First removes the characteristic from the `targetValueMap`.
        Then removes any `HMCharacteristicWriteAction`s from the action set
        which set the specified characteristic.
        
        - parameter characteristic: The `HMCharacteristic` to remove.
        - parameter completion: The closure to invoke when the characteristic has been removed.
    */
    func removeTargetValueForCharacteristic(characteristic: HMCharacteristic, completion: () -> Void) {
        /*
            We need to create a dispatch group here, because in many cases
            there will be one characteristic saved in the Action Set, and one
            in the target value map. We want to run the completion closure only one time,
            to ensure we've removed both.
        */
        let group = dispatch_group_create()
        if targetValueMap.objectForKey(characteristic) != nil {
            // Remove the characteristic from the target value map.
            dispatch_group_async(group, dispatch_get_main_queue()) {
                self.targetValueMap.removeObjectForKey(characteristic)
            }
        }
        if let actions = actionSet?.actions as? Set<HMCharacteristicWriteAction> {
            for action in Array(actions) {
                if action.characteristic == characteristic {
                    /*
                        Also remove the action, and only relinquish the dispatch group
                        once the action set has finished.
                    */
                    dispatch_group_enter(group)
                    actionSet?.removeAction(action) { error in
                        if let error = error {
                            print(error.localizedDescription)
                        }
                        dispatch_group_leave(group)
                    }
                }
            }
        }
        // Once we're positive both have finished, run the completion closure on the main queue.
        dispatch_group_notify(group, dispatch_get_main_queue(), completion)
    }
    
    // MARK: Characteristic Cell Delegate
    
    /**
        Receives a callback from a `CharacteristicCell` with a value change.
        Adds this value change into the targetValueMap, overwriting other value changes.
    */
    func characteristicCell(cell: CharacteristicCell, didUpdateValue newValue: AnyObject, forCharacteristic characteristic: HMCharacteristic, immediate: Bool) {
        targetValueMap.setObject(newValue, forKey: characteristic)
    }
    
    /**
        Receives a callback from a `CharacteristicCell`, requesting an initial value for
        a given characteristic.
        
        It checks to see if we have an action in this Action Set that matches the characteristic.
        If so, calls the completion closure with the target value.
    */
    func characteristicCell(cell: CharacteristicCell, readInitialValueForCharacteristic characteristic: HMCharacteristic, completion: (AnyObject?, NSError?) -> Void) {
        if let value = targetValueForCharacteristic(characteristic) {
            completion(value, nil)
            return
        }
        
        characteristic.readValueWithCompletionHandler { error in
            /*
                The user may have updated the cell value while the
                read was happening. We check the map one more time.
            */
            if let value = self.targetValueForCharacteristic(characteristic) {
                completion(value, nil)
            }
            else {
                completion(characteristic.value, error)
            }
        }
    }
}
