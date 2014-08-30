# UICatalog: Creating and Customizing UIKit Controls (Obj-C and Swift)

This sample demonstrates how to use many views and controls in the UIKit framework along with their assorted functionalities. Refer to this sample if you are looking for specific controls or views that are provided by the system.

Note that this sample also shows you how to make your non-standard views (images or custom views) accessible. Using the iOS Accessibility API enhances the user experience of VoiceOver users.

You will also notice this sample shows how to localize string content by using the NSLocalizedString function. Each language has a "Localizeable.strings" file and this function refers to this file when loading the strings from the default bundle.

## Written in Objective-C and Swift

This sample is written in both Objective-C and Swift. Both versions of the sample are at the top level directory of this project in folders named "Objective-C" and "Swift". Both versions of the application have the exact same visual appearance; however, the code and structure may be different depending on the choice of language.

## Using the Sample

This sample can be run on a device or on the simulator.

While looking over the source code of UICatalog you will find that many elements keep the same order of the view controller classes listed in the project. For example, the activity indicator view controller is the first view controller in the UICatalog project folder, but it is also the first view controller that's shown in the primary view controller's table view.

UICatalog uses a split view controller based application architecture, which can be seen in the storyboard files. The primary view controller defines the list of views that are used for demonstration in this application. Each secondary view controller corresponds to a given system-provided control (and is named accordingly). For example, the alert controller view controller shows how to use UIAlertController and its associated functionality. The only two exceptions to this rule are UISearchBar / UISearchController and UIToolbar; these APIs have multiple view controllers to explain how the control works and can be customized.

## UIKit Controls That Are Covered

UICatalog demonstrates how to configure and customize the following controls / controllers:

+ UIActivityIndicatorView
+ UIAlertController
+ UIButton
+ UIDatePicker
+ UIImageView
+ UIPageControl
+ UIPickerView
+ UIProgressView
+ UISegmentedControl
+ UISlider
+ UIStepper
+ UISwitch
+ UITextField
+ UITextView
+ UIWebView
+ UISearchBar
+ UISearchController
+ UIToolbar

## Build

Building this sample requires Xcode 6.0 and iOS 8.0 SDK

## Runtime

Running the sample requires iOS 8.0 or later.

Copyright (C) 2014 Apple Inc. All rights reserved.
