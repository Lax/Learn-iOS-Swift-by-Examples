# Photo Edit

This sample code shows how to implement a Photo Editing extension.

The extension allows the user to select a filter effect to apply to the photo or video selected in Photos (iOS or OS X) or Camera (iOS only). To use the sample extension, edit a photo or video using the Photos app, and tap the extension icon.

In both iOS and OS X, a PhotoEditingViewController class presents the extension's UI and, through the PHContentEditingController, responds to messages from Photos that define the photo editing process. Each platform's PhotoEditingViewController class forwards those messages to the ContentEditingController class, which provides the common functionality for processing photos, videos, and Live Photos on both platforms.

Note that the app in this sample only serves as a host for the extension -- it has no UI or functionality of its own.

## Setup Instructions

Run the Photo Edit app to install it. To enable the extension, edit a photo or video using the Photos app, tap the extension icon (three dots in a circle), tap More, and switch Photo Filter on.

## Requirements

### Build

Xcode 8.0 (iOS 10.0 / OS X 10.12 SDK)

### Runtime

iOS 9.1, OS X 10.11 or later

Copyright (C) 2016 Apple Inc. All rights reserved.
