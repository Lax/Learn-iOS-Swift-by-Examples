# AudioUnitV3Example: Audio Unit Extension and Host Implementation

The Audio Unit Extensions API introduces a mechanism for developers to deliver Audio Units on both iOS and OS X using the same API and also provides a bridging mechanism for existing version 2 Audio Units and hosts allowing them to work with new version 3 Audio Units.

To learn more about App Extensions and version 3 Audio Unit extensions, see the "App Extension Programming Guide" and the WWDC 2015 presentation ["Audio Unit Extensions"](https://developer.apple.com/videos/play/wwdc2015/508/).

This sample demonstrates how to build two example Audio Unit extensions, their containing apps, and a host app which uses the version 3 Audio Unit APIs for iOS and OSX.

## Overview

The targets in this sample are all prefixed by their respective platform designation, "iOS" or "OSX":

- FilterDemoApp, FilterDemoAppExtension — Effect Audio Unit
- InstrumentDemoApp, InstrumentDemoAppExtension — Instrument Audio Unit
- AUv3Host — Audio Unit Host

Also included are some reusable utility classes for managing audio formats, buffers, and scheduled parameters.

Note: For each audio unit, a shared framework is used and linked into both the containing app and the extension so that both can use the Audio Unit and its view controller. This architecture allows for maximum code reuse and easier debugging. The frameworks are called FilterDemoFramework and InstrumentDemoFramework prefixed by their respective platform designation, "iOS" or "OSX".

## Getting Started

Configure Signing for each target as required before working with this sample.

## AudioUnitv3Example Folder Hierarchy

AudioUnitv3.xcworkspace is the main workspace containing the Filter project, Instrument project and AUv3Host project.

The AUv3Host folder includes the main audio unit host project called AUv3Host.xcodeproj along with the iOS and OSX folders containing the individual implementation files and resources for each platform.

The Filter folder includes the main project file for the effect audio unit called Filter.xcodeproj. This folder also includes the iOS, OSX and Shared folders containing the individual implementation files and resources for building the extension, containing app, and framework. The Shared folder contains the `AUAudioUnit` subclass and kernel implementation which is shared across both platforms.

The Instrument folder includes the main project file for the instrument audio unit called Instrument.xcodeproj. This folder also includes the iOS, OSX and Shared folders containing the individual implementation files and resources for building the extension, containing app and framework. The Shared folder contains the `AUAudioUnit` subclass and kernel implementation which is shared across both platforms.

The top level Shared folder includes reusable utility classes for managing audio formats, buffers and scheduled parameters along with the SimplePlayEngine used for playback in the host apps and containing apps.

### FilterDemo

An effect version 3 Audio Unit packaged as an app extension, embedded in an application. The app packages shared code in a framework which is also embedded in the extension so that both the app and the extension can use the Audio Unit and its view controller.

The container app registers the Audio Unit dynamically so it can load it in-process for faster iteration during development. The SimplePlayEngine implementation is used to play audio through the audio unit.

This Audio Unit publishes a Filter effect.

### InstrumentDemo

An instrument version 3 Audio Unit packaged as an app extension, embedded in an application. The app packages shared code in a framework which is also embedded in the extension, so that both the app and the extension can use the Audio Unit and its view controller.

The container app registers the Audio Unit dynamically so it can load it in-process for faster iteration during development. The SimplePlayEngine implementation is used to play audio through the audio unit.

This Audio Unit publishes an instrument based on a simple sine-wave.

### AUv3Host

Simple Audio Unit host application that lets the user select an Audio Unit and supports opening an Audio Unit's custom view. The implementation uses the shared SimplePlayEngine source to play audio through a selected Audio Unit.

### SimplePlayEngine

Illustrates the use of `AVAudioUnitComponentManager`, `AVAudioEngine`, `AVAudioUnit`, and `AUAudioUnit` to play an audio file through a selected Audio Unit effect. This implementation file is shared amongst the host app and both audio unit container apps.

## Requirements

### Build

- Xcode 8.2 or greater.
- iOS 11 SDK.
- macOS 10.13 SDK.

### Runtime

- iOS 11 or greater
- macOS 10.13 or greater
