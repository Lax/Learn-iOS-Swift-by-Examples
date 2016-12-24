#RideMaps
##Overview
 
The ridesharing domain consists of 3 individual intent handling protocols that you must conform to:
1. `INListRideOptionsIntentHandling`
2. `INRequestRideIntentHandling`
3. `INGetRideStatusIntentHandling`
 
Each of the handling protocols can have resolve..., confirm..., and handle... methods. For the Maps context, we never need to implement the resolve... methods, and only need to implement the confirm method for `INRequestRideIntentHandling`.
 
In this project, each protocol in the domain has been separated into its own extension. This way you can isolate your code for each protocol in different processes.
 
This project includes copious comments to help you implement the ridesharing domain for intents. It does not include implementation, but will have hints about where to perform certain implementation tasks.
 
*The intents you wish to handle in an extension must be declared in the extension's Info.plist.*
