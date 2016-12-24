/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `AccessoryUpdateController` manages `CharacteristicCell` updates and buffers them up before sending them to HomeKit.
*/

import HomeKit

/// An object that responds to `CharacteristicCell` updates and notifies HomeKit of changes.
class AccessoryUpdateController: NSObject, CharacteristicCellDelegate {
    // MARK: Properties
    
    let updateQueue = dispatch_queue_create("com.sample.HMCatalog.CharacteristicUpdateQueue", DISPATCH_QUEUE_SERIAL)
    
    lazy var pendingWrites = [HMCharacteristic:AnyObject]()
    lazy var sentWrites = [HMCharacteristic:AnyObject]()
    
    // Implicitly unwrapped optional because we need `self` to initialize.
    var updateValueTimer: NSTimer!
    
    /// Starts the update timer on creation.
    override init() {
        super.init()
        startListeningForCellUpdates()
    }
    
    /// Responds to a cell change, and if the update was marked immediate, updates the characteristics.
    func characteristicCell(cell: CharacteristicCell, didUpdateValue value: AnyObject, forCharacteristic characteristic: HMCharacteristic, immediate: Bool) {
        pendingWrites[characteristic] = value
        if immediate {
            updateCharacteristics()
        }
    }
    
    /**
        Reads the characteristic's value and calls the completion with the characteristic's value.
    
        If there is a pending write request on the same characteristic, the read is ignored to prevent
        "UI glitching".
    */
    func characteristicCell(cell: CharacteristicCell, readInitialValueForCharacteristic characteristic: HMCharacteristic, completion: (AnyObject?, NSError?) -> Void) {
        characteristic.readValueWithCompletionHandler { error in
            dispatch_sync(self.updateQueue) {
                if let sentValue = self.sentWrites[characteristic] {
                    completion(sentValue, nil)
                    return
                }

                dispatch_async(dispatch_get_main_queue()) {
                    completion(characteristic.value, error)
                }
            }
        }
    }

    /// Creates and starts the update value timer.
    func startListeningForCellUpdates() {
        updateValueTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(AccessoryUpdateController.updateCharacteristics), userInfo: nil, repeats: true)
    }
    
    /// Invalidates the update timer.
    func stopListeningForCellUpdates() {
        updateValueTimer.invalidate()
    }
    
    /// Sends all pending requests in the array.
    func updateCharacteristics() {
        dispatch_sync(updateQueue) {
            for (characteristic, value) in self.pendingWrites {
                self.sentWrites[characteristic] = value

                characteristic.writeValue(value) { error in
                    if let error = error {
                        print("HomeKit: Could not change value: \(error.localizedDescription).")
                    }

                    self.didCompleteWrite(characteristic, value: value)
                }
            }

            self.pendingWrites.removeAll()
        }
    }
    
    /**
        Synchronously adds the characteristic-value pair into the `sentWrites` map.
        
        - parameter characteristic: The `HMCharacteristic` to add.
        - parameter value: The value of the `characteristic`.
    */
    func didSendWrite(characteristic: HMCharacteristic, value: AnyObject) {
        dispatch_sync(updateQueue) {
            self.sentWrites[characteristic] = value
        }
    }
    
    /**
        Synchronously removes the characteristic-value pair from the `sentWrites` map.
        
        - parameter characteristic: The `HMCharacteristic` to remove.
        - parameter value: The value of the `characteristic` (unused, but included for clarity).
    */
    func didCompleteWrite(characteristic: HMCharacteristic, value: AnyObject) {
        dispatch_sync(updateQueue) {
            self.sentWrites.removeValueForKey(characteristic)
        }
    }
}
