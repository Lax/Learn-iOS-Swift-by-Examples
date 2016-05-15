/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A data object for storing context information relevant to how the app was launched.
*/

import UIKit
import ListerKit

struct AppLaunchContext {
    // MARK: Properties
    
    let listURL: NSURL
    
    let listColor: List.Color
    
    // MARK: Initializers
    
    /**
        Initializes an `AppLaunchContext` instance with the color and URL provided.
        
        - parameter listURL: The `URL` of the file to launch to.
        - parameter listColor: The `List.Color` of the file to launch to.
    */
    init(listURL: NSURL, listColor: List.Color) {
        self.listURL = listURL
        self.listColor = listColor
    }
    
    /**
        Initializes an `AppLaunchContext` instance with the color and URL designated by the user activity.
        
        - parameter userActivity: The `userActivity` providing the file URL and list color to launch to.
        - parameter listsController: The `listsController` to be used to derive the `URL` available in the `userActivty`, if necessary.
    */
    init?(userActivity: NSUserActivity, listsController: ListsController) {
        guard let userInfo = userActivity.userInfo else {
            assertionFailure("User activity provided to \(#function) has no `userInfo` dictionary.")
            return nil
        }
        
        /*
            The URL may be provided as either a URL or a URL path via separate keys. Check first for 
            `NSUserActivityDocumentURLKey`, if not provided, obtain the path and create a file URL from it.
        */
        
        var possibleURL = userInfo[NSUserActivityDocumentURLKey] as? NSURL
        
        // If `URL` is `nil` the activity is being continued from a platofrm other than iOS or OS X.
        if possibleURL == nil {
            guard let listInfoFilePath = userInfo[AppConfiguration.UserActivity.listURLPathUserInfoKey] as? String else {
                assertionFailure("The `userInfo` dictionary provided to \(#function) did not contain a URL or URL path.")
                return nil
            }
            
            let fileURLForPath = NSURL(fileURLWithPath: listInfoFilePath, isDirectory: false)
            
            // Test for the existence of the file at the URL. If it exists proceed.
            if !fileURLForPath.checkPromisedItemIsReachableAndReturnError(nil) && !fileURLForPath.checkResourceIsReachableAndReturnError(nil) {
                // If the file does not exist at the URL created from the path construct one based on the filename.
                let derivedURL = listsController.documentsDirectory.URLByAppendingPathComponent(fileURLForPath.lastPathComponent!, isDirectory: false)
                
                if !derivedURL.checkPromisedItemIsReachableAndReturnError(nil) && !derivedURL.checkResourceIsReachableAndReturnError(nil) {
                    possibleURL = nil
                }
                else {
                    possibleURL = derivedURL
                }
            }
            else {
                possibleURL = fileURLForPath
            }
        }
        
        guard let URL = possibleURL else {
            assertionFailure("The `userInfo` dictionary provided to \(#function) did not contain a valid URL.")
            return nil
        }
        
        // Assign the URL resolved from the dictionary.
        listURL = URL
        
        // Attempt to obtain the `rawColor` stored as an `Int` value and construct a `List.Color` from it.
        guard let rawColor = userInfo[AppConfiguration.UserActivity.listColorUserInfoKey] as? Int,
              let color = List.Color(rawValue: rawColor) else {
            assertionFailure("The `userInfo` dictionary provided to \(#function) contains an invalid value for `color`.")
            return nil
        }
        
        listColor = color
    }
    
    /**
        Initializes an `AppLaunchContext` instance with the color and URL designated by the lister:// URL.
        
        - parameter listerURL: The URL adhering to the lister:// scheme providing the file URL and list color to launch to.
    */
    init?(listerURL: NSURL) {
        precondition(listerURL.scheme == AppConfiguration.ListerScheme.name, "Non-lister URL provided to \(#function).")
        
        guard let filePath = listerURL.path else {
            assertionFailure("URL provided to \(#function) is missing `path`.")
            return nil
        }
        
        // Construct a file URL from the path of the lister:// URL.
        listURL = NSURL(fileURLWithPath: filePath, isDirectory: false)
        
        // Extract the query items to initialize the `listColor` property from the `color` query item.
        guard let urlComponents = NSURLComponents(URL: listerURL, resolvingAgainstBaseURL: false),
              let queryItems = urlComponents.queryItems else {
                assertionFailure("URL provided to \(#function) contains no query items.")
                return nil
        }
        
        // Filter down to only the `color` query items. There should only be one.
        let colorQueryItems = queryItems.filter { $0.name == AppConfiguration.ListerScheme.colorQueryKey }
        
        guard let colorQueryItem = colorQueryItems.first where colorQueryItems.count == 1 else {
            assertionFailure("URL provided to \(#function) should contain only one `color` query item.")
            return nil
        }
        
        // Attempt to obtain the `rawColor` stored as an `Int` value and construct a `List.Color` from it.
        guard let colorQueryItemValue = colorQueryItem.value,
              let rawColor = Int(colorQueryItemValue),
              let color = List.Color(rawValue: rawColor) else {
            assertionFailure("URL provided to \(#function) contains an invalid value for `color`: \(colorQueryItem.value).")
            return nil
        }

        listColor = color
    }
}
