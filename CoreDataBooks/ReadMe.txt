CoreDataBooks
=============

This sample illustrates a number of aspects of working with the Core Data framework with an iPhone application:

* Use of an instance of NSFetchedResultsController object to manage a collection of objects to be displayed in a table view.
* Use of a child managed object context to isolate changes during an add operation.
* Undo and redo. 
* Database initialization.

This sample assumes some familiarity with the Core Data framework, and with UIKit view controllers and table views. As a minimum, you should have worked through the "Core Data Tutorial for iOS" tutorial.


Build Requirements
------------------------------
iOS 7.0 SDK or later


Runtime Requirements
------------------------------
iOS 6.0 or later


Running the Sample
------------------
The sample presents a simple master-detail interface. The master is a list of book titles. Selecting a title navigates to the detail view for that book. The master has a navigation bar (at the top) with a "+" button on the right for creating a new book. This creates the new book and then navigates immediately to the detail view for that book. There is also an "Edit" button. This displays a "-" button next to each book. Touching the minus button shows a "Delete" button which will delete the book from the list. 

The detail view displays three fields: title, copyright date, and author. The user can navigate back to the main list by touching the "Books" button in the navigation bar. If the user taps Edit, they can modify individual fields. Until they tap Save, they can also undo up to three previous changes.


Packaging List
--------------

CoreDataBooksAppDelegate.{h,m}
Configures the Core Data stack and the first view controllers.

RootViewController.{h,m}
Manages a table view for listing all books. Provides controls for adding and removing books.

DetailViewController.{h,m}
Manages a detail display for display fields of a single Book. 

AddViewController.{h,m}
Subclass of DetailViewController with functionality for managing new Book objects.

EditingViewController.{h,m}
View for editing a field of data -- either text or a date.

Book.{h,m}
A simple managed object class to represent a book.

CoreDataBooks.sqlite
A pre-populated database file that is copied into the appropriate location when the application is first launched.

CoreDataBooks.xcdatamodel
The Core Data managed object model for the application.


Changes from Previous Versions
------------------------------
1.5 - Fixed NSUndoManager allocation bug.

1.4 - Upgraded to support iOS 6.0 SDK, added missing CFBundleIdentifier, minor code reformatting, now using NSCurrentLocaleDidChangeNotification to detect locale changes for dates.

1.3 - Updated to use ARC and storyboard, uses a child managed object context instead of a peer context.

1.2 - Added CFBundleIconFiles in Info.plist.

1.1 - Upgraded project to build with the iOS 4.0 SDK. updated to use NSFetchedResultsController's controllerWillChangeContent: delegate method, and an update to UITableView's change-handling, to allow for more fluid updates. Corrected a memory leak in EditingViewController.

1.0 - First release.

===========================================================================
Copyright (C) 2009-2014 Apple Inc. All rights reserved.
