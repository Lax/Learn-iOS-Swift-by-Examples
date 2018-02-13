# TopSongs

## Description

This sample shows you how to import data from XML into Core Data. The focus is on performance, as this operation can be an expensive one. The XML parsing approach is borrowed from the sample "XMLPerformance", which compares parsing with libxml's C API and parsing with NSXMLParser. This sample uses a modified version of the LibXMLParser class, renamed as iTunesRSSImporter. This is the primary class to look at for how data is parsed from XML and imported into Core Data.


## Discussion

### Multithreading:
Parsing data is an expensive task, and importing data into Core Data can be as well. In order to provide a good user experience, this kind of work should be done in the background. This can be achieved using one of several APIs, but NSOperation is the most straightforward and is the route chosen for this sample. Multithreading always introduces complexity into an application. On the iPhone, you should be extremely careful to ensure that UIKit view objects are only accessed on the main thread. Even something as simple as [UIApplication sharedApplication].networkActivityIndicatorVisible = YES can cause problems if invoked on secondary threads. To be safe, use NSObject's performSelectorOnMainThread:withObject:waitUntilDone: to forward messages to the main thread.

### Memoory Footprint:
Parsing and importing often result in the creation of large numbers of autoreleased objects. To control the memory footprint during these operations, you should create and drain additional autorelease pools at discrete intervals. 

### Core Data relationships:
Creating Core Data objects is fairly straightforward, and the Core Data Programming Guide has a very useful article "Efficiently Importing Data". Importing, however, becomes much more complex when relationships are involved. Part of the complexity arises from the need to retrieve objects based on some criteria without keeping all objects in memory. For example, in this application, there are Songs and Categories. Each Song has a to-one relationship with a Category; the inverse relationship is that each Category has multiple songs. The XML data presents songs with categories inline rather than as separate data. So, in the process of creating a Song object, it is necessary to associate that Song with a Category, based on the name of the Category. It's not known whether the Category already exists, so the first step is to perform a "fetch" in Core Data. If the fetch does not return an object, then a new Category is created. Finally, the relationship between the Song and the Category is established.

The problem with this pattern is that fetches are, relatively speaking, expensive. The cost is primarily a result of the need to interact with the underlying database, which often requires I/O. Doing repeated fetches in rapid succession - such as during data import - can be very inefficient. One way of avoiding the need to perform a fetch is to keep the objects you will need in memory, or at least keep their unique identifiers in memory, with a lookup table. Then you simply go to the lookup table, retrieve the ID associated with the key you are using (the Category name in this case) and then get the object associated with the ID. This works well, expecially in cases where the size of the lookup table is both small and known in advance. However, it has the potential to create a different kind of problem - low memory due to overconsumption by the table. 

The easiest way to avoid the memory problem for large or potentially large data sets is to use a simple caching mechanism. This builds upon the lookup table by setting a fixed size to the table. If an item is in the table (a cache "hit"), it is simply returned. If an item is not in the table (a cache "miss") then a fetch is performed to retrieve that item and it is place in the table. When the table becomes full, an item must be evicted in order for the current requested item to be cached. How you determine which item is evicted is known as the "replacement policy". There are many different algorithms for this purpose, the best known being "Least Recently Used" or LRU. That is the algorithm implemented in the cache for this example.


## Build Requirements

iOS SDK 9.0 or later


## Runtime Requirements

iOS 8.0 or later


## Packaging List

AppDelegate
Configures the Core Data persistence stack and starts the RSS importer.

iTunesRSSImporter
Downloads, parses, and imports the iTunes top songs RSS feed into Core Data.

CategoryCache
Simple LRU (least recently used) cache for Category objects to minimize fetching while controlling memory footprint.

SongsViewController
Lists all songs in a table view. Also allows sorting and grouping via bottom segmented control.

SongDetailsController
Displays details of a single song.

Song
NSManagedObject subclass for Song entity.

Category
NSManagedObject subclass for Category entity.


Copyright (C) 2010-2015 Apple Inc. All rights reserved.
