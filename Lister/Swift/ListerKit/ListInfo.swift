/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The `ListInfo` class is a caching abstraction over a `List` object that contains information about lists (e.g. color and name).
            
*/

import UIKit

public class ListInfo: NSObject {
    // MARK: Properties

    public let URL: NSURL
    
    public var color: List.Color?

    public var name: String {
        let displayName = NSFileManager.defaultManager().displayNameAtPath(URL.path!)

        return displayName.stringByDeletingPathExtension
    }

    private let fetchQueue = dispatch_queue_create("com.example.apple-samplecode.listinfo", DISPATCH_QUEUE_SERIAL)

    // MARK: Initializers

    public init(URL: NSURL) {
        self.URL = URL
    }

    // MARK: Fetch Methods

    public func fetchInfoWithCompletionHandler(completionHandler: Void -> Void) {
        dispatch_async(fetchQueue) {
            // If the color hasn't been set yet, the info hasn't been fetched.
            if self.color != nil {
                completionHandler()
                
                return
            }
            
            ListUtilities.readListAtURL(self.URL) { list, error in
                dispatch_async(self.fetchQueue) {
                    if let list = list {
                        self.color = list.color
                    }
                    else {
                        self.color = .Gray
                    }
                    
                    completionHandler()
                }
            }
        }
    }
    
    // MARK: NSObject
    
    override public func isEqual(object: AnyObject?) -> Bool {
        if let listInfo = object as? ListInfo {
            return listInfo.URL == URL
        }

        return false
    }
}
