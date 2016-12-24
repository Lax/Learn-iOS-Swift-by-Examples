/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ServiceGroupViewController` allows users to modify service groups.
*/

import UIKit
import HomeKit

/// A view controller that allows the user to add services to a service group.
class ServiceGroupViewController: HMCatalogViewController, HMAccessoryDelegate {
    // MARK: Types
    
    struct Identifiers {
        static let serviceCell = "ServiceCell"
        static let addServicesSegue = "Add Services Plus"
    }
    
    // MARK: Properties
    
    @IBOutlet weak var plusButton: UIBarButtonItem!
    
    var serviceGroup: HMServiceGroup!
    lazy private var accessories = [HMAccessory]()
    lazy private var servicesForAccessory = [HMAccessory: [HMService]]()
    
    // MARK: View Methods
    
    /// Reloads the view.
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        title = serviceGroup.name
        reloadData()
    }
    
    /// Pops the view controller if our data is invalid.
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if shouldPopViewController() {
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    // MARK: Table View Methods
    
    /**
        Generates the number of sections and adds a table view
        back ground message, if required.
        
        - returns:  The number of accessories in the service group.
    */
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let sections = accessories.count
        if sections == 0 {
            setBackgroundMessage(NSLocalizedString("No Services", comment: "No Services"))
        }
        else {
            setBackgroundMessage(nil)
        }

        return sections
    }
    
    /// - returns:  The number of services for the accessory at the specified section.
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let accessory = accessories[section]
        let services = servicesForAccessory[accessory]

        return services?.count ?? 0
    }
    
    /// - returns:  The name of the accessory at the specified section.
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return accessories[section].name
    }
    
    /// All cells in the table view represent services and can be deleted.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    /// - returns:  A `ServiceCell` with the service at the given index path.
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.serviceCell, forIndexPath: indexPath) as! ServiceCell
        let service = serviceAtIndexPath(indexPath)
        cell.includeAccessoryText = false
        cell.service = service
        return cell
    }
    
    /**
        - returns:  `true` if there are any services not already in the service group;
                    `false` otherwise.
    */
    private func shouldEnableAdd() -> Bool {
        let unAddedServices = home.servicesNotAlreadyInServiceGroup(serviceGroup)
        return unAddedServices.count != 0
    }
    
    /// Deleting a cell removes the corresponding service from the service group.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            removeServiceAtIndexPath(indexPath)
        }
    }
    
    /**
        Removes the service associated with the cell at a given index path.
        
        - parameters indexPath: The `NSIndexPath` to remove.
    */
    private func removeServiceAtIndexPath(indexPath: NSIndexPath) {
        let service = serviceAtIndexPath(indexPath)
        serviceGroup.removeService(service) { error in
            if let error = error {
                self.displayError(error)
            }

            self.reloadData()
        }
    }
    
    /**
        Finds the service at a given index path.
        
        - parameter indexPath: An `NSIndexPath`.
        
        - returns: The service at the given index path
    */
    private func serviceAtIndexPath(indexPath: NSIndexPath) -> HMService {
        let accessory = accessories[indexPath.section]
        let services = servicesForAccessory[accessory]!
        return services[indexPath.row]
    }
    
    /// Passes the service group into the `AddServicesViewController`
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        if segue.identifier == Identifiers.addServicesSegue {
            let addServicesVC = segue.intendedDestinationViewController as! AddServicesViewController
            addServicesVC.serviceGroup = serviceGroup
        }
    }
    
    // MARK: Helper Methods
    
    /**
        Resets accessory and service lists, resets the plus
        button's enabled status and reloads the table view.
    */
    private func reloadData() {
        resetLists()
        plusButton.enabled = shouldEnableAdd()
        tableView.reloadData()
    }
    
    /**
        Resets the accessories array and the service-accessory mapping
        using the original HomeKit objects.
    */
    private func resetLists() {
        accessories = []
        servicesForAccessory = [:]

        for service in serviceGroup.services {
            if let accessory = service.accessory {
                if servicesForAccessory[accessory] == nil {
                    accessories.append(accessory)
                    servicesForAccessory[accessory] = [service]
                }
                else {
                    servicesForAccessory[accessory]?.append(service)
                }
            }
        }
        
        // Sort all service lists.
        for accessory in accessories {
            servicesForAccessory[accessory] = servicesForAccessory[accessory]?.sortByLocalizedName()
        }
        
        // Sort accessory list.
        accessories = accessories.sortByLocalizedName()
    }
    
    /**
        - returns: `true` if our service group is not
                   in the home any more; `false` otherwise.
    */
    private func shouldPopViewController() -> Bool {
        guard let home = homeStore.home else { return true }

        return !home.serviceGroups.contains { group in
            return group == serviceGroup
        }
    }
    
    /**
        Registers as the delegate for the home and
        all accessories which are related to our service group.
    */
    override func registerAsDelegate() {
        super.registerAsDelegate()

        for service in serviceGroup.services {
            service.accessory?.delegate = self
        }
    }
    
    // MARK: HMHomeDelegate Methods
    
    /// Pops the view controller if our service group has been deleted.
    func home(home: HMHome, didRemoveServiceGroup group: HMServiceGroup) {
        if group == serviceGroup {
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    // Home and accessory changes result in a full data reload.
    
    func home(home: HMHome, didAddService service: HMService, toServiceGroup group: HMServiceGroup) {
        if serviceGroup == group {
            reloadData()
        }
    }
    
    func home(home: HMHome, didRemoveService service: HMService, fromServiceGroup group: HMServiceGroup) {
        if serviceGroup == group {
            reloadData()
        }
    }
    
    func home(home: HMHome, didRemoveAccessory accessory: HMAccessory) {
        reloadData()
    }
    
    func accessoryDidUpdateServices(accessory: HMAccessory) {
        reloadData()
    }
    
    func accessory(accessory: HMAccessory, didUpdateNameForService service: HMService) {
        reloadData()
    }
}