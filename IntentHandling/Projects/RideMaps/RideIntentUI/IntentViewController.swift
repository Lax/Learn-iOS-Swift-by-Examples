/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An object that implements the `INRidesharingDomainHandling` protocols to handle ridesharing tasks.
 */

import IntentsUI

// The intents whose interactions you wish to handle must be declared in the extension's Info.plist.

class IntentViewController: UIViewController, INUIHostedViewControlling {
    
    // MARK: - INUIHostedViewControlling
    
    // Prepare your view controller for the interaction to handle.
    func configure(with interaction: INInteraction!, context: INUIHostedViewContext, completion: ((CGSize) -> Void)!) {
        
        /*
         -configure can be called at any time. Most likely it could be called each time you send an update in get ride status live observation.
         
         Your non-ui extension and ui extension run in separate processes, so it is up to you how to synchronize data between the two. 
         
         It is recommended that you configure the view controller based only on the information in the interaction object to minimize data mismatch between the two extensions.
         
         The interaction object contains both an intent and response. Use the information on both of these objects to correctly configure the view controller.
         
         IMPORTANT: Any arbitrary data can be stored in the response's user activity's user info dictionary when you send a get ride status response back to Maps. It will be handed back to you here.
         
         The context will let you know whether this view controller will be shown inside Maps or Siri. If it is shown inside Maps, it is not necessary nor recommended to show an MKMapView.
         */
        
        if let completion = completion {
            completion(self.desiredSize)
        }
    }
    
    var desiredSize: CGSize {
        // NOTE: Maps does not respect desired size.
        return self.extensionContext!.hostedViewMaximumAllowedSize
    }
    
}
