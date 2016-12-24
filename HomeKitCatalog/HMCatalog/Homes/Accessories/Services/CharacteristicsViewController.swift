/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `CharacteristicsViewController` displays characteristics within a service.
*/

import UIKit
import HomeKit

/// A view controller that displays a list of characteristics within an `HMService`.
class CharacteristicsViewController: HMCatalogViewController, HMAccessoryDelegate {
    // MARK: Properties
    
    var service: HMService!
    var cellDelegate: CharacteristicCellDelegate!
    private var tableViewDataSource: CharacteristicsTableViewDataSource!
    var showsFavorites = false
    var allowsAllWrites = false
    
    // MARK: View Methods
    
    /// Initializes the data source.
    override func viewDidLoad() {
        super.viewDidLoad()
     
        tableViewDataSource = CharacteristicsTableViewDataSource(service: service, tableView: tableView, delegate: cellDelegate, showsFavorites: showsFavorites, allowsAllWrites: allowsAllWrites)
    }
    
    /// Reloads the view and enabled notifications for all relevant characteristics.
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        title = service.name
        setNotificationsEnabled(true)
        reloadTableView()
    }
    
    /// Disables notifications for characteristics.
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        setNotificationsEnabled(false)
    }
    
    /**
        Registers as the delegate for the current home and
        the service's accessory.
    */
    override func registerAsDelegate() {
        super.registerAsDelegate()
        service.accessory?.delegate = self
    }
    
    /**
        Enables or disables notifications on all characteristics within this service.
        
        - parameter notificationsEnabled: A `Bool`; whether to enable or disable.
    */
    func setNotificationsEnabled(notificationsEnabled: Bool) {
        for characteristic in service.characteristics {
            if characteristic.supportsEventNotification {
                characteristic.enableNotification(notificationsEnabled) { error in
                    if let error = error {
                        print("HomeKit: Error enabling notification on charcteristic '\(characteristic)': \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// Reloads the table view and stops the refresh control.
    func reloadTableView() {
        setNotificationsEnabled(true)
        tableViewDataSource.service = service
        refreshControl?.endRefreshing()
        tableView.reloadData()
    }
    
    // MARK: Table View Methods
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch CharacteristicTableViewSection(rawValue: indexPath.section) {
            case .Characteristics?:
                let characteristic = service.characteristics[indexPath.row]
                didSelectCharacteristic(characteristic, atIndexPath: indexPath)
                
            case .AssociatedServiceType?:
                didSelectAssociatedServiceTypeAtIndexPath(indexPath)
                
            case nil:
                fatalError("Unexpected `CharacteristicTableViewSection` raw value.")
        }
    }
    
    /**
        If a characteristic is selected, and it is the 'Identify' characteristic,
        perform an identify on that accessory.
    */
    private func didSelectCharacteristic(characteristic: HMCharacteristic, atIndexPath indexPath: NSIndexPath) {
        if characteristic.isIdentify {
            service.accessory?.identifyWithCompletionHandler { error in
                if let error = error {
                    self.displayError(error)
                    return
                }
            }
        }
    }
    
    /**
        Handles selection of one of the associated service types in the list.
        
        - parameter indexPath: The selected index path.
    */
    private func didSelectAssociatedServiceTypeAtIndexPath(indexPath: NSIndexPath) {
        let serviceTypes = HMService.validAssociatedServiceTypes
        var newServiceType: String?
        if indexPath.row < serviceTypes.count {
            newServiceType = serviceTypes[indexPath.row]
        }
        service.updateAssociatedServiceType(newServiceType) { error in
            if let error = error {
                self.displayError(error)
                return
            }

            self.didUpdateAssociatedServiceType()
        }
    }
    
    /// Reloads the associated service section in the table view.
    private func didUpdateAssociatedServiceType() {
        let associatedServiceTypeIndexSet = NSIndexSet(index: CharacteristicTableViewSection.AssociatedServiceType.rawValue)

        tableView.reloadSections(associatedServiceTypeIndexSet, withRowAnimation: .Automatic)
    }
    
    // MARK: HMHomeDelegate Methods
    
    /// If our accessory was removed, pop to root view controller.
    func home(home: HMHome, didRemoveAccessory accessory: HMAccessory) {
        if accessory == service.accessory {
            navigationController?.popToRootViewControllerAnimated(true)
        }
    }
    
    // MARK: HMAccessoryDelegate Methods
    
    /// If our accessory becomes unreachable, pop to root view controller.
    func accessoryDidUpdateReachability(accessory: HMAccessory) {
        if accessory == service.accessory && !accessory.reachable {
            navigationController?.popToRootViewControllerAnimated(true)
        }
    }
    
    /**
        Search for the cell corresponding to that characteristic and
        update its value.
    */
    func accessory(accessory: HMAccessory, service: HMService, didUpdateValueForCharacteristic characteristic: HMCharacteristic) {
        if let index = service.characteristics.indexOf(characteristic) {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! CharacteristicCell
            cell.setValue(characteristic.value, notify: false)
        }
    }
}
