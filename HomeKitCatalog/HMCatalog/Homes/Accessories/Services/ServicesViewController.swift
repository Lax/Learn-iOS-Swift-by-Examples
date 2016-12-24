/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ServicesViewController` displays an accessory's services.
*/

import UIKit
import HomeKit

/// Represents the sections in the `ServicesViewController`.
enum AccessoryTableViewSection: Int {
    case Services, BridgedAccessories
}

/**
    A view controller which displays all the services of a provided accessory, and 
    passes its cell delegate onto a `CharacteristicsViewController`.
*/
class ServicesViewController: HMCatalogViewController, HMAccessoryDelegate {
    // MARK: Types
    
    struct Identifiers {
        static let accessoryCell = "AccessoryCell"
        static let serviceCell = "ServiceCell"
        static let showServiceSegue = "Show Service"
    }
    
    // MARK: Properties
    
    var accessory: HMAccessory!
    lazy var cellDelegate: CharacteristicCellDelegate = AccessoryUpdateController()
    var showsFavorites = false
    var allowsAllWrites = false
    var onlyShowsControlServices = false
    var displayedServices = [HMService]()
    var bridgedAccessories = [HMAccessory]()
    
    // MARK: View Methods
    
    /// Configures table view.
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    /// Reloads the view.
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateTitle()
        reloadData()
    }
    
    /// Pops the view controller, if required.
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if shouldPopViewController() {
            navigationController?.popToRootViewControllerAnimated(true)
        }
    }
    
    /**
        Passes the `CharacteristicsViewController` the service from the cell and
        configures the view controller.
    */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        guard segue.identifier == Identifiers.showServiceSegue else { return }
        
        if let indexPath = tableView.indexPathForCell(sender as! UITableViewCell) {
            let selectedService = displayedServices[indexPath.row]
            let characteristicsViewController = segue.intendedDestinationViewController as! CharacteristicsViewController
            characteristicsViewController.showsFavorites = showsFavorites
            characteristicsViewController.allowsAllWrites = allowsAllWrites
            characteristicsViewController.service = selectedService
            characteristicsViewController.cellDelegate = cellDelegate
        }
    }
    
    /**
        - returns:  `true` if our accessory is no longer in the
                    current home's list of accessories.
    */
    private func shouldPopViewController() -> Bool {
        for accessory in homeStore.home!.accessories {
            if accessory == accessory {
                return false
            }
        }
        return true
    }
    
    // MARK: Delegate Registration
    
    /**
        Registers as the delegate for the current home
        and for the current accessory.
    */
    override func registerAsDelegate() {
        super.registerAsDelegate()
        accessory.delegate = self
    }
    
    // MARK: Table View Methods
    
    /// Two sections if we're showing bridged accessories.
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if accessory.uniqueIdentifiersForBridgedAccessories != nil {
            return 2
        }
        return 1
    }
    
    /**
        Section 1 contains the services within the accessory.
        Section 2 contains the bridged accessories.
    */
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch AccessoryTableViewSection(rawValue: section) {
            case .Services?:
                return displayedServices.count
                
            case .BridgedAccessories?:
                return bridgedAccessories.count
                
            case nil:
                fatalError("Unexpected `AccessoryTableViewSection` raw value.")
        }
    }
    
    /**
        - returns:  A Service or Bridged Accessory Cell based
                    on the section.
    */
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch AccessoryTableViewSection(rawValue: indexPath.section) {
            case .Services?:
                return self.tableView(tableView, serviceCellForRowAtIndexPath: indexPath)
                
            case .BridgedAccessories?:
                return self.tableView(tableView, bridgedAccessoryCellForRowAtIndexPath: indexPath)
                
            case nil:
                fatalError("Unexpected `AccessoryTableViewSection` raw value.")
        }
    }
    
    /**
        - returns:  A cell containing the name of a bridged
                    accessory at a given index path.
    */
    func tableView(tableView: UITableView, bridgedAccessoryCellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.accessoryCell, forIndexPath: indexPath)
        let accessory = bridgedAccessories[indexPath.row]
        cell.textLabel?.text = accessory.name
        return cell
    }
    
    /**
        - returns:  A cell containing the name of a service at
                    a given index path, as well as a localized
                    description of its service type.
    */
    func tableView(tableView: UITableView, serviceCellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.serviceCell, forIndexPath: indexPath)
        let service = displayedServices[indexPath.row]
        
        // Inherit the name from the accessory if the Service doesn't have one.
        cell.textLabel?.text = service.name ?? service.accessory?.name
        cell.detailTextLabel?.text = service.localizedDescription
        return cell
    }
    
    /// - returns:  A title string for the section.
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch AccessoryTableViewSection(rawValue: section) {
            case .Services?:
                return NSLocalizedString("Services", comment: "Services")
                
            case .BridgedAccessories?:
                return NSLocalizedString("Bridged Accessories", comment: "Bridged Accessories")
                
            case nil:
                fatalError("Unexpected `AccessoryTableViewSection` raw value.")
        }
    }
    
    /// - returns:  A localized description of the accessories bridged status.
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if accessory.bridged && AccessoryTableViewSection(rawValue: section)! == .Services {
            let formatString = NSLocalizedString("This accessory is being bridged into HomeKit by %@.", comment: "Bridge Description")
            if let bridge = home.bridgeForAccessory(accessory) {
                return String(format: formatString, bridge.name)
            }
            else {
                return NSLocalizedString("This accessory is being bridged into HomeKit.", comment: "Bridge Description Without Bridge")
            }
        }
        return nil
    }
    
    // MARK: Helper Methods
    
    /// Updates the navigation bar's title.
    func updateTitle() {
        navigationItem.title = accessory.name
    }
    
    /**
        Updates the title, resets the displayed services based on
        view controller configurations, reloads the bridge accessory
        array and reloads the table view.
    */
    private func reloadData() {
        displayedServices = accessory.services.sortByLocalizedName()
        if onlyShowsControlServices {
            // We are configured to only show control services, filter the array.
            displayedServices = displayedServices.filter { service -> Bool in
                return service.isControlType
            }
        }
        
        if let identifiers = accessory.uniqueIdentifiersForBridgedAccessories {
            bridgedAccessories = home.accessoriesWithIdentifiers(identifiers).sortByLocalizedName()
        }
        tableView.reloadData()
    }
    
    // MARK:  HMAccessoryDelegate Methods
    
    /// Reloads the title based on the accessories new name.
    func accessoryDidUpdateName(accessory: HMAccessory) {
        updateTitle()
    }
    
    /// Reloads the cell for the specified service.
    func accessory(accessory: HMAccessory, didUpdateNameForService service: HMService) {
        if let index = displayedServices.indexOf(service) {
            let path = NSIndexPath(forRow: index, inSection: AccessoryTableViewSection.Services.rawValue)
            tableView.reloadRowsAtIndexPaths([path], withRowAnimation: .Automatic)
        }
    }
    
    /// Reloads the view.
    func accessoryDidUpdateServices(accessory: HMAccessory) {
        reloadData()
    }
    
    /// If our accessory has become unreachable, go back the previous view.
    func accessoryDidUpdateReachability(accessory: HMAccessory) {
        if self.accessory == accessory {
            navigationController?.popViewControllerAnimated(true)
        }
    }
}
