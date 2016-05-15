# ShapeEdit

ShapeEdit is a simple iCloud Document app for iOS.

ShapeEdit demonstrates the best practices for building a modern document based app which integrates with the iCloud Drive APIs. You will see how to discover and list documents in the cloud with thumbnails to build great UIs for your users as well as read from your cloud documents with proper file coordination using UIDocument. In addition, you will learn how to open cloud documents in place from the iCloud Drive app.

## Version

1.2

## Requirements

### Build

Xcode 7.3, iOS 9.0 SDK

### Runtime

iOS 9.0

## About ShapeEdit

ShapeEdit is organized into two main parts, the DocumentBrowser and the DocumentEditor.

The DocumentBrowser manages a recents list and NSMetadataQuery in order to let users browse and select documents that they wish to edit. It uses a collection view controller to display previews of the document to the user with thumbnails for a pretty UI. The DocumentBrowser consists of:

1. The DocumentBrowserQuery manages the NSMetadataQuery for discovering documents. It is the primary data source for discovering all of our shape documents as well as notifying when they change so we can update the collection view for display. When updates happen to NSMetadataQuery, the DocumentBrowserQuery computes the animations since the last notification and submits the results to the DocumentBrowserQueryDelegate for display.

2. The DocumentBrowserModelObject which represents a single document in the DocumentBrowserQuery. This manages all the properties of a single NSMetadataItem from the NSMetadataQuery.

3. The RecentModelObjectsManager which manages a list of RecentModelObjects. It listens for notifications from each of the stored RecentModelObjects and notifies its delegate accordingly.

4. The RecentModelObject which manages a single recent displayed in the UI. It listens for FilePresenter notifications and notifies its delegate when things change and it needs to be reloaded.

5. The ThumbnailCache which manages a cache of thumbnails which we have already loaded for display in the collection view. It also manages a worker queue to delegate thumbnail loading to the background when cache misses happen to avoid hindering scrolling performance. It notifies its delegate on the main queue when thumbnails have been reloaded so that the cells can be reloaded to display the new thumbnails

6. The DocumentBrowserController which manages the UICollectionView displayed to the user. It creates UICollectionViewCells from data received from the DocumentBrowserQuery and RecentModelObjectsManager and displays them to the user in its collection view. It is the delegate of the DocumentBrowserQuery, the RecentModelObjectsManager, and the ThumbnailCache and updates the view as necessary when updates are received from the delegate callbacks. It also handles user interaction notifications when documents are selected / created and pushes to the DocumentEditor view for the user to begin editing.

The DocumentEditor presents and allows users to modify an individual document. Pay most attention to the ShapeDocument class here which inherits from UIDocument to save and load its state with proper file coordination. The DocumentEditor consists of:

1. The ShapeDocument which manages one shape document instance. It subclasses from UIDocument to deal with file coordination properly, whether it be reading from / writing to documents under file coordination, or being notified about other file coordination requests to that document and taking appropriate actions. Most of the heavy lifting is dealt with for us automatically by UIDocument.

2. The DocumentViewController + ShapeView which manage the display of the document to the user. These provide our simple interface for the user to make modifications to our documents and notifies the ShapeDocument when modifications have been made so it knows when it needs to flush its changes to disk.

Copyright (C) 2016 Apple Inc. All rights reserved.