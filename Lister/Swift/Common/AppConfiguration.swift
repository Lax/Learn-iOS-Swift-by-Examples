/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Handles application configuration logic and information.
            
*/

import Foundation

public class AppConfiguration {
    private struct Defaults {
        static let firstLaunchKey = "AppConfiguration.Defaults.firstLaunchKey"
        static let storageOptionKey = "AppConfiguration.Defaults.storageOptionKey"
        static let storedUbiquityIdentityToken = "AppConfiguration.Defaults.storedUbiquityIdentityToken"
    }
    
    public struct UserActivity {
        public static let listColorUserInfoKey = "listColor"
    }
    
    #if os(OSX)
    public struct App {
        public static let bundleIdentifier = "com.example.apple-samplecode.ListerOSX"
    }
    #endif

    public struct Extensions {
        #if os(iOS)
        public static let widgetBundleIdentifier = "com.example.apple-samplecode.Lister.ListerToday"
        #elseif os(OSX)
        public static let widgetBundleIdentifier = "com.example.apple-samplecode.Lister.ListerTodayOSX"
        #endif
    }

    public enum Storage: Int {
        case NotSet = 0, Local, Cloud
    }
    
    public class var sharedConfiguration: AppConfiguration {
        struct Singleton {
            static let sharedAppConfiguration = AppConfiguration()
        }

        return Singleton.sharedAppConfiguration
    }
    
    public class var listerUTI: String {
        return "com.example.apple-samplecode.Lister"
    }
    
    public class var listerFileExtension: String {
        return "list"
    }
    
    public class var defaultListerDraftName: String {
        return NSLocalizedString("List", comment: "")
    }
    
    public class var localizedTodayDocumentName: String {
        return NSLocalizedString("Today", comment: "The name of the Today list")
    }
    
    public class var localizedTodayDocumentNameAndExtension: String {
        return "\(localizedTodayDocumentName).\(listerFileExtension)"
    }
    
    public func runHandlerOnFirstLaunch(firstLaunchHandler: Void -> Void) {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        #if os(iOS)
        let defaultOptions: [NSObject: AnyObject] = [
            Defaults.firstLaunchKey: true,
            Defaults.storageOptionKey: Storage.NotSet.rawValue
        ]
        #elseif os(OSX)
        let defaultOptions: [NSObject: AnyObject] = [
            Defaults.firstLaunchKey: true
        ]
        #endif
        
        defaults.registerDefaults(defaultOptions)

        if defaults.boolForKey(Defaults.firstLaunchKey) {
            defaults.setBool(false, forKey: Defaults.firstLaunchKey)

            firstLaunchHandler()
        }
    }
    
    public var isCloudAvailable: Bool {
        return NSFileManager.defaultManager().ubiquityIdentityToken != nil
    }
    
    #if os(iOS)
    public var storageOption: Storage {
        get {
            let value = NSUserDefaults.standardUserDefaults().integerForKey(Defaults.storageOptionKey)
            
            return Storage(rawValue: value)!
        }

        set {
            NSUserDefaults.standardUserDefaults().setInteger(newValue.rawValue, forKey: Defaults.storageOptionKey)
        }
    }

    // MARK: Ubiquity Identity Token Handling (Account Change Info)
    
    public func hasAccountChanged() -> Bool {
        var hasChanged = false
        
        let currentToken: protocol<NSCoding, NSCopying, NSObjectProtocol>? = NSFileManager.defaultManager().ubiquityIdentityToken
        let storedToken: protocol<NSCoding, NSCopying, NSObjectProtocol>? = storedUbiquityIdentityToken
        
        let currentTokenNilStoredNonNil = currentToken == nil && storedToken != nil
        let storedTokenNilCurrentNonNil = currentToken != nil && storedToken == nil
        
        // Compare the tokens.
        let currentNotEqualStored = currentToken != nil && storedToken != nil && !currentToken!.isEqual(storedToken!)
        
        if currentTokenNilStoredNonNil || storedTokenNilCurrentNonNil || currentNotEqualStored {
            persistAccount()
            
            hasChanged = true
        }
        
        return hasChanged
    }

    private func persistAccount() {
        var defaults = NSUserDefaults.standardUserDefaults()
        
        if let token = NSFileManager.defaultManager().ubiquityIdentityToken {
            let ubiquityIdentityTokenArchive = NSKeyedArchiver.archivedDataWithRootObject(token)
            
            defaults.setObject(ubiquityIdentityTokenArchive, forKey: Defaults.storedUbiquityIdentityToken)
        }
        else {
            defaults.removeObjectForKey(Defaults.storedUbiquityIdentityToken)
        }
    }
    
    // MARK: Convenience

    private var storedUbiquityIdentityToken: protocol<NSCoding, NSCopying, NSObjectProtocol>? {
        var storedToken: protocol<NSCoding, NSCopying, NSObjectProtocol>?
        
        // Determine if the logged in iCloud account has changed since the user last launched the app.
        let archivedObject: AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey(Defaults.storedUbiquityIdentityToken)
        
        if let ubiquityIdentityTokenArchive = archivedObject as? NSData {
            if let archivedObject = NSKeyedUnarchiver.unarchiveObjectWithData(ubiquityIdentityTokenArchive) as? protocol<NSCoding, NSCopying, NSObjectProtocol> {
                storedToken = archivedObject
            }
        }
        
        return storedToken
    }

    #endif
}