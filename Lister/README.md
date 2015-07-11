# Lister

## Version

2.0

## Build Requirements
+ Xcode 6.3 or later
+ iOS 8.2 SDK or later
+ OS X 10.10 SDK or later
+ iCloud–enabled provisioning profile
+ App Groups–enabled provisioning profile

## Runtime Requirements
+ iOS 8.0 or later (iOS 8.2 or later required for Apple Watch)
+ OS X 10.10 or later

## About Lister

Lister is a productivity app for iOS and OS X that enables you to create and share to-do lists across your iPhone, iPad, Apple Watch, and Mac.

Lister demonstrates how to:

+ Create an Apple Watch app to complement your iPhone app.
+ Use iCloud Document Storage to share content between multiple app targets and
platforms.
+ Use App Groups to share local content between apps and extensions
on a single device.
+ Create App Extensions to provide Today Widgets and Watch Apps.
+ Define a framework to share common code between multiple targets.

The Lister Xcode project is provided in both Swift and Objective-C.

Because Lister supports iCloud Documents and App Groups, the Lister Xcode project requires a small amount of setup before it can be built and run. It also requires a paid iOS and / or Mac Developer Program account.

+ If you have an iOS Developer Program account, follow the instructions in *iOS and Watch Quick Start*.
+ If you have a Mac Developer Program account, follow the instructions in *Mac Quick Start*.

## Written in Objective-C and Swift

This sample is provided in both Objective-C and Swift. Both versions of the sample are at the top level directory of this project in folders named "Objective-C" and "Swift". Both versions of the application have the exact same visual appearance; however, the code and structure may be different depending on the choice of language.

Note: The "List" class in Swift is conceptually equivalent to the "AAPLList" class in Objective C. The same applies to other classes mentioned in this README. This documentation refers to class names for both languages without the "AAPL" prefix, for brevity.

## Application Architecture

The Lister project includes iOS and OS X app targets, iOS and OS X app extensions, and frameworks containing shared code.

### OS X

Lister for OS X is a document-based application with a single window per document. To organize the implementation of the app, Lister takes a modular design approach. Three main controllers are each responsible for different portions of the user interface and document interaction: ListWindowController manages a single window and owns the document associated with the window. The window controller also implements interactions with the window’s toolbar such as sharing. The window controller is also responsible for presenting an AddItemViewController object that allows the user to quickly add an item to the list. The ListViewController class is responsible for displaying each item in a table view in the window.

Lister's design and controller interactions are implemented in a Mac Storyboard. A storyboard makes it easy to visualize the relationships between view controllers and to lay out the user interface of the app. Lister also takes advantage of Auto Layout to fluidly resize the interface as the user resizes the window. If you're opening the project for the first time, the Storyboard.storyboard file is a good place to understand how the app works.

Although much of the view layer is implemented with built–in AppKit views and controls, there are several interesting custom views in Lister. The ColorPaletteView class is an interface to select a list's color. When the user shows or hides the color palette, the view dynamically animates the constraints defined in Interface Builder. The ListTableView and TableRowView classes are responsible for displaying list items in the table view.

Document storage in Lister is implemented in the ListDocument class, a subclass of NSDocument. Documents are stored as keyed archives. ListDocument reuses much of the same model code shared between the OS X and iOS apps. Additionally, the ListDocument class enables Auto Save and Versions, undo management, and more. With the ListFormatting class, the user can copy and paste items between Lister and other apps, and even share items.

The Lister app manages a Today list that it stores in iCloud document storage. The TodayListManager class is responsible for creating, locating, and retrieving the today ListDocument object from the user's iCloud container. Open the Today list with the Command-T key combination.

### iOS

The iOS version of Lister follows many of the same design principles as the OS X version—the two versions share common code. The iOS version also follows the Model-View-Controller (MVC) design pattern and uses modern app development practices including Storyboards and Auto Layout. In the iOS version of Lister, the user manages multiple lists using a table view implemented in the ListDocumentsViewController class.

A user can store their documents both locally or in iCloud. To abstract the storage mechanism away from the type of storage (iCloud or local), Lister uses a ListsController class that notifies the ListDocumentsViewController about new lists, lists that have been removed, and also lists that have been updated. The ListsController has an ListCoordinator property which is responsible for tracking the relevant URLs. In Lister, there are two types of ListCoordinator objects: the CloudListCoordinator object as well as the LocalListCoordinator object. The only place that these objects are used directly is within the ListsController. The storage mechanism is determined by the AppDelegate, which asks the user what their storage preference is. Once their preference is known, the app delegate creates an ListCoordinator and passes it to the app delegate's ListsController property. The app delegate passes the ListsController object throughout the application to ensure that it's used as the single place to manage lists.

Once the list of documents is visible, a user can tap on a list to show the ListViewController. This class displays and manages a single document. If a user wants to create a new list, they can tap on the "+" to display an instance of the NewListDocumentController. Lists are represented with the ListDocument class, a subclass of UIDocument, which is responsible for serialization and deserialization of a list. Rather than directly manage List objects, the ListDocumentsViewController class manages an array of ListInfo objects. The ListInfo class caches properties that are required, like the list's color, for display.

Note: Lister leverages the document picker on iOS. This requires that code signing, entitlements, and provisioning for the project have been configured before you run Lister. If you run the app without configuring entitlements correctly and create a new document via the "+" button, an exception will be raised about a missing iCloud entitlement.

### Shared Code

Much of the model layer code for Lister is used throughout the entire project, across the iOS and OS X platforms. List and ListItem are the two main model objects. The ListItem class represents a single item in a list. It contains only three stored properties: the text of the item, a boolean value indicating whether the user has completed it, and a unique identifier. Along with these properties, the ListItem class also implements the functionality required to compare, archive, and unarchive a ListItem object. The List class holds an array of these ListItem objects, as well as the desired list color. The List class also supports indexed subscripting, archiving, unarchiving, and equality.

Archiving and unarchiving are specifically designed and implemented so that model objects can be unarchived regardless of the language, Swift or Objective–C, or the platform, iOS or OS X, that they were archived on.

In addition to model code, by subclassing CALayer (a class shared by iOS and OS X), Lister shares check box drawing code with both platforms. The project includes a control class for each platform with user interface framework–specific code. These CheckBox classes use the designable and inspectable attributes so that the custom drawing code is viewable and adjustable live in Interface Builder.

### iOS and OS X Today Widget

Lister Today widgets are available on both iOS and OS X. Lister shares much of the same model, controller, and drawing code between the app extensions and apps by using a shared framework. This is also very valuable because it centralizes the core code into a single location. See the "Shared" Code section above for more info on the details of the code sharing. Both iOS and OS X implement a view controller subclass called TodayViewController; this can be found in the ListerToday target for iOS and ListerTodayOSX for OS X.

## Swift Features

The Swift version of the Lister sample makes use of many features unique to Swift, including:

#### Nested types

The List.Color enumeration represents a list's associated color.

#### String Constants

Constants are defined using structs and static members to avoid keeping constants in the global namespace. One example is notification constants, which are typically defined as global string constants in Objective-C. Nested structures inside types allow for better organization of notifications in Swift.

#### Extensions on Types at Different Layers of a Project

The List.Color enum is defined in the List model object. It is extended in the UI layer (ListColorUI.swift) so that it can be easily converted into a platform-specific color object.

#### Subscripting

The List class provides access to its ListItem objects through indexed subscripting. The List object stores ListItem objects in an in-memory array.

#### Tuples

The List class is responsible for managing the order of its ListItem objects. When an item is moved from one row to another, the list returns a lightweight tuple that contains both the "from" and "to" indices. This tuple is used in a few different methods in the List class.

## Unit Tests

Lister has unit tests written for the List and ListItem classes. These tests are in the ListerKitTests group. The same tests can be run on an iOS or Mac target to ensure that the cross-platform code works as expected. To run the unit tests, select either the ListerKit (for iOS) or ListerKitOSX (for OS X) scheme in the Scheme menu. Then hold the Run button down and select the "Test" option, or press Command-U to run the tests.

## Release Notes

Lister does not currently support configuring a storage option before the iOS app is launched. Please launch the iOS app first. In your own projects, you should provide for the watch app being run prior to the iOS app that hosts it.

Copyright (C) 2014-2015 Apple Inc. All rights reserved.
