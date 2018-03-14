# MPRemoteCommandSample (for iOS, tvOS and macOS)

## Requirements

### Build

* Xcode 8.1 or later
* iOS 10.0 SDK or later
* tvOS 10.0 SDK or later
* macOS 10.12 SDK or later
* Swift 3.0

### Runtime

* iOS 10.0 or later
* tvOS 10.0  or later
* macOS 10.12.1 or later

## About MPRemoteCommandSample

This sample demonstrates how to leverage the `MPRemoteCommandCenter` and `MPNowPlayingInfoCenter` APIs to add support for remote control events.  Using `MPRemoteCommandCenter` for remote control events provides the following benefits:

- The ability to support Media events not previously available with the `UIApplication.beginReceivingRemoteControlEvents()` API such as skipping forward and backward a specified number of seconds.
- The ability to support displaying media controls on the Touch Bar with supported hardware on macOS.
- Finer control of what controls shows up on the Lock Screen, Control Center and CarPlay when your application is playing audio on iOS. 
- The ability to support playback commands via Siri on macOS, iOS, watchOS, and tvOS.
- The ability for media applications to support the automatic pause and play functionality with the AirPods when taking them in and out of the ear.

## Targets

### MPRemoteCommandSample

MPRemoteCommandSample for iOS is a `UITabBarController` based application that provides a list of assets to play and the ability to configure which `MPRemoteCommand` to enable or disable while the app is running.

The main classes that the MPRemoteCommandSample target uses are the following:

__AssetListTableViewController.swift__

- `AssetListTableViewController` is a `UITableViewController` subclass that provides a list of all the m4a files that are in the application's bundle.  Playback of a given `Asset` can be triggered by tapping on the `UITableViewCell` associated with the `Asset`.

__RemoteCommandListTableViewController.swift__

- `RemoteCommandListTableViewController` is a `UITableViewController` subclass that provides a list of all the supported `MPRemoteCommand` that are available on `MPRemoteCommandCenter` to enable or disable.  It has its own `UITableViewCell` subclass called `RemoteCommandListTableViewCell` which has a `UISwitch` to toggle the corresponding `MPRemoteCommand` as enabled or disabled in the `RemoteCommandManager` while the application is running.    

### MPRemoteCommandSample-TV

MPRemoteCommandSample-TV is a tvOS single view based application that plays a HTTP Live Stream using `AVPlayerLayer`.  The purpose of this sample is to demonstrate how to add support for Siri playback commands including the "What did they just say?" feature.  

The main classes that the MPRemoteCommandSample-TV target uses are the following:

__InitialViewController.swift__

- `InitialViewController` is the initial `UIViewController` that prepares an HLS asset for playback in a `PlayerViewController`.

__PlayerView.swift__

- `PlayerView` is a subclass of `UIView` with a layerClass of `AVPlayerLayer`.

__PlayerViewController.swift__

- `PlayerViewController` is a subclass of `UIViewController` with a `PlayerView` as its `view` and is used to play the HLS asset.

### MPRemoteCommandSample-macOS

MPRemoteCommandSample-macOS is a single window Cocoa application that provides a list of assets to play and the ability to configure which `MPRemoteCommand` to enable or disable while the app is running.

The main classes that the MPRemoteCommandSample-macOS target uses are the following:

__AssetPlaybackViewController.swift__

- `AssetPlaybackViewController` is a `NSViewController` subclass that lists all the m4a files in the applications bundle that can be played back in the application as well as provides basic metadata about the currently playing `Asset`.  Playback of a given `Asset` can be triggered by selecting the row associated with the `Asset`.

__RemoteCommandConfigurationViewController.swift__

- `RemoteCommandConfigurationViewController` is an `NSViewController` subclass that contains a view based `NSTableView` that lists all the supported `MPRemoteCommand`s that are available to enable/disable.  The `NSTableView` displays its own `NSView` subclass called `RemoteCommandView` which has a check box `NSButton` to toggle the corresponding MPRemoteCommand as enabled or disabled in the RemoteCommandManager while the application is running.

__WindowController.swift__

- `WindowController` is an `NSWindowController` subclass that contains an `NSToolbar` with toolbar items for controlling playback of the currently playing `Asset` if any.   

### Main Files 

All of the targets use the following classes:

__Asset.swift__

- `Asset` is a Swift struct that acts as a wrapper around an `AVURLAsset` and a `String` representing the name of the `Asset`.

__AssetPlaybackManager.swift__

- `AssetPlaybackManager` is the class that manages the playback of Assets in this sample using Key-value observing on various AVFoundation classes.  This class does the following:
    - Manages updating the information displaying in `MPNowPlayingInfoCenter` based on certain playback events.
    - Provides the necessary hooks for `RemoteCommandManager` to call when receiving a `MPRemoteCommandEvent`.

__RemoteCommandManager.swift__

- `RemoteCommandManager` is the class that manages configuring the various `MPRemoteCommand` events that `MPRemoteCommandCenter` provides.  This class does the following:
    - Adding and removing the command handlers when enabling and disabling a `MPRemoteCommand` respectively.
    - Responding to various `MPRemoteCommandEvent` calls and calling the appropriate `AssetPlaybackManager` playback method.

## Important Notes

### Deciding whether to use `MPRemoteCommandCenter` or `UIApplication.beginReceivingRemoteControlEvents()`

In iOS 7.1 and later you should only use the `MPRemoteCommandCenter` APIs to register for remote control events.  When using `MPRemoteCommandCenter` you do not need to call `UIApplication.beginReceivingRemoteControlEvents()`.

### Customizing what controls appear on the Lock Screen and in Control Center

Using the `MPRemoteCommand` objects vended by `MPRemoteCommandCenter`, you can customize what controls show up on the Lock Screen and Control Center.  Depending on the type of application you have, you may want to support certain commands via Siri but have a subset of those commands display on the Lock Screen and Control Center.  To control what commands display on both the Lock Screen and Control Center you should set the `isEnabled` to `true` if you want it to display and `false` if you wish to hide it.  Setting `isEnabled` to `false` will still allow the `MPRemoteCommandEvent` to be accessible via Siri while allowing you to customize what displays on the Lock Screen and in Control Center.  

### Supporting the "What did they just say?" Siri command on tvOS

If your tvOS application is using `AVPlayerViewController` then you will automatically get this functionality for free.  Using `AVPlayerViewController` will for playback will handle updating `MPNowPlayingInfoCenter` and registering for remote control events.  However, if you are managing your own asset playback using `AVPlayerLayer` then you will need to register for the `skipBackwardCommand` in `MPRemoteCommandCenter`.

### How often to update the contents of `MPNowPlayingInfoCenter.nowPlayingInfo`

It is important to make sure that you only ever update the `MPNowPlayingInfoCenter.nowPlayingInfo` whenever absolutely necessary.  Typically the only time you should update `MPNowPlayingInfoCenter.nowPlayingInfo` is when a change in playback state occurs or if the playback position changes as a result of user action.  Some examples of when to update the `MPNowPlayingInfoCenter.nowPlayingInfo` are:

- The now playing item changing.
- User pausing or resuming playback.
- The playback rate of the player changing. 
- The playback position changing.

Copyright (C) 2016 Apple Inc. All rights reserved.
