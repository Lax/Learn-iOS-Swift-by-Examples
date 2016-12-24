/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `AddServicesViewController` allows users to add services to a service group.
*/

import UIKit
import HomeKit

/**
    A view controller that provides a list of services and lets the user select services to be added to the provided Service Group.

    The services are not added to the service group until the 'Done' button is pressed.
*/
class AddServicesViewController: HMCatalogViewController, HMAccessoryDelegate {
    // MARK: Types
    
    struct Identifiers {
        static let serviceCell = "ServiceCell"
    }
    
    // MARK: Properties
    
    lazy private var displayedAccessories = [HMAccessory]()
    lazy private var displayedServicesForAccessory = [HMAccessory: [HMService]]()
    lazy private var selectedServices = [HMService]()
    
    var serviceGroup: HMServiceGroup!
    
    // MARK: View Methods
    
    /// Reloads internal data and view.
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        selectedServices = []
        reloadTable()
    }
    
    /// Registers as the delegate for the home and all accessories.
    override func registerAsDelegate() {
        super.registerAsDelegate()
        for accessory in homeStore.home!.accessories {
            accessory.delegate = self
        }
    }
    
    // MARK: Table View Methods
    
    /// - returns:  The number of displayed accessories.
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return displayedAccessories.count
    }
    
    /// - returns:  The number of displayed services for the provided accessory.
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let accessory = displayedAccessories[section]
        return displayedServicesForAccessory[accessory]!.count
    }
    
    /// - returns:  A configured `ServiceCell`.
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.serviceCell, forIndexPath: indexPath) as! ServiceCell
        
        let service = serviceAtIndexPath(indexPath)
        
        cell.includeAccessoryText = false
        cell.service = service
        cell.accessoryType = selectedServices.contains(service)  ? .Checkmark : .None

        return cell
    }
    
    /**
        When an indexPath is selected, this function either adds or removes the selected service from the
        service group.
    */
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Get the service associated with this index.
        let service = serviceAtIndexPath(indexPath)
        
        // Call the appropriate add/remove operation with the closure from above.
        if let index = selectedServices.indexOf(service) {
            selectedServices.removeAtIndex(index)
        }
        else {
            selectedServices.append(service)
        }

        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    /// - returns: The name of the displayed accessory at the given section.
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return displayedAccessories[section].name
    }
    
    // MARK: Helper Methods
    
    /**
        Adds the selected services to the service group.
        
        Calls the provided completion handler once all services have been added.
    */
    func addSelectedServicesWithCompletionHandler(completion: () -> Void) {
        // Create a dispatch group for each of the service additions.
        let addServicesGroup = dispatch_group_create()
        for service in selectedServices {
            dispatch_group_enter(addServicesGroup)
            serviceGroup.addService(service) { error in
                if let error = error {
                    self.displayError(error)
                }
                dispatch_group_leave(addServicesGroup)
            }
        }
        dispatch_group_notify(addServicesGroup, dispatch_get_main_queue(), completion)
    }
    
    /**
        Finds the service at a specific index path.
        
        - parameter indexPath: An `NSIndexPath`
        
        - returns:  The `HMService` at the given index path.
    */
    private func serviceAtIndexPath(indexPath: NSIndexPath) -> HMService {
        let accessory = displayedAccessories[indexPath.section]
        let services = displayedServicesForAccessory[accessory]!
        return services[indexPath.row]
    }
    
    /**
        Commits the changes to the service group
        and dismisses the view.
    */
    @IBAction func dismiss() {
        addSelectedServicesWithCompletionHandler {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    /// Resets internal data and view.
    func reloadTable() {
        resetDisplayedServices()
        tableView.reloadData()
    }
    
    /**
        Updates internal array of accessories and the mapping
        of accessories to selected services.
    */
    func resetDisplayedServices() {
        displayedAccessories = []
        let allAccessories = home.accessories.sortByLocalizedName()
        displayedServicesForAccessory = [:]
        for accessory in allAccessories {
            var displayedServices = [HMService]()
            for service in accessory.services {
                if !serviceGroup.services.contains(service)  && service.serviceType != HMServiceTypeAccessoryInformation {
                    displayedServices.append(service)
                }
            }
            
            // Only add the accessory if it has displayed services.
            if !displayedServices.isEmpty {
                displayedServicesForAccessory[accessory] = displayedServices.sortByLocalizedName()
                displayedAccessories.append(accessory)
            }
        }
    }
    
    // MARK: HMHomeDelegate Methods
    
    /// Dismisses the view controller if our service group was removed.
    func home(home: HMHome, didRemoveServiceGroup group: HMServiceGroup) {
        if serviceGroup == group {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    /// Reloads the view if an accessory was added to HomeKit.
    func home(home: HMHome, didAddAccessory accessory: HMAccessory) {
        reloadTable()
        accessory.delegate = self
    }
    
    /// Dismisses the view controller if we no longer have accesories.
    func home(home: HMHome, didRemoveAccessory accessory: HMAccessory) {
        if home.accessories.isEmpty {
            navigationController?.dismissViewControllerAnimated(true, completion: nil)
        }
        
        reloadTable()
    }
    
    // MARK: HMAccessoryDelegate Methods
    
    // Accessory changes reload the data and view.

    func accessory(accessory: HMAccessory, didUpdateNameForService service: HMService) {
        reloadTable()
    }
    
    func accessoryDidUpdateServices(accessory: HMAccessory) {
        reloadTable()
    }
}