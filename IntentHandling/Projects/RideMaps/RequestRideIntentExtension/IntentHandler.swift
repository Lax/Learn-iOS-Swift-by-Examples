/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An object that implements the `INRequestRideIntentHandling` protocol to handle ridesharing tasks.
 */

import Intents

// The intents whose interactions you wish to handle must be declared in the extension's Info.plist.

class IntentHandler: INExtension, INRequestRideIntentHandling {
    
    // MARK: - INRequestRideIntentHandling
    
    
    func confirm(requestRide intent: INRequestRideIntent, completion: @escaping (INRequestRideIntentResponse) -> Void) {
        
        /*
         Maps uses this method to update the pickup location for the ride.
         
         Confirm with your service whether this pickup -> destination route and payment info is valid.
         
         Use the rideOptionName on the intent to match it to a ride option given in listRideOptions.
         
         In addition, create and update any details on the ride option like fare, or eta for this updated pickup location.
         
         */
        
        let rideOption = INRideOption(name: "Small car", estimatedPickupDate: Date(timeIntervalSinceNow: 5 * 60))
        
        let rideStatus = INRideStatus()
        rideStatus.rideOption = rideOption
        rideStatus.estimatedPickupDate = Date(timeIntervalSinceNow: 5 * 60)
        rideStatus.rideIdentifier = NSUUID().uuidString // This ride identifier must match the one in handleRequestRide and getRideStatus
        
        /*
         Pickup / dropoff locations
         
         You can specify different pickup / dropoff locations from the ones included in the intent.
         You may change both the coordinate and the name of the placemark.
         
         Maps will display the name that you specify, and will update the pickup location on the map to the new cooridinates.
         Use this functionality to specify dedicated pickup spots or easier to spot POIs.
         */
        
        // set pickup and dropoff locations
        
        let response = INRequestRideIntentResponse(code: .success, userActivity: nil)
        response.rideStatus = rideStatus
        
        completion(response)
    }
    
    func handle(requestRide intent: INRequestRideIntent, completion: @escaping (INRequestRideIntentResponse) -> Void) {
        
        /*
         Handle the actual request to book a ride here. Grab relevant information from the intent...
         
         - pickup location
         - dropoff location
         - ride option name
         - party size
         - payment method
         
         ...and make a call to your service.
         
         You should return a response from this method as soon as your service has acknowledged the request.
         
         Notice how the response codes are the same as list ride options? Use the same semantics as defined above.
         
         You must return a non-nil ride status with a valid ride option and ride option name, otherwise there will be an error on the Maps side.
         
         Most likely you will want the ride phase to be .received at this point. An .unknown ride phase here will be an error.
         
         IMPORTANT: Include as much information as possible on the ride status including the ride option, and estimated dates. A missing or blank ride option name will cause an error.
         
         The ride identifier will be consistent across this particular ride session.
         
         You must set the userActivityForCancelingInApplication to allow canceling of your ride. When a user selects cancel from inside Maps, this activity will be continued in your parent app to complete the cancelation.
         
         Also, additionalActionActivities will show up as actions the user can take which require completion inside your parent app. You can use this for things like splitting the fare, sharing ETA, contacting customer support, etc.
         */
    }
}

