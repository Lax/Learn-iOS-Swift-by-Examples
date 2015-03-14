/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
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
        Initializes an `AppLaunchContext` instance with the color and URL designated by the user activity.
        
        :param: userActivity The userActivity providing the file URL and list color to launch to.
    */
    init(userActivity: NSUserActivity) {
        assert(userActivity.userInfo != nil, "User activity provided to \(__FUNCTION__) has no `userInfo` dictionary.")
        let userInfo = userActivity.userInfo!
        
        /*
            The URL may be provided as either a URL or a URL path via separate keys. Check first for 
            `NSUserActivityDocumentURLKey`, if not provided, obtain the path and create a file URL from it.
        */
        
        var URL = userInfo[NSUserActivityDocumentURLKey] as? NSURL
        
        if URL == nil {
            let listInfoFilePath = userInfo[AppConfiguration.UserActivity.listURLPathUserInfoKey] as? String
            
            assert(listInfoFilePath != nil, "The `userInfo` dictionary provided to \(__FUNCTION__) did not contain a URL or URL path.")
            
            URL = NSURL(fileURLWithPath: listInfoFilePath!, isDirectory: false)
        }
        
        assert(URL != nil, "The `userInfo` dictionary provided to \(__FUNCTION__) did not contain a valid URL.")
        
        // Unwrap the URL obtained from the dictionary.
        listURL = URL!
        
        // The color will be stored as an `Int` under the prescribed key.
        let rawColor = userInfo[AppConfiguration.UserActivity.listColorUserInfoKey] as? Int
        
        assert(rawColor == nil || 0...5 ~= rawColor!, "The `userInfo` dictionary provided to \(__FUNCTION__) contains an invalid value for `color`: \(rawColor).")
        
        // Unwrap the `rawColor` value and construct a `List.Color` from it.
        listColor = List.Color(rawValue: rawColor!)!
    }
    
    /**
        Initializes an `AppLaunchContext` instance with the color and URL designated by the lister:// URL.
        
        :param: listerURL The URL adhering to the lister:// scheme providing the file URL and list color to launch to.
    */
    init(listerURL: NSURL) {
        assert(listerURL.scheme != nil && listerURL.scheme! == AppConfiguration.ListerScheme.name, "Non-lister URL provided to \(__FUNCTION__).")
        
        assert(listerURL.path != nil, "URL provided to \(__FUNCTION__) is missing `path`.")
        
        // Construct a file URL from the path of the lister:// URL.
        listURL = NSURL(fileURLWithPath: listerURL.path!, isDirectory: false)!
        
        // Extract the query items to initialize the `listColor` property from the `color` query item.
        let urlComponents = NSURLComponents(URL: listerURL, resolvingAgainstBaseURL: false)!
        let queryItems = urlComponents.queryItems as [NSURLQueryItem]
        
        // Filter down to only the `color` query items. There should only be one.
        let colorQueryItems = queryItems.filter { $0.name == AppConfiguration.ListerScheme.colorQueryKey }
        
        assert(colorQueryItems.count == 1, "URL provided to \(__FUNCTION__) should contain only one `color` query item.")
        let colorQueryItem = colorQueryItems.first!
        
        // Obtain a `rawColor` value by converting the `String` `value` of the query item to an `Int`.
        let rawColor = colorQueryItem.value?.toInt()
        
        assert(rawColor != nil || 0...5 ~= rawColor!, "URL provided to \(__FUNCTION__) contains an invalid value for `color`: \(colorQueryItem.value).")

        // Unwrap the `rawColor` value and construct a `List.Color` from it.
        listColor = List.Color(rawValue: rawColor!)!
    }
}
