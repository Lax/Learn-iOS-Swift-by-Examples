/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An object that implements the `INGetRideStatusIntentHandling` protocol to handle ridesharing tasks.
 */

import Intents

// The intents whose interactions you wish to handle must be declared in the extension's Info.plist.

class IntentHandler: INExtension, INGetRideStatusIntentHandling {
    
    // MARK: - INGetRideStatusIntentHandling
    
    /*
     There are two kinds of ride status updates:
     - One shot
     - Live observation
     
     For one shot updates, -handleGetRideStatus will be called. This can be called at any time.
     
     For live observation, -startSendingUpdates will be called and an observer object specified.
     
     NOTE: You are allowed only one current ride at a time.
     */
    
    func handle(getRideStatus intent: INGetRideStatusIntent, completion: @escaping (INGetRideStatusIntentResponse) -> Void) {
        
        /*
         The intent has no data on it since this method is only asking for a current ride's status.
         
         Query your service to see if there is a current ride in progress. If there is, return the intent response with the .success code and a valid, fully detailed rideStatus object.
         A missing or blank ride option name will cause an error.
         
         Again, the response codes are similar to list ride / request ride and follow the same semantics.
         
         Sending a ride status with a completed phase is valid here, but be sure to set the completionStatus.
         
         If a ride is in the completed state for outstandingPaymentAmount for example, keep sending that status.
         
         Maps will automatically start to ignore a completed state after a set interval.
         
         When the user goes to get another ride, however, you can either allow that, or ask them to complete the previous ride by specifying a response code of .failureRequiringAppLaunchPreviousRideNeedsCompletion.
         */
    }
    
    func startSendingUpdates(forGetRideStatus intent: INGetRideStatusIntent, to observer: INGetRideStatusIntentResponseObserver) {
        
        /*
         It is time for you to start sending updates to the observer. The best thing to do here is to set up a timer to ping your service or some sort of persistent connection to your service.
         
         NOTE: It is completely possible for -startSendingUpdates to be called, and your extension terminated before -stopSendingUpdates is called. In this case, if your extension is restarted, -startSendingUpdates may be called again if you specify in -getRideStatus that there is a current ride.
         
         Store the observer in an ivar and send it the -didUpdate message whenever you have updated information about the current ride.
         
         Maps recommends spacing updates 1-10 seconds apart. Maps will throttle updates as it sees fit.
         */
        
    }
    
    func stopSendingUpdates(forGetRideStatus intent: INGetRideStatusIntent) {
        
        /*
         Stop sending updates and nil out your reference to the observer. Probably stop your timer or close your connection to your service.
         */
        
    }
}

