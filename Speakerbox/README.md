# Speakerbox: Using CallKit to create a VoIP app

This sample app demonstrates how to use CallKit.framework in a VoIP app to allow it to integrate natively into the system.

## Requirements

### Build

Xcode 8.0 or later; iOS 10.0 SDK or later

### Runtime

iOS 10.0 or later

## About Speakerbox

Speakerbox is an example VoIP app which uses CallKit.framework to make and receive calls. It demonstrates several key areas:

- Creating a CXProvider and setting its delegate, in order to perform call actions in response to delegate callbacks. For example, the app's ProviderDelegate implements `-provider:performAnswerCallAction:` to handle answering an incoming call.
- Calling CXProvider API to provide updates to call metadata (using the CXCallUpdate class) and call lifecycle (using the various `report…` methods). For example, the app calls `CXProvider.reportOutgoingCall(with:connectedAtDate:)` to notify the system when an outgoing call has connected.
- Creating a CXCallController in order to request transactions in response to user interactions in the app. For example, to start an outgoing call, the app calls `CXCallController.request(_:)` to request a CXTransaction containing a CXStartCallAction.
- Registering an app's CXProviderConfiguration, in order to configure certain behaviors of the app. For example, the app sets `maximumCallsPerCallGroup` to 1 to indicate that calls may not be grouped together.
- Handling call audio, including the correct points to configure the app's AVAudioSession versus starting call audio media. See `configureAudioSession()`, `startAudio()`, and `stopAudio()`.
- Starting an outgoing call in response to an INStartAudioCallIntent, including introspecting the INInteraction and NSUserActivity which contain the intent.

Copyright (C) 2016 Apple Inc. All rights reserved.
