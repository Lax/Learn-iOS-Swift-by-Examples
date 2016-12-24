/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `HomeListConfigurationViewController` allows for the creation and deletion of homes.
*/

import UIKit
import HomeKit

// Represents the sections in the `HomeListConfigurationViewController`.
enum HomeListSection: Int {
    case Homes, PrimaryHome
    
    static let count = 2
}

/**
    A `HomeListViewController` subclass which allows the user to add and remove 
    homes and set the primary home.
*/
class HomeListConfigurationViewController: HomeListViewController {
    // MARK: Types
    
    struct Identifiers {
        static let addHomeCell = "AddHomeCell"
        static let noHomesCell = "NoHomesCell"
        static let primaryHomeCell = "PrimaryHomeCell"
    }
    
    // MARK: Table View Methods
    
    /// - returns:  The number of sections in the `HomeListSection` enum.
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return HomeListSection.count
    }
    
    /// Provides the number of rows in the section using the internal home's list.
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch HomeListSection(rawValue: section) {
            // Add row.
            case .Homes?:
                return homes.count + 1

            // 'No homes' row.
            case .PrimaryHome?:
                return max(homes.count, 1)
            
            case nil: fatalError("Unexpected `HomeListSection` raw value.")
        }
    }
    
    /**
        Generates and configures either a content cell or an add cell using the 
        provided index path.
    */
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPathIsAdd(indexPath) {
            return tableView.dequeueReusableCellWithIdentifier(Identifiers.addHomeCell, forIndexPath: indexPath)
        }
        else if homes.isEmpty {
            return tableView.dequeueReusableCellWithIdentifier(Identifiers.noHomesCell, forIndexPath: indexPath)
        }
        
        let reuseIdentifier: String

        switch HomeListSection(rawValue: indexPath.section) {
            case .Homes?:
                reuseIdentifier = Identifiers.homeCell

            case .PrimaryHome?:
                reuseIdentifier = Identifiers.primaryHomeCell
            
            case nil: fatalError("Unexpected `HomeListSection` raw value.")
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)
        let home = homes[indexPath.row]
        
        cell.textLabel!.text = home.name
        cell.detailTextLabel?.text = sharedTextForHome(home)
        
        // Mark the primary home with checkmark.
        if HomeListSection(rawValue: indexPath.section) == .PrimaryHome {
            if home == homeManager.primaryHome {
                cell.accessoryType = .Checkmark
            }
            else {
                cell.accessoryType = .None
            }
        }
        
        return cell
    }
    
    /// Homes in the list section can be deleted. The add row cannot be deleted.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return HomeListSection(rawValue: indexPath.section) == .Homes && !indexPathIsAdd(indexPath)
    }
    
    /// Only the 'primary home' section has a title.
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if HomeListSection(rawValue: section) == .PrimaryHome {
            return NSLocalizedString("Primary Home", comment: "Primary Home")
        }

        return nil
    }
    
    /// Provides subtext about the use of designating a "primary home".
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == HomeListSection.PrimaryHome.rawValue {
            return NSLocalizedString("The primary home is used by Siri to route commands if the home is not specified.", comment: "Primary Home Description")
        }
        return nil
    }
    
    /**
        If selecting a regular home, a segue will be performed.
        If this method is called, the user either selected the 'add' row,
        a primary home cell, or the `No Homes` cell.
    */
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPathIsAdd(indexPath) {
            addNewHome()
        }
        else if indexPathIsNone(indexPath) {
            return
        }
        else if HomeListSection(rawValue: indexPath.section) == .PrimaryHome {
            let newPrimaryHome = homes[indexPath.row]
            updatePrimaryHome(newPrimaryHome)
        }
    }
    
    /// Removes the home from HomeKit if the row is deleted.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            removeHomeAtIndexPath(indexPath)
        }
    }
    
    // MARK: Helper Methods
    
    /**
        Updates the primary home in HomeKit and reloads the view.
        If the home is already selected, no action is taken.
        
        - parameter newPrimaryHome: The new `HMHome` to set as the primary home.
    */
    private func updatePrimaryHome(newPrimaryHome: HMHome) {
        guard newPrimaryHome != homeManager.primaryHome else { return }

        homeManager.updatePrimaryHome(newPrimaryHome) { error in
            if let error = error {
                self.displayError(error)
                return
            }
            
            self.didUpdatePrimaryHome()
        }
    }
    
    /// Reloads the 'primary home' section.
    private func didUpdatePrimaryHome() {
        let primaryIndexSet = NSIndexSet(index: HomeListSection.PrimaryHome.rawValue)
      
        tableView.reloadSections(primaryIndexSet, withRowAnimation: .Automatic)
    }
    
    /**
        Removed the home at the specified index path from HomeKit and updates the view.
        
        - parameter indexPath: The `NSIndexPath` of the home to remove.
    */
    private func removeHomeAtIndexPath(indexPath: NSIndexPath) {
        let home = homes[indexPath.row]

        // Remove the home from the data structure. If it fails, put it back.
        didRemoveHome(home)
        homeManager.removeHome(home) { error in
            if let error = error {
                self.displayError(error)
                self.didAddHome(home)
                return
            }
        }
    }
    
    /**
        Presents an alert controller so the user can provide a name. If committed, 
        the home is created.
    */
    private func addNewHome() {
        let attributedType = NSLocalizedString("Home", comment: "Home")
        let placeholder = NSLocalizedString("Apartment", comment: "Apartment")

        presentAddAlertWithAttributeType(attributedType, placeholder: placeholder) { name in
            self.addHomeWithName(name)
        }
    }
    
    /**
        Removes a home from the internal structure and updates the view.
        
        - parameter home: The `HMHome` to remove.
    */
    override func didRemoveHome(home: HMHome) {
        guard let index = homes.indexOf(home) else { return }

        let indexPath = NSIndexPath(forRow: index, inSection: HomeListSection.Homes.rawValue)
        homes.removeAtIndex(index)
        let primaryIndexPath = NSIndexPath(forRow: index, inSection: HomeListSection.PrimaryHome.rawValue)
        
        /*
            If there aren't any homes, we still want one cell to display 'No Homes'.
            Just reload.
        */
        tableView.beginUpdates()
        if homes.isEmpty {
            tableView.reloadRowsAtIndexPaths([primaryIndexPath], withRowAnimation: .Fade)
        }
        else {
            tableView.deleteRowsAtIndexPaths([primaryIndexPath], withRowAnimation: .Automatic)
        }
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        tableView.endUpdates()

    }
    
    /// Adds the home to the internal structure and updates the view.
    override func didAddHome(home: HMHome) {
        homes.append(home)
        sortHomes()
        guard let newHomeIndex = homes.indexOf(home) else { return }

        let indexPath = NSIndexPath(forRow: newHomeIndex, inSection: HomeListSection.Homes.rawValue)
        
        let primaryIndexPath = NSIndexPath(forRow: newHomeIndex, inSection: HomeListSection.PrimaryHome.rawValue)
        
        tableView.beginUpdates()
        
        if homes.count == 1 {
            tableView.reloadRowsAtIndexPaths([primaryIndexPath], withRowAnimation: .Fade)
        }
        else {
            tableView.insertRowsAtIndexPaths([primaryIndexPath], withRowAnimation: .Automatic)
        }
        
        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        tableView.endUpdates()
    }
    
    /**
        Creates a new home with the provided name, adds the home to HomeKit
        and reloads the view.
    */
    private func addHomeWithName(name: String) {
        homeManager.addHomeWithName(name) { newHome, error in
            if let error = error {
                self.displayError(error)
                return
            }

            self.didAddHome(newHome!)
        }
    }
    

    /// - returns:  `true` if the index path is the 'add row'; `false` otherwise.
    private func indexPathIsAdd(indexPath: NSIndexPath) -> Bool {
        return HomeListSection(rawValue: indexPath.section) == .Homes &&
            indexPath.row == homes.count
    }
    
    /// - returns:  `true` if the index path is the 'No Homes' cell; `false` otherwise.
    private func indexPathIsNone(indexPath: NSIndexPath) -> Bool {
        return HomeListSection(rawValue: indexPath.section) == .PrimaryHome && homes.isEmpty
    }
    
    // MARK: HMHomeDelegate Methods
    
    /// Finds the home in the internal structure and reloads the corresponding row.
    override func homeDidUpdateName(home: HMHome) {
        if let index = homes.indexOf(home) {
            let listIndexPath = NSIndexPath(forRow: index, inSection: HomeListSection.Homes.rawValue)

            let primaryIndexPath = NSIndexPath(forRow: index, inSection: HomeListSection.PrimaryHome.rawValue)
            
            tableView.reloadRowsAtIndexPaths([listIndexPath, primaryIndexPath], withRowAnimation: .Automatic)
        }
        else {
            // Just reload the data since we don't know the index path.
            tableView.reloadData()
        }
    }
    
    // MARK: HMHomeManagerDelegate Methods
    
    /// Reloads the 'primary home' section.
    func homeManagerDidUpdatePrimaryHome(manager: HMHomeManager) {
        didUpdatePrimaryHome()
    }
}