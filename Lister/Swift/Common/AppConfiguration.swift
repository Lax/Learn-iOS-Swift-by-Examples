/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Handles application configuration logic and information.
*/

import Foundation

public typealias StorageState = (storageOption: AppConfiguration.Storage, accountDidChange: Bool, cloudAvailable: Bool)

public class AppConfiguration {
    // MARK: Types
    
    private struct Defaults {
        static let firstLaunchKey = "AppConfiguration.Defaults.firstLaunchKey"
        static let storageOptionKey = "AppConfiguration.Defaults.storageOptionKey"
        static let storedUbiquityIdentityToken = "AppConfiguration.Defaults.storedUbiquityIdentityToken"
    }
    
    // Keys used to store relevant list data in the userInfo dictionary of an NSUserActivity for continuation.
    public struct UserActivity {
        // The editing user activity is integrated into the ubiquitous UI/NSDocument architecture.
        public static let editing = "com.example.apple-samplecode.Lister.editing"
        
        // The watch user activity is used to continue activities started on the watch on other devices.
        public static let watch = "com.example.apple-samplecode.Lister.watch"
        
        // The user info key used for storing the list path for use in transition from glance -> app on the watch.
        public static var listURLPathUserInfoKey = "listURLPathUserInfoKey"
        
        // The user info key used for storing the list color for use in transition from glance -> app on the watch.
        public static var listColorUserInfoKey = "listColorUserInfoKey"
    }
    
    // Keys used to store information in a WCSession context.
    public struct ApplicationActivityContext {
        public static let currentListsKey = "ListerCurrentLists"
        public static let listNameKey = "name"
        public static let listColorKey = "color"
    }
    
    // Constants used in assembling and handling the custom lister:// URL scheme.
    public struct ListerScheme {
        // The scheme name used for encoding the list when transitioning from today -> app on iOS.
        public static var name = "lister"
        // The query key used for encoding the list color when transitioning from today -> app on iOS.
        public static var colorQueryKey = "color"
    }
    
    /*
        The value of the `LISTER_BUNDLE_PREFIX` user-defined build setting is written to the Info.plist file of
        every target in Swift version of the Lister project. Specifically, the value of `LISTER_BUNDLE_PREFIX` 
        is used as the string value for a key of `AAPLListerBundlePrefix`. This value is loaded from the target's
        bundle by the lazily evaluated static variable "prefix" from the nested "Bundle" struct below the first
        time that "Bundle.prefix" is accessed. This avoids the need for developers to edit both `LISTER_BUNDLE_PREFIX`
        and the code below. The value of `Bundle.prefix` is then used as part of an interpolated string to insert
        the user-defined value of `LISTER_BUNDLE_PREFIX` into several static string constants below.
    */
    private struct Bundle {
        static var prefix = NSBundle.mainBundle().objectForInfoDictionaryKey("AAPLListerBundlePrefix") as! String
    }

    struct ApplicationGroups {
        static let primary = "group.\(Bundle.prefix).Lister.Documents"
    }
    
    #if os(OSX)
    public struct App {
        public static let bundleIdentifier = "\(Bundle.prefix).ListerOSX"
    }
    #endif
    
    public struct Extensions {
        #if os(iOS)
        public static let widgetBundleIdentifier = "\(Bundle.prefix).Lister.ListerToday"
        #elseif os(OSX)
        public static let widgetBundleIdentifier = "\(Bundle.prefix).Lister.ListerTodayOSX"
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
    
    private var applicationUserDefaults: NSUserDefaults {
        return NSUserDefaults(suiteName: ApplicationGroups.primary)!
    }
    
    public private(set) var isFirstLaunch: Bool {
        get {
            registerDefaults()
            
            return applicationUserDefaults.boolForKey(Defaults.firstLaunchKey)
        }
        set {
            applicationUserDefaults.setBool(newValue, forKey: Defaults.firstLaunchKey)
        }
    }
    
    private func registerDefaults() {
        #if os(iOS)
            let defaultOptions: [String: AnyObject] = [
                Defaults.firstLaunchKey: true,
                Defaults.storageOptionKey: Storage.NotSet.rawValue
            ]
        #elseif os(watchOS)
            let defaultOptions: [String: AnyObject] = [
                Defaults.firstLaunchKey: true
            ]
        #elseif os(OSX)
            let defaultOptions: [String: AnyObject] = [
                Defaults.firstLaunchKey: true
            ]
        #endif
        
        applicationUserDefaults.registerDefaults(defaultOptions)
    }
    
    public func runHandlerOnFirstLaunch(firstLaunchHandler: Void -> Void) {
        if isFirstLaunch {
            isFirstLaunch = false

            firstLaunchHandler()
        }
    }
    
    public var isCloudAvailable: Bool {
        return NSFileManager.defaultManager().ubiquityIdentityToken != nil
    }
    
    #if os(iOS)
    public var storageState: StorageState {
        return (storageOption, hasAccountChanged(), isCloudAvailable)
    }
    
    public var storageOption: Storage {
        get {
            let value = applicationUserDefaults.integerForKey(Defaults.storageOptionKey)
            
            return Storage(rawValue: value)!
        }

        set {
            applicationUserDefaults.setInteger(newValue.rawValue, forKey: Defaults.storageOptionKey)
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
        let defaults = applicationUserDefaults
        
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
        let archivedObject: AnyObject? = applicationUserDefaults.objectForKey(Defaults.storedUbiquityIdentityToken)
        
        if let ubiquityIdentityTokenArchive = archivedObject as? NSData,
           let archivedObject = NSKeyedUnarchiver.unarchiveObjectWithData(ubiquityIdentityTokenArchive) as? protocol<NSCoding, NSCopying, NSObjectProtocol> {
            storedToken = archivedObject
        }
        
        return storedToken
    }
    
    /**
        Returns a `ListCoordinator` based on the current configuration that queries based on `pathExtension`.
        For example, if the user has chosen local storage, a local `ListCoordinator` object will be returned.
    */
    public func listCoordinatorForCurrentConfigurationWithPathExtension(pathExtension: String, firstQueryHandler: (Void -> Void)? = nil) -> ListCoordinator {
        if AppConfiguration.sharedConfiguration.storageOption != .Cloud {
            // This will be called if the storage option is either `.Local` or `.NotSet`.
            return LocalListCoordinator(pathExtension: pathExtension, firstQueryUpdateHandler: firstQueryHandler)
        }
        else {
            return CloudListCoordinator(pathExtension: pathExtension, firstQueryUpdateHandler: firstQueryHandler)
        }
    }
    
    /**
        Returns a `ListCoordinator` based on the current configuration that queries based on `lastPathComponent`.
        For example, if the user has chosen local storage, a local `ListCoordinator` object will be returned.
    */
    public func listCoordinatorForCurrentConfigurationWithLastPathComponent(lastPathComponent: String, firstQueryHandler: (Void -> Void)? = nil) -> ListCoordinator {
        if AppConfiguration.sharedConfiguration.storageOption != .Cloud {
            // This will be called if the storage option is either `.Local` or `.NotSet`.
            return LocalListCoordinator(lastPathComponent: lastPathComponent, firstQueryUpdateHandler: firstQueryHandler)
        }
        else {
            return CloudListCoordinator(lastPathComponent: lastPathComponent, firstQueryUpdateHandler: firstQueryHandler)
        }
    }
    
    /**
        Returns a `ListsController` instance based on the current configuration. For example, if the user has
        chosen local storage, a `ListsController` object will be returned that uses a local list coordinator.
        `pathExtension` is passed down to the list coordinator to filter results.
    */
    public func listsControllerForCurrentConfigurationWithPathExtension(pathExtension: String, firstQueryHandler: (Void -> Void)? = nil) -> ListsController {
        let listCoordinator = listCoordinatorForCurrentConfigurationWithPathExtension(pathExtension, firstQueryHandler: firstQueryHandler)
        
        return ListsController(listCoordinator: listCoordinator, delegateQueue: NSOperationQueue.mainQueue()) { lhs, rhs in
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == NSComparisonResult.OrderedAscending
        }
    }

    /**
        Returns a `ListsController` instance based on the current configuration. For example, if the user has
        chosen local storage, a `ListsController` object will be returned that uses a local list coordinator.
        `lastPathComponent` is passed down to the list coordinator to filter results.
    */
    public func listsControllerForCurrentConfigurationWithLastPathComponent(lastPathComponent: String, firstQueryHandler: (Void -> Void)? = nil) -> ListsController {
        let listCoordinator = listCoordinatorForCurrentConfigurationWithLastPathComponent(lastPathComponent, firstQueryHandler: firstQueryHandler)
        
        return ListsController(listCoordinator: listCoordinator, delegateQueue: NSOperationQueue.mainQueue()) { lhs, rhs in
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == NSComparisonResult.OrderedAscending
        }
    }
    
    #endif
}