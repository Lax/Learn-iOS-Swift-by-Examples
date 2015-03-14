/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The test case class for the `AppLaunchContext` class.
*/

import Lister
import ListerKit
import UIKit
import XCTest

class AppLaunchContextTests: XCTestCase {
    // MARK: Types
    
    struct UserActivity {
        static let testing = "com.example.apple-samplecode.Lister.testing"
    }
    
    // MARK: Properties
    
    var listURLs = [NSURL]()
    
    var color = List.Color.Blue
    
    // MARK: Setup
    
    override func setUp() {
        super.setUp()
        
        listURLs = NSBundle.mainBundle().URLsForResourcesWithExtension(AppConfiguration.listerFileExtension, subdirectory: "") as! [NSURL]
    }
    
    // MARK: Initializers
    
    func testUserActivityInitializerWithNSUserActivityDocumentURLKey() {
        var userActivity = NSUserActivity(activityType: UserActivity.testing)
        
        userActivity.addUserInfoEntriesFromDictionary([
            NSUserActivityDocumentURLKey: listURLs.first!,
            AppConfiguration.UserActivity.listColorUserInfoKey: color.rawValue
        ])
        
        let launchContext = AppLaunchContext(userActivity: userActivity)
        
        XCTAssertEqual(launchContext.listURL.absoluteURL!, listURLs.first!.absoluteURL!)
        XCTAssertEqual(launchContext.listColor, color)
    }
    
    func testUserActivityInitializerWithAppConfigurationUserActivitylistURLPathUserInfoKey() {
        var userActivity = NSUserActivity(activityType: UserActivity.testing)
        
        userActivity.addUserInfoEntriesFromDictionary([
            AppConfiguration.UserActivity.listURLPathUserInfoKey: listURLs.first!.path!,
            AppConfiguration.UserActivity.listColorUserInfoKey: color.rawValue
            ])
        
        let launchContext = AppLaunchContext(userActivity: userActivity)
        
        XCTAssertEqual(launchContext.listURL.absoluteURL!, listURLs.first!.absoluteURL!)
        XCTAssertEqual(launchContext.listColor, color)
    }
    
    func testUserActivityInitializerPrefersNSUserActivityDocumentURLKey() {
        var userActivity = NSUserActivity(activityType: UserActivity.testing)
        
        userActivity.addUserInfoEntriesFromDictionary([
            NSUserActivityDocumentURLKey: listURLs.first!,
            AppConfiguration.UserActivity.listURLPathUserInfoKey: listURLs.last!.path!,
            AppConfiguration.UserActivity.listColorUserInfoKey: color.rawValue
            ])
        
        let launchContext = AppLaunchContext(userActivity: userActivity)
        
        XCTAssertEqual(launchContext.listURL.absoluteURL!, listURLs.first!.absoluteURL!)
        XCTAssertEqual(launchContext.listColor, color)
    }
    
    func testListerURLSchemeInitializer() {
        // Construct a URL with the lister scheme and the file path of the document.
        let urlComponents = NSURLComponents()
        urlComponents.scheme = AppConfiguration.ListerScheme.name
        urlComponents.path = listURLs.first!.path!
        
        // Add a query item to encode the color associated with the list.
        let colorQueryValue = "\(color.rawValue)"
        let colorQueryItem = NSURLQueryItem(name: AppConfiguration.ListerScheme.colorQueryKey, value: colorQueryValue)
        urlComponents.queryItems = [colorQueryItem]
        
        let launchContext = AppLaunchContext(listerURL: urlComponents.URL!)
        
        XCTAssertEqual(launchContext.listURL.absoluteURL!, listURLs.first!.absoluteURL!)
        XCTAssertEqual(launchContext.listColor, color)
    }
}
