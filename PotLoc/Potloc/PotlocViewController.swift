/*
Copyright (C) 2016 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Contains the PotlocViewController which shows how to use CLLocationManager and WCSession together to communicate between an iPhone and an Apple Watch.
*/

import UIKit
import WatchConnectivity
import CoreLocation

/**
    The `PotlocViewController` is responsible for maintaining the `CLLocationManager`
    and the `WCSession`. When the watch sends a start or stop message, the `PotlocViewController`
    informs the `CLLocationManager` to act accordingly. As the location manager accumulates
    locations, the `PotlocViewController` maintains a cumulative count of how many
    locations have been received. On a five second timeout, the `PotlocViewController` sends
    the location count to the watch to be processed as needed.

    The `PotlocViewController` can also start and stop updating location using the
    `startStopUpdatingLocationButton`. When location updates are started or stopped, 
    both views are informed of the change so they can both update accordingly.

    When sending streamed information such as location updates to the watch, it
    is recommended to batch the updates and send them less frequently than received.
*/
class PotlocViewController: UIViewController, WCSessionDelegate, CLLocationManagerDelegate {
    // MARK: Properties
    
    /// Default WatchConnectivity session for communicating with the watch.
    let session = WCSession.defaultSession()
    
    /// Location manager used to start and stop updating location.
    let manager = CLLocationManager()
    
    /// Indicates whether the location manager is updating location.
    var isUpdatingLocation = false
    
    /// Cumulative count of received locations.
    var receivedLocationCount = 0
    
    /// The number of locations that will be sent in a batch to the watch.
    var locationBatchCount = 0
    
    /**
        Timer to send the cumulative count to the watch.
        To avoid polluting IDS traffic, its better to send batch updates to the watch
        instead of sending the updates as they arrive.
    */
    var sessionMessageTimer = NSTimer()
    
    /**
        Label to show the status of the Location Manager: running or not running.
        This label is useful for debugging.
    */
    @IBOutlet weak var managerStatusLabel: UILabel!

    /// Static text informing the user of the meaning of the location batch size label.
    @IBOutlet weak var locationBatchSizeTitleLabel: UILabel!
    
    /// Indicates to the user the number of locations that will be sent to the watch.
    @IBOutlet weak var locationBatchSizeLabel: UILabel!
    
    /// Static text informing the user of the meaning of the received location count label.
    @IBOutlet weak var receivedLocationCountTitleLabel: UILabel!
    
    /// Indicates to the user the total number of locations that have been received since starting the app.
    @IBOutlet weak var receivedLocationCountLabel: UILabel!
    
    /// Button to start or stop updating location. Outlet is used to set the text depending on the action.
    @IBOutlet weak var startStopUpdatingLocationButton: UIButton!
    
    // MARK: Localized String Convenience

    var updatingLocationText: String {
        return NSLocalizedString("Location manager updating location", comment: "Inform user the location manager is updating location")
    }
    
    var notUpdatingLocationText: String {
        return NSLocalizedString("Location manager not updating location", comment: "Inform user the location manager is not updating location")
    }
    
    var startButtonTitle: String {
        return NSLocalizedString("Start updating location", comment: "Pressing this button will start updating location")
    }
    
    var stopButtonTitle: String {
        return NSLocalizedString("Stop updating location", comment: "Pressing this button will stop updating location")
    }
    
    var locationBatchSizeTitleText: String {
        return NSLocalizedString("Locations received since last context update", comment: "Informs the user how many locations have been received since last batch push to the watch")
    }
    
    var receivedLocationCountTitleText: String {
        return NSLocalizedString("Total locations received", comment: "Informs the user how many locations have been received since starting the app")
    }
    
    // MARK: Initialization
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }
    

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        commonInit()
    }
    
    /**
        Sets the delegates and activate the `WCSession`.
        
        The `WCSession` needs to be activated in the init methods so that when the
        app is launched into the background when it wasn't previously running, the
        session can still be activated allowing communication between the watch and
        the phone. Activating the session in the `viewDidLoad()` method wont suffice
        since the `viewDidLoad()` method will not be called if the app is launched
        into the background.
    */
    func commonInit() {
        
        // Initialize the `WCSession` and the `CLLocationManager`.
        session.delegate = self
        session.activateSession()
        
        manager.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        locationBatchSizeTitleLabel.text = locationBatchSizeTitleText
        receivedLocationCountTitleLabel.text = receivedLocationCountTitleText
    }
    
    /**
        Starts updating location and allows the app to receive background location 
        updates.
    
        This method also sets the view into a state that lets the user know that
        the manager has started updating location, as well as starts the batch timer
        for sending location counts to the watch.
    
        Use `commandedFromPhone` to determine whether or not to call `requestWhenInUseAuthorization()`.
        If this method was called due to a command from the watch, the watch should
        be responsible for requesting authorization, and therefore this method 
        should not request authorization. This ensures that the authorization prompt 
        will come from the device that the user is currently interacting with.
    */
    func startUpdatingLocationAllowingBackground(commandedFromPhone commandedFromPhone: Bool) {
        isUpdatingLocation = true
        /* 
            When commanding from the phone, request authorization and inform the
            watch app of the state change.
        */
        if commandedFromPhone {
            manager.requestWhenInUseAuthorization()

            do {
                try session.updateApplicationContext([
                    MessageKey.StateUpdate.rawValue: isUpdatingLocation,
                    MessageKey.LocationCount.rawValue: String(receivedLocationCount)
                ])
            }
            catch let error as NSError {
                print("Error when updating application context \(error.localizedDescription).")
            }
        }

        manager.allowsBackgroundLocationUpdates = true
        
        manager.startUpdatingLocation()
        
        sessionMessageTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(PotlocViewController.sendLocationCount), userInfo: nil, repeats: true)
        
        managerStatusLabel.text = updatingLocationText
        
        startStopUpdatingLocationButton.setTitle(stopButtonTitle, forState: .Normal)
    }
    
    /**
        Informs the manager to stop updating location, invalidates the timer, and 
        updates the view.
    
        If the command comes from the phone, this method sends a state update to 
        the watch to inform the watch that location updates have stopped.
    */
    func stopUpdatingLocation(commandedFromPhone commandedFromPhone: Bool) {
        isUpdatingLocation = false
        /*
            When commanding from the phone, request authorization and inform the 
            watch app of the state change.
        */
        if commandedFromPhone {
            do {
                try session.updateApplicationContext([
                    MessageKey.StateUpdate.rawValue: isUpdatingLocation,
                    MessageKey.LocationCount.rawValue: String(receivedLocationCount)
                ])
            }
            catch let error as NSError {
                print("Error when updating application context \(error.localizedDescription)")
            }
        }

        manager.stopUpdatingLocation()
        
        manager.allowsBackgroundLocationUpdates = false
        
        sessionMessageTimer.invalidate()
        
        managerStatusLabel.text = notUpdatingLocationText
     
        startStopUpdatingLocationButton.setTitle(startButtonTitle, forState: .Normal)
    }
    
    /**
        Responds to the button press by either starting or stopping location updates
        depending on the current state.
    */
    @IBAction func startStopUpdatingLocation(sender: AnyObject) {
        if isUpdatingLocation {
            stopUpdatingLocation(commandedFromPhone: true)
        }
        else {
            startUpdatingLocationAllowingBackground(commandedFromPhone: true)
        }
    }
    
    /**
        On the receipt of a message, check for expected commands.

        On a `startUpdatingLocation` command, inform the manager to start updating
        location, and start a repeating 5 second timer that sends the cumulative 
        location count to the watch.

        On a `stopUpdatingLocation` command, inform the manager to stop updating 
        location, and stop the repeating timer.
    */
    func session(session: WCSession, didReceiveMessage message: [String: AnyObject], replyHandler: [String: AnyObject] -> Void) {
        guard let messageCommandString = message[MessageKey.Command.rawValue] as? String else { return }

        guard let messageCommand = MessageCommand(rawValue: messageCommandString) else {
            print("Unknown command \(messageCommandString).")
            return
        }

        dispatch_async(dispatch_get_main_queue()) {
            switch messageCommand {
                case .StartUpdatingLocation:
                    self.startUpdatingLocationAllowingBackground(commandedFromPhone: false)

                    replyHandler([
                        MessageKey.Acknowledge.rawValue: messageCommand.rawValue
                    ])

                case .StopUpdatingLocation:
                    self.stopUpdatingLocation(commandedFromPhone: false)

                    replyHandler([
                        MessageKey.Acknowledge.rawValue: messageCommand.rawValue
                    ])
                
                case .SendLocationStatus:
                    replyHandler([
                        MessageKey.Acknowledge.rawValue: self.isUpdatingLocation
                    ])
            }
        }
    }
    
    /**
        Send the current cumulative location to the watch and reset the batch
        count to zero.
    */
    func sendLocationCount() {
        do {
            try session.updateApplicationContext([
                MessageKey.StateUpdate.rawValue: isUpdatingLocation,
                MessageKey.LocationCount.rawValue: String(receivedLocationCount)
            ])
            
            locationBatchCount = 0
            
            locationBatchSizeLabel.text = String(locationBatchCount)
        }
        catch let error as NSError {
            print("Error when updating application context \(error).")
        }
    }
    
    /**
        Increases that location count by the number of locations received by the 
        manager. Updates the batch count with the added locations.
    */
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        receivedLocationCount = receivedLocationCount + locations.count
        locationBatchCount = locationBatchCount + locations.count

        locationBatchSizeLabel.text = String(locationBatchCount)
        
        receivedLocationCountLabel.text = String(receivedLocationCount)
    }
    
    /// Log any errors to the console.
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error occured: \(error.localizedDescription).")
    }
}
