# AVReaderWriter

## Description

AVReaderWriter demonstrates how to use AVAssetReader to read and decode sample data from a movie file, work directly with the sample data, then use AVAssetWriter to encode and write the sample data to a new movie file.

There are two versions: One is written in Objective-C and runs on OS X, the other is written in Swift and runs on iOS.  Despite differing in the area of user interface management, both versions demonstrate the same basic concepts involved in working with raw media data.  The execution of these concepts is concentrated in CyanifyOperation.swift (Swift/iOS version) and AAPLDocument.m (Objective-C/OS X version).

## Build Requirements

Xcode 8.0, macOS 10.12 SDK, iOS 10.0 SDK

## Runtime Requirements

OS X 10.11, iOS 9.0

# Structure

Objective-C Version:
	Source files: AAPLDocument.h/m, AAPLProgressPanelController.h/m, main.m
	Project bundle: AVReaderWriter.xcodeproj, AVReaderWriterOSX-Info.plist, InfoPlist.strings
	User interface files: AAPLProgressPanel.xib, MainMenu.xib, AAPLDocument.xib
	User interface resources: AudioOnly2x.png, ErrorLoading2x.png

Swift Version:
	Main source file: CyanifyOperation.swift
	User interface source files: ProgressViewController.swift, ResultViewController.swift, StartViewController.swift, AppDelegate.swift
	Project bundle: AVReaderWriter.xcodeproj, Info.plist
	User interface files: LaunchScreen.storyboard, Main.storyboard, Assets.xcassets
	Resources: ElephantSeals.mov

## Changes

Version 1.0
- First version.

Version 2.0
- Add Swift version.

Version 3.1
- Update for Swift 2.3

Copyright (C) 2016 Apple Inc. All rights reserved.
