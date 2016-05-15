/*
Copyright (C) 2016 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

*/

import WatchKit
import Foundation
import WatchConnectivity
import CoreLocation

/**
    `StreamLocationInterfaceController` is responsible for communicating between 
    the "Stream" interface, the phone, and the `CLLocationManager`. The
    `StreamLocationInterfaceController` is not a `CLLocationManagerDelegate` since
    it is unconcerned with the delegate callbacks.

    When the user starts location updates, this controller first informs the
    `CLLocationManager` to `requestWhenInUseAuthorization()`, then sends a message
    to the phone to start updating locations. When the user stops location updates,
    this controller sends a message to the phone to stop location updates.

    When the phone sends an update to the cumulative number of locations it has
    received, this controller the interface, displaying the new number of received
    locations to the user.
*/
class StreamLocationInterfaceController: WKInterfaceController, WCSessionDelegate, CLLocationManagerDelegate {
    // MARK: Properties
    
    /// Default WatchConnectivity session for communicating with the phone.
    let session = WCSession.defaultSession()
    
    /// Location manager for requesting authorization when starting location updates.
    var manager: CLLocationManager?
    
    /**
        Static text informing the user of the meaning of the `locationsReceivedOnPhoneCount` 
        label.
    */
    @IBOutlet var locationsReeivedOnPhoneCountTitleLabel: WKInterfaceLabel!
    
    /// Label to display the number of locations that the phone has received.
    @IBOutlet var locationsReceivedOnPhoneCount: WKInterfaceLabel!
    
    /// Button to send start/stop location update commands to the phone.
    @IBOutlet var startStopButton: WKInterfaceButton!
    
    /// Flag to determine whether to command start or stop updating location.
    var commandStartUpdatingLocation = true
    
    // MARK: Localized String Convenience

    var interfaceTitle: String {
        return NSLocalizedString("Stream", comment: "Indicates to the user that this interface exemplifies how to start and stop location updates on the phone and stream the results to the watch")
    }
    
    var locationsReceivedText: String {
        return NSLocalizedString("iPhone Locations Received:", comment: "Informs the user that the number below represents the number of locations received on the iPhone")
    }
    
    var startingTitle: String {
        return NSLocalizedString("Starting", comment: "Indicates that the command to start updating location has been sent")
    }
    
    var stoppingTitle: String {
        return NSLocalizedString("Stopping", comment: "Indicates that the command to stop updating location has been sent")
    }
    
    var deniedTitle: String {
        return NSLocalizedString("Denied", comment: "Indicates that the user cannot start updating location")
    }
    
    var startTitle: String {
        return NSLocalizedString("Start", comment: "Indicates to send the command to start updating location")
    }
    
    var stopTitle: String {
        return NSLocalizedString("Stop", comment: "Indicates to send the command to stop updating location")
    }

    // MARK: Interface Controller
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        setTitle(interfaceTitle)
        locationsReeivedOnPhoneCountTitleLabel.setText(locationsReceivedText)
        
        // Initialize the `WCSession`.
        session.delegate = self
        session.activateSession()
    }
    
    /// Get the current state of the location updates before showing the interface.
    override func willActivate() {
        sendLocationUpdateStatusCommand()

        super.willActivate()
    }

    /// MARK - Button Actions

    /**
        Commands the phone to start or stop updating location, and adjusts the 
        interface as necessary. Request when in use location usage before sending 
        the command to the phone. Since the user is interacting with the watch, 
        the prompt should originate from the watch.
    */
    @IBAction func startStopUpdatingLocation(sender: AnyObject) {
        guard commandStartUpdatingLocation else {
            sendStopUpdatingLocationCommand()

            return
        }

        let authorizationStatus = CLLocationManager.authorizationStatus()

        switch authorizationStatus {
            case .NotDetermined:
                startStopButton.setTitle(startingTitle)
                manager = CLLocationManager()
                manager!.delegate = self
                manager!.requestWhenInUseAuthorization()

            case .AuthorizedWhenInUse:
                sendStartUpdatingLocationCommand()
            
            case .Denied:
                startStopButton.setTitle(deniedTitle)
            
            default:
                break
        }
    }
    
    /// MARK - Sending Commands to Phone
   
    /**
        Sends the message to request a status update from the phone determining 
        if the phone is updating location.
    */
    func sendLocationUpdateStatusCommand() {
        let message = [
            MessageKey.Command.rawValue: MessageCommand.SendLocationStatus.rawValue
        ]

        session.sendMessage(message, replyHandler: { replyDict in
            guard let ack = replyDict[MessageKey.Acknowledge.rawValue] as? Bool else { return }
            self.commandStartUpdatingLocation = !ack

            let buttonTitle = ack ? self.stopTitle : self.startTitle
            self.startStopButton.setTitle(buttonTitle)
            
        }, errorHandler: { error in
            self.locationsReceivedOnPhoneCount.setText(error.localizedDescription)
        })
    }
    
    /// Sends the message to start updating location, and handles the reply.
    func sendStartUpdatingLocationCommand() {
        startStopButton.setTitle(startingTitle)
        
        let message = [
            MessageKey.Command.rawValue: MessageCommand.StartUpdatingLocation.rawValue
        ]
        
        session.sendMessage(message, replyHandler: { replyDict in
            guard let ack = replyDict[MessageKey.Acknowledge.rawValue] as? String
                  where ack == MessageCommand.StartUpdatingLocation.rawValue else { return }

            self.startStopButton.setTitle(self.stopTitle)
            self.commandStartUpdatingLocation = false
            
        }, errorHandler: { error in
            self.locationsReceivedOnPhoneCount.setText(error.localizedDescription)

            self.startStopButton.setTitle(self.startTitle)
        })
    }
    
    /// Sends the message to stop updating location, and handles the reply.
    func sendStopUpdatingLocationCommand() {
        startStopButton.setTitle(stoppingTitle)
        
        let message = [
            MessageKey.Command.rawValue: MessageCommand.StopUpdatingLocation.rawValue
        ]
        
        session.sendMessage(message, replyHandler: { replyDict in
            guard let ack = replyDict[MessageKey.Acknowledge.rawValue] as? String
                  where ack == MessageCommand.StopUpdatingLocation.rawValue else { return }
            
            self.startStopButton.setTitle(self.startTitle)
            self.commandStartUpdatingLocation = true

        }, errorHandler: { error in
            self.locationsReceivedOnPhoneCount.setText(error.localizedDescription)
            self.startStopButton.setTitle(self.stopTitle)
        })
    }
    
    /// MARK - WCSessionDelegate Methods
    
    /**
        On receipt of a locationCount message, set the text to the value of the 
        locationCount key. This is the only key expected to be sent.
    
        On receipt of a startUpdate message, update the controller's state to 
        reflect the location updating state.
    */
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String: AnyObject]) {
        dispatch_async(dispatch_get_main_queue()) {
            if let locationCount = applicationContext[MessageKey.LocationCount.rawValue] as? String {
                self.locationsReceivedOnPhoneCount.setText(locationCount)
            }
            else if let stateUpdate = applicationContext[MessageKey.StateUpdate.rawValue] as? Bool {
                self.commandStartUpdatingLocation = !stateUpdate
                
                let buttonTitle = stateUpdate ? self.stopTitle : self.startTitle
                self.startStopButton.setTitle(buttonTitle)
            }
        }
    }
    
    /// MARK - CLLocationManagerDelegate Methods
    
    /**
        Resets the location manager to nil since it is no longer needed after the 
        authorization status is updated. Also sends the command to start updating 
        location if the authorization status has changed to .AuthorizedWhenInUse.
    */
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        /*
            Only set the manager to nil if the status has been determined. This 
            prevents us from releasing the manager when the "didChangeAuthorizationStatus"
            callback is received on manager creation while the status is still not
            determined.
        */
        if status != .NotDetermined {
            self.manager = nil
        }
        
        if status == .AuthorizedWhenInUse {
            sendStartUpdatingLocationCommand()
        }
        else if status == .Denied {
            dispatch_async(dispatch_get_main_queue()) {
                self.startStopButton.setTitle(self.deniedTitle)
            }
        }
    }
}
