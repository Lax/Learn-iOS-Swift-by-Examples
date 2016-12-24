/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `FavoritesViewController` allows users to control pinned accessories.
*/

import UIKit
import HomeKit

/**
    Lists favorite characteristics (grouped by accessory) and allows users to 
    manipulate their values.
*/
class FavoritesViewController: UITableViewController, UITabBarControllerDelegate, HMAccessoryDelegate, HMHomeManagerDelegate {
    
    // MARK: Types
    
    struct Identifiers {
        static let characteristicCell = "CharacteristicCell"
        static let segmentedControlCharacteristicCell = "SegmentedControlCharacteristicCell"
        static let switchCharacteristicCell = "SwitchCharacteristicCell"
        static let sliderCharacteristicCell = "SliderCharacteristicCell"
        static let textCharacteristicCell = "TextCharacteristicCell"
        static let serviceTypeCell = "ServiceTypeCell"
    }
    
    // MARK: Properties
    
    var favoriteAccessories = FavoritesManager.sharedManager.favoriteAccessories
    
    var cellDelegate = AccessoryUpdateController()
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    /// If `true`, the characteristic cells should show stars.
    var showsFavorites = false {
        didSet {
            editButton.title = showsFavorites ? NSLocalizedString("Done", comment: "Done") : NSLocalizedString("Edit", comment: "Edit")

            reloadData()
        }
    }
    
    // MARK: View Methods
    
    /// Configures the table view and tab bar.
    override func awakeFromNib() {
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.allowsSelectionDuringEditing = true

        registerReuseIdentifiers()
        
        tabBarController?.delegate = self
    }
    
    /// Prepares HomeKit objects and reloads view.
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        registerAsDelegate()
        
        setNotificationsEnabled(true)
        
        reloadData()
    }
    
    /// Disables notifications and "unregisters" as the delegate for the home manager.
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        setNotificationsEnabled(false)

        // We don't want any more callbacks once the view has disappeared.
        HomeStore.sharedStore.homeManager.delegate = nil
    }
    
    /// Registers for all types of characteristic cells.
    private func registerReuseIdentifiers() {
        let characteristicNib = UINib(nibName: Identifiers.characteristicCell, bundle: nil)
        tableView.registerNib(characteristicNib, forCellReuseIdentifier: Identifiers.characteristicCell)
        
        let sliderNib = UINib(nibName: Identifiers.sliderCharacteristicCell, bundle: nil)
        tableView.registerNib(sliderNib, forCellReuseIdentifier: Identifiers.sliderCharacteristicCell)
        
        let switchNib = UINib(nibName: Identifiers.switchCharacteristicCell, bundle: nil)
        tableView.registerNib(switchNib, forCellReuseIdentifier: Identifiers.switchCharacteristicCell)
        
        let segmentedNib = UINib(nibName: Identifiers.segmentedControlCharacteristicCell, bundle: nil)
        tableView.registerNib(segmentedNib, forCellReuseIdentifier: Identifiers.segmentedControlCharacteristicCell)
        
        let textNib = UINib(nibName: Identifiers.textCharacteristicCell, bundle: nil)
        tableView.registerNib(textNib, forCellReuseIdentifier: Identifiers.textCharacteristicCell)
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Identifiers.serviceTypeCell)
    }
    
    // MARK: Table View Methods
    
    /**
        Provides the number of sections based on the favorite accessories count.
        Also, add/removes the background message, if required.
        
        - returns:  The favorite accessories count.
    */
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let sectionCount = favoriteAccessories.count
        
        if sectionCount == 0 {
            let message = NSLocalizedString("No Favorite Characteristics", comment: "No Favorite Characteristics")

            setBackgroundMessage(message)
        }
        else {
            setBackgroundMessage(nil)
        }
        
        return sectionCount
    }
    
    /// - returns:  The number of characteristics for accessory represented by the section index.
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let accessory = favoriteAccessories[section]

        let characteristics = FavoritesManager.sharedManager.favoriteCharacteristicsForAccessory(accessory)
        
        return characteristics.count
    }
    
    /**
        Dequeues the appropriate characteristic cell for the characteristic at the
        given index path and configures the cell based on view configurations.
    */
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let characteristics = FavoritesManager.sharedManager.favoriteCharacteristicsForAccessory(favoriteAccessories[indexPath.section])
        
        let characteristic = characteristics[indexPath.row]
        
        var reuseIdentifier = Identifiers.characteristicCell

        if characteristic.isReadOnly || characteristic.isWriteOnly {
            reuseIdentifier = Identifiers.characteristicCell
        }
        else if characteristic.isBoolean {
            reuseIdentifier = Identifiers.switchCharacteristicCell
        }
        else if characteristic.hasPredeterminedValueDescriptions {
            reuseIdentifier = Identifiers.segmentedControlCharacteristicCell
        }
        else if characteristic.isNumeric {
            reuseIdentifier = Identifiers.sliderCharacteristicCell
        }
        else if characteristic.isTextWritable {
            reuseIdentifier = Identifiers.textCharacteristicCell
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) as! CharacteristicCell

        cell.showsFavorites = showsFavorites
        cell.delegate = cellDelegate
        cell.characteristic = characteristic

        return cell
    }
    
    /// - returns:  The name of the accessory at the specified index path.
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return favoriteAccessories[section].name
    }
    
    // MARK: IBAction Methods
    
    /// Toggles `showsFavorites`, which will also reload the view.
    @IBAction func didTapEdit(sender: UIBarButtonItem) {
        showsFavorites = !showsFavorites
    }
    
    
    // MARK: Helper Methods
    
    /**
        Resets the `favoriteAccessories` array from the `FavoritesManager`,
        resets the state of the edit button, and reloads the data.
    */
    private func reloadData() {
        favoriteAccessories = FavoritesManager.sharedManager.favoriteAccessories

        editButton.enabled = !favoriteAccessories.isEmpty
        
        tableView.reloadData()
    }
    
    /**
        Enables or disables notifications for all favorite characteristics which
        support event notifications.
        
        - parameter notificationsEnabled: A `Bool` representing enabled or disabled.
    */
    private func setNotificationsEnabled(notificationsEnabled: Bool) {
        for characteristic in FavoritesManager.sharedManager.favoriteCharacteristics {
            if characteristic.supportsEventNotification {
                characteristic.enableNotification(notificationsEnabled) { error in
                    if let error = error {
                        print("HomeKit: Error enabling notification on characteristic \(characteristic): \(error.localizedDescription).")
                    }
                }
            }
        }
    }
    
    /**
        Registers as the delegate for the home manager and all
        favorite accessories.
    */
    private func registerAsDelegate() {
        HomeStore.sharedStore.homeManager.delegate = self

        for accessory in favoriteAccessories {
            accessory.delegate = self
        }
    }
    
    // MARK: HMAccessoryDelegate Methods
    
    /// Update the view to disable cells with unavailable accessories.
    func accessoryDidUpdateReachability(accessory: HMAccessory) {
        reloadData()
    }
    
    /// Search for the cell corresponding to that characteristic and update its value.
    func accessory(accessory: HMAccessory, service: HMService, didUpdateValueForCharacteristic characteristic: HMCharacteristic) {
        guard let accessory = characteristic.service?.accessory else { return }

        guard let indexOfAccessory = favoriteAccessories.indexOf(accessory) else { return }
        
        let favoriteCharacteristics = FavoritesManager.sharedManager.favoriteCharacteristicsForAccessory(accessory)
        
        guard let indexOfCharacteristic = favoriteCharacteristics.indexOf(characteristic) else { return }
        
        let indexPath = NSIndexPath(forRow: indexOfCharacteristic, inSection: indexOfAccessory)
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! CharacteristicCell
        
        cell.setValue(characteristic.value, notify: false)
    }
    
    // MARK: HMHomeManagerDelegate Methods
    
    /// Reloads views and re-configures characteristics.
    func homeManagerDidUpdateHomes(manager: HMHomeManager) {
        registerAsDelegate()
        setNotificationsEnabled(true)
        reloadData()
    }
}
