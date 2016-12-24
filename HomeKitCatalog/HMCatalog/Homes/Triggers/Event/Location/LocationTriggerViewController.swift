/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `LocationTriggerViewController` allows the user to modify and create Location triggers.
*/

import UIKit
import MapKit
import HomeKit
import AddressBookUI
import Contacts

/// A view controller which facilitates the creation of a location trigger.
class LocationTriggerViewController: EventTriggerViewController {
    
    struct Identifiers {
        static let locationCell = "LocationCell"
        static let regionStatusCell = "RegionStatusCell"
        static let selectLocationSegue = "Select Location"
    }
    
    static let geocoder = CLGeocoder()
    
    static let regionStatusTitles = [
        NSLocalizedString("When I Enter The Area", comment: "When I Enter The Area"),
        NSLocalizedString("When I Leave The Area", comment: "When I Leave The Area")
    ]
    
    var locationTriggerCreator: LocationTriggerCreator {
        return triggerCreator as! LocationTriggerCreator
    }
    
    var localizedAddress: String?
    
    var viewIsDisplayed = false
    
    // MARK: View Methods
    
    /// Initializes a trigger creator and registers for table view cells.
    override func viewDidLoad() {
        super.viewDidLoad()
        triggerCreator = LocationTriggerCreator(trigger: trigger, home: home)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Identifiers.locationCell)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Identifiers.regionStatusCell)
    }
    
    /**
        Generates an address string for the current region location and
        reloads the table view.
    */
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        viewIsDisplayed = true
        if let region = locationTriggerCreator.targetRegion {
            let centerLocation = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
            LocationTriggerViewController.geocoder.reverseGeocodeLocation(centerLocation) { placemarks, error in
                if !self.viewIsDisplayed {
                    // The geocoder took too long, we're not on this view any more.
                    return
                }
                if let error = error {
                    self.displayError(error)
                    return
                }
                if let mostLikelyPlacemark = placemarks?.first {
                    let address = CNMutablePostalAddress(placemark: mostLikelyPlacemark)
                    let addressFormatter = CNPostalAddressFormatter()
                    let addressString = addressFormatter.stringFromPostalAddress(address)
                    self.localizedAddress = addressString.stringByReplacingOccurrencesOfString("\n", withString: ", ")
                    let section = NSIndexSet(index: 2)
                    self.tableView.reloadSections(section, withRowAnimation: .Automatic)
                }
            }
        }
        tableView.reloadData()
    }
    
    /// Passes the trigger creator and region into the `MapViewController`.
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        if segue.identifier == Identifiers.selectLocationSegue {
            guard let destinationVC = segue.intendedDestinationViewController as? MapViewController else { return }
            // Give the map the previous target region (if exists).
            destinationVC.targetRegion = locationTriggerCreator.targetRegion
            destinationVC.delegate = locationTriggerCreator
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        viewIsDisplayed = false
    }
    
    // MARK: Table View Methods
    
    /**
        - returns:  The number of rows in the Region section;
                    defaults to the super implementation for other sections.
    */
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sectionForIndex(section) {
            case .Region?:
                return 2
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    /**
        Generates a cell based on the section.
        Handles Region and Location sections, defaults to
        super implementations for other sections.
    */
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch sectionForIndex(indexPath.section) {
            case .Region?:
                return self.tableView(tableView, regionStatusCellForRowAtIndexPath: indexPath)
                
            case .Location?:
                return self.tableView(tableView, locationCellForRowAtIndexPath: indexPath)
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        }
    }
    
    /// Generates the single location cell.
    private func tableView(tableView: UITableView, locationCellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.locationCell, forIndexPath: indexPath)
        cell.accessoryType = .DisclosureIndicator
        
        if locationTriggerCreator.targetRegion != nil {
            cell.textLabel?.text = localizedAddress ?? NSLocalizedString("Update Location", comment: "Update Location")
        }
        else {
            cell.textLabel?.text = NSLocalizedString("Set Location", comment: "Set Location")
        }
        return cell
    }
    
    /// Generates the cell which allow the user to select either 'on enter' or 'on exit'.
    private func tableView(tableView: UITableView, regionStatusCellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.regionStatusCell, forIndexPath: indexPath)
        cell.textLabel?.text = LocationTriggerViewController.regionStatusTitles[indexPath.row]
        cell.accessoryType = (locationTriggerCreator.targetRegionStateIndex == indexPath.row) ? .Checkmark : .None
        return cell
    }
    
    /**
        Allows the user to select a location or change the region status.
        Defaults to the super implmentation for other sections.
    */
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch sectionForIndex(indexPath.section) {
            case .Location?:
                performSegueWithIdentifier(Identifiers.selectLocationSegue, sender: self)
                
            case .Region?:
                locationTriggerCreator.targetRegionStateIndex = indexPath.row
                let reloadIndexSet = NSIndexSet(index: indexPath.section)
                tableView.reloadSections(reloadIndexSet, withRowAnimation: .Automatic)
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        }
    }
    
    /**
        - returns:  A localized title for the Location and Region sections.
                    Defaults to the super implmentation for other sections.
    */
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch sectionForIndex(section) {
            case .Location?:
                return NSLocalizedString("Location", comment: "Location")
                
            case .Region?:
                return NSLocalizedString("Region Status", comment: "Region Status")
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                return super.tableView(tableView, titleForHeaderInSection: section)
        }
    }
    
    /**
        - returns:  A localized description of the region status.
                    Defaults to the super implmentation for other sections.
    */
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch sectionForIndex(section) {
            case .Region?:
                return NSLocalizedString("This trigger can activate when you enter or leave a region. For example, when you arrive at home or when you leave work.", comment: "Location Region Description")
                
            case nil:
                fatalError("Unexpected `TriggerTableViewSection` raw value.")
                
            default:
                return super.tableView(tableView, titleForFooterInSection: section)
        }
    }
    
    // MARK: Trigger Controller Methods
    
    /**
        - parameter index: The section index.
        
        - returns: The `TriggerTableViewSection` for the given index.
    */
    override func sectionForIndex(index: Int) -> TriggerTableViewSection? {
        switch index {
            case 0:
                return .Name
                
            case 1:
                return .Enabled
                
            case 2:
                return .Location
                
            case 3:
                return .Region
                
            case 4:
                return .Conditions
                
            case 5:
                return .ActionSets
                
            default:
                return nil
        }
    }
}