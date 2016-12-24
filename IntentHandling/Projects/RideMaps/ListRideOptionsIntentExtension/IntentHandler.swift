/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An object that implements the `INListRideOptionsIntentHandling` protocol to handle ridesharing tasks.
 */

import Intents

// The intents whose interactions you wish to handle must be declared in the extension's Info.plist.

class IntentHandler: INExtension, INListRideOptionsIntentHandling {
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
    // MARK: - INListRideOptionsIntentHandling
    
    // For list ride options, we don't need to implement -confirmListRideOptions since it isn't used in the Maps context.
    
    func handle(listRideOptions intent: INListRideOptionsIntent, completion: @escaping (INListRideOptionsIntentResponse) -> Void) {
        
        /*
         We need to do the following here:
         
         1. Get the pickup and dropoff locations from the intent.
         2. Send these locations to your service.
         3. Get back a list of different ride options your service provides between these two points.
         4. Create an intent response with an appropriate response code and data.
         
         */
        
        /*
         Some helpful tips on INListRideOptionsIntentResponseCodes:
         
         - case unspecified
            - Don't use this, it is considered a failure.
         - case ready
            - Don't use this, it is considered a failure.
         - case inProgress
            - Don't use this, it is considered a failure.
         - case success
            - Use this for when there are valid ride options you wish to display.
         - case failure
            - Use this when there is a failure.
         - case failureRequiringAppLaunch
            - Use this when there is a failure which can be recovered from, but only by switching to your parent app.
         - case failureRequiringAppLaunchMustVerifyCredentials
            - Use this when a user is not logged in or signed up for your service in your parent app.
         - case failureRequiringAppLaunchNoServiceInArea
            - Use this when you definitively don't offer service in the general area the user requested ride options in.
         - case failureRequiringAppLaunchServiceTemporarilyUnavailable
            - Use this when you temporarily don't offer service in the general area, for example if there are no vehicles available.
         - case failureRequiringAppLaunchPreviousRideNeedsCompletion
            - Use this when there was a previous ride in your service that the user needs to complete in your parent app. For example if the user still needs to pay for the previous ride. If there is a previous ride that needs completion, but you would still like to allow the user to book another ride, return .success.
         
         For the cases requiringAppLaunch, make sure to include a relevant user activity. This activity will be continued in your parent app if the user chooses to take action on the failure message in Maps. See NSUserActivity documentation here: https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSUserActivity_Class/ .
         
         */
        let response = INListRideOptionsIntentResponse(code: .success, userActivity: nil)
        
        
        /* 
         Ride options
         
         Specify a ride option with the INRideOption class. You will have a chance to update the ride option object after a user books a ride, during the ride, and at the end of a ride.
         
         IMPORTANT: When you get a HandleRequestRideIntent below, you will not be handed back the whole ride option. Instead you will be give the following data:
         - pickup location (CLPlacemark)
         - dropoff location (CLPlacemark)
         - ride option name (INSpeakableString)
         - party size (nil if you provided none)
         - payment method (INPaymentMethod)
         
         Therefore, you *must* make the ride option name unique so you can match the listed option with the requested option.
         
         */
        let smallCarOption = INRideOption(name: "Small Car", estimatedPickupDate: Date(timeIntervalSinceNow: 3 * 60)) // You must provide a name and estimated pickup date.
        
        smallCarOption.priceRange = INPriceRange(firstPrice: NSDecimalNumber(string: "5.60") , secondPrice: NSDecimalNumber(string: "10.78"), currencyCode: "USD") // There are different ways to define a price range and depending on which initializer you use, Maps may change the formatting of the price.
        
        smallCarOption.disclaimerMessage = "This is a very small car, tall passengers may not fit." // A message that is specific to this ride option.
        
        /*
         Party size options
         
         If you offer different prices for different party sizes for this option, you may use this property to enumerate them. If you do not, leave this nil.
         
         You may have different price ranges for each party size option. If you leave the price range for the party size option nil, it will default to the ride option's price range.
         
         The size description is user visible text.
        */
        smallCarOption.availablePartySizeOptions =  [
                                                        INRidePartySizeOption(partySizeRange: NSRange(location: 0, length: 1), sizeDescription: "One person", priceRange: nil),
                                                        INRidePartySizeOption(partySizeRange: NSRange(location: 0, length: 2), sizeDescription: "Two people", priceRange: INPriceRange(firstPrice: NSDecimalNumber(string: "6.60") , secondPrice: NSDecimalNumber(string: "11.78"), currencyCode: "USD"))
                                                    ]
        smallCarOption.availablePartySizeOptionsSelectionPrompt = "Choose a party size"
        
        /*
         Special pricing
         
         The special pricing string is a user facing string that describes details about the special pricing.
         
         The badge image is shown beside the string as a visual indicator of the special pricing.
         
         Setting either of these properties will result in Maps alerting the user that there is special pricing in effect.
         
         */
        smallCarOption.specialPricing = "High demand. 50% extra will be added to your fare."
        smallCarOption.specialPricingBadgeImage = INImage(named: "specialPricingBadge")
        
        /*
         Fare line items
         
         These help the user understand the breakdown of the fare for the ride option. You'll have a chance to give updated fare line items after a user books a ride, during the ride, and at the end of the ride.
         */
        let base = INRideFareLineItem(title: "Base fare", price: NSDecimalNumber(string: "4.76"), currencyCode: "USD" )!
        let airport = INRideFareLineItem(title: "Airport fee", price: NSDecimalNumber(string: "3.00"), currencyCode: "USD" )!
        let discount = INRideFareLineItem(title: "Promo code (3fs8sdx)", price: NSDecimalNumber(string: "-4.00"), currencyCode: "USD" )!
        smallCarOption.fareLineItems = [ base, airport, discount ]
        
        /*
         User activity for booking in application
         
         ONLY set this if this particular ride option is not able to be booked outside of your parent application. For example if the Intents API does not support a particular feature of the ride option.
         
         This will cause Maps to continue the activity in the parent app rather than booking the whole ride inside Maps.
         */
        smallCarOption.userActivityForBookingInApplication = NSUserActivity(activityType: "bookInApp");
        
        response.rideOptions = [ smallCarOption ]
        
        /*
         Payment methods
         
         Specify the payment methods that a user has registered with your service. You will be handed back the selected payment method in -handleRequestRideIntent:completion:.
         */
        let paymentMethod = INPaymentMethod(type: .credit, name: "Visa Platinum", identificationHint: "•••• •••• •••• 1234", icon: INImage(named: "creditCardImage"))
        let applePay = INPaymentMethod.applePay()  // If you support Pay and the user has an Pay payment method set in your parent app
        response.paymentMethods = [ paymentMethod, applePay ]
        
        
        /*
         Expiration date
         
         The date at which these ride options expire. When this date is reached, Maps may call -handleListRideOptions:completion: again.
         */
        response.expirationDate = Date(timeIntervalSinceNow: 5 * 60)
    }
}

