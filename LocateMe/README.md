LocateMe

================================================================================
ABSTRACT:

This demonstrates the two primary use cases for the Core Location Framework: getting the user's location and tracking changes to the user's location. Developers should read the class reference documentation for CLLocationManager, CLLocationManagerDelegate, and CLLocation for detailed information about the Core Location framework. In addition, the iPhone Application Programming Guide has a section under "Device Support", titled "Getting the User's Current Location", which discusses best practices for using this framework.

Important Considerations:

• Core Location does not guarantee that a measurement matching the desiredAccuracy will be delivered. Rather, a best effort is made, and may be constrained both by the capabilities of the device and the location and environment from which it is used. For example, a first generation iPod touch may only be able to provide location via WiFi triangulation, which in turn might give better than 100-meter accuracy. However, used in a location which lacks WiFi hotspots, no location at all could be acquired. Similarly, a GPS equiped device will often provide better than 10-meter accuracy, but not underground. Your code should be prepared to handle any of these possibilities. In particular, a timeout should be used to stop updating the location manager even if a measurement meeting the desired is not received. A reasonable timeout is around 30 seconds.

• Core Location caches location data, so it is typical that the first measurement the location manager's delegate receives is "stale". You should always check the timestamp on measurement objects to determine if they are likely to be out-of-date.

• When tracking changes to the user's location, the distanceFilter property can be used to filter out update messages from the location manager to it's delegate. However, such messages may still be delivered if more accurate measurements are acquired. Also, the distanceFilter does not impact the hardware's activity - i.e., there is no savings of power by setting a larger distanceFilter because the hardware continues to acquire measurements. This simply affects whether those measurements are passed on to the location manager's delegate. Power can only be saved by turning off the location manager.

What to Look For in this Project:

The most important location handling code is in the GetLocationViewController and TrackLocationViewController. "#pragma mark Location Manager Interactions" is used to demarcate the specific sections that create, configure, start, and stop the manager, and where its delegate methods are implemented.

This sample also makes use of “NSLocationWhenInUseUsageDescription” in its Info.plist together with CLLocationManager’s requestWhenInUseAuthorization method.

================================================================================
BUILD REQUIREMENTS:

iOS 8.0 SDK or later

================================================================================
RUNTIME REQUIREMENTS:

iOS 7.0 or later

================================================================================
PACKAGING LIST:

AppDelegate
The application delegate has a minimal role in this sample: in -applicationDidFinishLaunching: it adds the tab bar controller's view to the window. It also creates a CLLocationManager object to check the locationServicesEnabled property at launch time.

GetLocationViewController
Attempts to acquire a location measurement with a specific level of accuracy. A timeout is used to avoid wasting power in the case where a sufficiently accurate measurement cannot be acquired. Presents a SetupViewController instance so the user can configure the desired accuracy and timeout. Uses a LocationDetailViewController instance to drill down into details for a given location measurement.

TrackLocationViewController
Attempts to track the user location with a specific level of accuracy. A "distance filter" indicates the smallest change in location that triggers an update from the location manager to its delegate. Presents a SetupViewController instance so the user can configure the desired accuracy and distance filter. Uses a LocationDetailViewController instance to drill down into details for a given location measurement.

SetupViewController
Displayed by either a GetLocationViewController or a TrackLocationViewController, this view controller is presented modally and communicates back to the presenting controller using a simple delegate protocol. The protocol sends setupViewController:didFinishSetupWithInfo: to its delegate with a dictionary containing a desired accuracy and either a timeout or a distance filter value. A custom UIPickerView specifies the desired accuracy. A slider is shown for setting the timeout or distance filter. This view controller can be initialized using either of two nib files: GetLocationSetupView.xib or TrackLocationSetupView.xib. These nibs have nearly identical layouts, but differ in the labels and attributes for the slider.

LocationDetailViewController
Shows all of the properties of a CLLocation object in a table view. Uses the CLLocation (Strings) category to present the information as localized strings.

CLLocation (Strings)
This is an Objective C category on the CLLocation class that extends the class by adding some convenience methods for presenting localized string representations of various properties.

================================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 2.3
- Upgraded for the iOS 8 SDK, adopts current best practices for Objective-C (including use of properties, autosynthesis, and literals), now uses Storyboards and ARC (Automatic Reference Counting).

Version 2.2
- Updated for iOS 4.0.

Version 2.0 
- Complete rewrite to focus separately on two primary use cases - getting a single location and tracking location changes.

Version 1.1
- Updated for and tested with iPhone OS 2.0. First public release.
- Fixed date error.

Version 1.0
- First version.

================================================================================
Copyright (C) 2008-2014 Apple Inc. All rights reserved.