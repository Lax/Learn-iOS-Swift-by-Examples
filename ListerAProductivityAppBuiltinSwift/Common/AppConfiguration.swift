/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Handles application configuration logic and information.
            
*/

import Foundation

class AppConfiguration {
    struct Defaults {
        static let firstLaunchKey = "AppConfiguration.Defaults.firstLaunchKey"
        static let storageOptionKey = "AppConfiguration.Defaults.storageOptionKey"
        static let storedUbiquityIdentityToken = "AppConfiguration.Defaults.storedUbiquityIdentityToken"
    }

    struct Notifications {
        struct StorageOptionDidChange {
            static let name = "AppConfiguration.Notifications.StorageOptionDidChange"
        }
    }
    
    struct Extensions {
        #if os(iOS)
        static let widgetBundleIdentifier = "com.example.apple-samplecode.Lister.ListerToday"
        #elseif os(OSX)
        static let widgetBundleIdentifier = "com.example.apple-samplecode.Lister.ListerTodayOSX"
        #endif
    }
    
    enum Storage: Int {
        case NotSet = 0, Local, Cloud
    }
    
    struct SharedInstances {
        static let sharedAppConfiguration = AppConfiguration()
    }
    
    class var sharedConfiguration: AppConfiguration {
        return SharedInstances.sharedAppConfiguration
    }
    
    class var listerFileExtension: String {
        return "list"
    }
    
    class var defaultListerDraftName: String {
        return NSLocalizedString("List", comment: "")
    }
    
    class var localizedTodayDocumentName: String {
        return NSLocalizedString("Today", comment: "The name of the Today list")
    }
    
    class var localizedTodayDocumentNameAndExtension: String {
        return "\(localizedTodayDocumentName).\(listerFileExtension)"
    }
    
    var storedIdentityToken: protocol<NSCoding, NSCopying, NSObjectProtocol>? {
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

    func runHandlerOnFirstLaunch(handler: Void -> Void) {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        defaults.registerDefaults([
            Defaults.firstLaunchKey: true,
            Defaults.storageOptionKey: Storage.NotSet.toRaw()
        ])

        if defaults.boolForKey(Defaults.firstLaunchKey) {
            defaults.setBool(false, forKey: Defaults.firstLaunchKey)
            handler()
        }
    }
    
    var storageOption: Storage {
        get {
            let value = NSUserDefaults.standardUserDefaults().integerForKey(Defaults.storageOptionKey)
            
            return Storage.fromRaw(value)!
        }

        set {
            NSUserDefaults.standardUserDefaults().setInteger(newValue.toRaw(), forKey: Defaults.storageOptionKey)

            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.StorageOptionDidChange.name, object: self, userInfo: nil)
        }
    }
    
    var isCloudAvailable: Bool {
        return NSFileManager.defaultManager().ubiquityIdentityToken != nil
    }

    // Convenience property to fetch the 3 cloud related states.
    var storageState: (storageOption: Storage, accountDidChange: Bool, cloudAvailable: Bool) {
        return (storageOption: storageOption, accountDidChange: hasUbiquityIdentityChanged, cloudAvailable: isCloudAvailable)
    }
    
    // MARK: Identity
    
    var hasUbiquityIdentityChanged: Bool {
        if storageOption != .Cloud {
            return false
        }

        var hasChanged = false
        
        let currentToken: protocol<NSCoding, NSCopying, NSObjectProtocol>? = NSFileManager.defaultManager().ubiquityIdentityToken
        let storedToken: protocol<NSCoding, NSCopying, NSObjectProtocol>? = storedIdentityToken

        let currentTokenNilStoredNonNil = !currentToken && storedToken
        let storedTokenNilCurrentNonNil = currentToken && !storedToken
        // Need to compare the tokens use isEqual(_:) since we only know that they conform to NSObjectProtocol.
        let currentNotEqualStored = currentToken && storedToken && !currentToken!.isEqual(storedToken!)

        if currentTokenNilStoredNonNil || storedTokenNilCurrentNonNil || currentNotEqualStored {
            handleUbiquityIdentityChange()
            hasChanged = true
        }

        return hasChanged
    }
    
    func handleUbiquityIdentityChange() {
        var defaults = NSUserDefaults.standardUserDefaults()

        if let token = NSFileManager.defaultManager().ubiquityIdentityToken {
            NSLog("The user signed into a different iCloud account.")
            let ubiquityIdentityTokenArchive = NSKeyedArchiver.archivedDataWithRootObject(token)
            defaults.setObject(ubiquityIdentityTokenArchive, forKey: Defaults.storedUbiquityIdentityToken)
        }
        else {
            NSLog("The user signed out of iCloud.")
            defaults.removeObjectForKey(Defaults.storedUbiquityIdentityToken)
        }
    }
}