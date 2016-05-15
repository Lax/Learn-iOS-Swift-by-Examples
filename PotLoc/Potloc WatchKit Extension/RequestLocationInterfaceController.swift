/*
Copyright (C) 2016 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

*/

import WatchKit
import Foundation

/**
    The `RequestLocationInterfaceController` is responsible for communicating between
    the "Request" interface and the `LocationModel`. This interface controller exemplifies
    how to call the `CLLocationManager` directly from a WatchKit Extension using 
    the `requestLocation(_:)` method.

    In order to guarantee that the information displayed in the interface is fresh,
    this class uses a 2 second timeout after every location update to reset the
    interface. This is done in order to make the example more clear and to avoid stale
    data polluting the interface.
*/
class RequestLocationInterfaceController: WKInterfaceController, CLLocationManagerDelegate {
    // MARK: Properties
    
    /// Location manager to request authorization and location updates.
    let manager = CLLocationManager()
    
    /// Flag indicating whether the manager is requesting the user's location.
    var isRequestingLocation = false
    
    /// Button to request location. Also allows cancelling the location request.
    @IBOutlet var requestLocationButton: WKInterfaceButton!
    
    /// Label to display the most recent location's latitude.
    @IBOutlet var latitudeLabel: WKInterfaceLabel!
    
    /// Label to display the most recent location's longitude.
    @IBOutlet var longitudeLabel: WKInterfaceLabel!
    
    /// Label to display an error if the location manager finishes with an error.
    @IBOutlet var errorLabel: WKInterfaceLabel!
    
    // MARK: Localized String Convenience

    var interfaceTitle: String {
        return NSLocalizedString("Request", comment: "Indicates that this interface exemplifies requesting location from the watch")
    }
    
    var requestLocationTitle: String {
        return NSLocalizedString("Request Location", comment: "Button title to indicate that pressing the button will cause the location manager to request location")
    }

    var cancelTitle: String {
        return NSLocalizedString("Cancel", comment: "Cancel the current action")
    }
    
    var deniedText: String {
        return NSLocalizedString("Location authorization denied.", comment: "Text to indicate authorization status is .Denied")
    }
    
    var unexpectedText: String {
        return NSLocalizedString("Unexpected authorization status.", comment: "Text to indicate authorization status is an unexpected value")
    }
    
    // MARK: Interface Controller
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        setTitle(interfaceTitle)
        
        // Remember to set the location manager's delegate.
        manager.delegate = self
        
        latitudeLabel.setAlpha(0)
        longitudeLabel.setAlpha(0)
        errorLabel.setAlpha(0)
    }
    
    /// MARK - Button Actions
    
    /**
        When the user taps the Request Location button in the interface, this method 
        informs the `LocationModel`'s shared instance to request a location.
    
        If the user is already requesting location, this method will instead cancel
        the request.
    */
    @IBAction func requestLocation(sender: AnyObject) {
        guard !isRequestingLocation else {
            manager.stopUpdatingLocation()
            isRequestingLocation = false
            requestLocationButton.setTitle(requestLocationTitle)

            return
        }

        let authorizationStatus = CLLocationManager.authorizationStatus()

        switch authorizationStatus {
            case .NotDetermined:
                isRequestingLocation = true
                requestLocationButton.setTitle(cancelTitle)
                manager.requestWhenInUseAuthorization()

            case .AuthorizedWhenInUse:
                isRequestingLocation = true
                requestLocationButton.setTitle(cancelTitle)
                manager.requestLocation()
            
            case .Denied:
                errorLabel.setAlpha(1)
                errorLabel.setText(deniedText)
                simulateFadeOut(errorLabel)
            
            default:
                errorLabel.setAlpha(1)
                errorLabel.setText(unexpectedText)
                simulateFadeOut(errorLabel)
        }
    }
    
    /// MARK - CLLocationManagerDelegate Methods
    
    /**
        When the location manager receives new locations, display the latitude and
        longitude of the latest location and restart the timers.
    */
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !locations.isEmpty else { return }

        dispatch_async(dispatch_get_main_queue()) {
            let lastLocationCoordinate = locations.last!.coordinate
            
            self.latitudeLabel.setText(String(lastLocationCoordinate.latitude))
            
            self.longitudeLabel.setText(String(lastLocationCoordinate.longitude))
            
            self.latitudeLabel.setAlpha(1)
            
            self.longitudeLabel.setAlpha(1)
            
            self.isRequestingLocation = false
            
            self.requestLocationButton.setTitle(self.requestLocationTitle)
            
            self.simulateFadeOut(self.latitudeLabel)
            
            self.simulateFadeOut(self.longitudeLabel)
        }
    }
    
    /**
        When the location manager receives an error, display the error and restart
        the timers.
    */
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        dispatch_async(dispatch_get_main_queue()) {
            self.errorLabel.setAlpha(1)
            
            self.errorLabel.setText(String(error.localizedDescription))

            self.isRequestingLocation = false
            
            self.requestLocationButton.setTitle(self.requestLocationTitle)
            
            self.simulateFadeOut(self.errorLabel)
        }
    }
    
    /**
        Only request location if the authorization status changed to an 
        authorization level that permits requesting location.
    */
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        dispatch_async(dispatch_get_main_queue()) {
            guard self.isRequestingLocation else { return }

            switch status {
                case .AuthorizedWhenInUse:
                    manager.requestLocation()
                    
                case .Denied:
                    self.errorLabel.setAlpha(1)
                    self.errorLabel.setText(self.deniedText)
                    self.isRequestingLocation = false
                    self.requestLocationButton.setTitle(self.requestLocationTitle)
                    self.simulateFadeOut(self.errorLabel)
                    
                default:
                    self.errorLabel.setAlpha(1)
                    self.errorLabel.setText(self.unexpectedText)
                    self.isRequestingLocation = false
                    self.requestLocationButton.setTitle(self.requestLocationTitle)
                    self.simulateFadeOut(self.errorLabel)
            }
        }
    }
    
    /// MARK - Resetting
    
    /**
        Simulates fading out animation by setting the alpha of the given label to
        progressively smaller numbers.
    */
    func simulateFadeOut(label: WKInterfaceLabel) {
        let mainQueue = dispatch_get_main_queue()
        
        for index in 1...10 {
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(index) / 10.0 * Double(NSEC_PER_SEC)))

            dispatch_after(time, mainQueue) {
                let alphaAmount = CGFloat(1 - (0.1 * Float(index)))

                label.setAlpha(alphaAmount)
            }
        }
    }
}
