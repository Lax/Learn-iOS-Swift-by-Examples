/*
<codex />
*/

import UIKit

var _sharedListCoordinator: ListCoordinator?

class ListCoordinator: NSObject {
    struct Notifications {
        static let storageChoiceDidChangeNotification = "storageChoiceDidChangeNotification"
    }
    
    struct Defaults {
        static let storedUbiquityIdentityToken = "storedUbiquityIdentityToken"
    }
    
    struct Identifiers {
        static let applicationGropuIdentifier = "A93A5CM278.com.example.apple-samplecode.ListerGroup"
        static let ubiquityContainerIdentifier = "A93A5CM278.com.example.apple-samplecode.Lister"
    }
    
    class func sharedListCoordinator() -> ListCoordinator {
        if _sharedListCoordinator {
            return _sharedListCoordinator!
        }
        
        _sharedListCoordinator = ListCoordinator()
        
        return _sharedListCoordinator!
    }
    
    var storedUbiquityIdentityToken: protocol<NSCoding, NSCopying, NSObjectProtocol>? {
    var storedToken: protocol<NSCoding, NSCopying, NSObjectProtocol>?
        
        // determine if the logged in iCloud account has changed since the user last launched the app
        let archivedObject: AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey(ListCoordinator.Defaults.storedUbiquityIdentityToken)
        if let ubiquityIdentityTokenArchive = archivedObject as? NSData {
            if let archivedObject = NSKeyedUnarchiver.unarchiveObjectWithData(ubiquityIdentityTokenArchive) as? protocol<NSCoding, NSCopying, NSObjectProtocol> {
                storedToken = archivedObject
            }
        }
        
        return storedToken
    }
    
    var documentsDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as NSURL
    var groupDocumentsDirectory: NSURL {
          if cloudEnabled {
            return documentsDirectory
          }
          else {
             return NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(ListCoordinator.Identifiers.applicationGropuIdentifier)
          }
    }
    
    var todayDocumentURL: NSURL {
    return groupDocumentsDirectory.URLByAppendingPathComponent("Today.list")
    }
    var cloudEnabled: Bool = false {
        didSet {
            if cloudEnabled != oldValue {
                updateFileStorageContainerURL()
                NSNotificationCenter.defaultCenter().postNotificationName(ListCoordinator.Notifications.storageChoiceDidChangeNotification, object: self)
            }
        }
    }
    
    // MARK: Identity
    
    func checkUbiquityIdentityDidChange() -> Bool {
        var result = false
        
        let currentToken = NSFileManager.defaultManager().ubiquityIdentityToken
        let storedToken = storedUbiquityIdentityToken
        
        if !currentToken || !storedToken || !currentToken.isEqual(storedToken) {
            println("ubiquity identity has changed")
            handleUbiquityIdentityChange()
            result = true
        }
        
        return result
    }
    
    func handleUbiquityIdentityChange() {
        var defaults = NSUserDefaults.standardUserDefaults()
        if let token = NSFileManager.defaultManager().ubiquityIdentityToken {
            // the account has changed
            println("user changed iCloud accounts")
            let ubiquityIdentityTokenArchive = NSKeyedArchiver.archivedDataWithRootObject(token)
            defaults.setObject(ubiquityIdentityTokenArchive, forKey: ListCoordinator.Defaults.storedUbiquityIdentityToken)
        }
        else {
            // there is no signed-in account
            println("user signed out of iCloud")
            defaults.removeObjectForKey(ListCoordinator.Defaults.storedUbiquityIdentityToken)
        }
        
        defaults.synchronize()
    }
    
    func ubiquityIdentityDidChangeNotification(notification: NSNotification) {
        println("ubiquity identity did change")
        handleUbiquityIdentityChange()
        
        println("should post a notification to alert the app that the identity has changed")
    }
    
    // MARK: Today
    
    func ensureTodayDocumentExistsWithError(outError: NSErrorPointer) -> Bool {
        let fileManager = NSFileManager.defaultManager()
        
        if fileManager.fileExistsAtPath(todayDocumentURL.path) {
            return true
        }
        
        // <rdar://problem/16908721> NSBundle(forClass:) should remain as NSBundle.bundleForClass()
        // <rdar://problem/16880689> "dynamicType" requires "self" in class scope
        let defaultTodayDocumentURL = NSBundle.mainBundle().URLForResource("Today", withExtension: "list")
        
        return fileManager.copyItemAtURL(defaultTodayDocumentURL, toURL: todayDocumentURL, error: error)
    }
    
    // MARK: Document Handling
    
    func updateFileStorageContainerURL() {
        let oldDocumentsDirectory = documentsDirectory
        
        if !cloudEnabled {
            // <rdar://problem/16953693> Array.firstElement
            documentsDirectory = (NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as NSURL)
        }
        else {
            let cloudDirectory = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier(ListCoordinator.Identifiers.ubiquityContainerIdentifier)!
            documentsDirectory = cloudDirectory.URLByAppendingPathComponent("Documents")
            
            var error: NSError?
            let localDocuments = NSFileManager.defaultManager().contentsOfDirectoryAtURL(oldDocumentsDirectory, includingPropertiesForKeys: nil, options: .SkipsPackageDescendants, error: &error)
            
            for object: AnyObject in localDocuments! {
                if let url = object as? NSURL {
                    if url.pathExtension == "list" {
                        moveFileToUbiquity(url)
                    }
                }
            }
        }
    }
    
    func moveFileToUbiquity(sourceURL: NSURL) {
        let destinationFileName = sourceURL.lastPathComponent
        let destinationURL = documentsDirectory.URLByAppendingPathComponent(destinationFileName)
        
        // dispatch ubiquity upload to background queue
        var defaultQueue = dispatch_get_global_queue(CLong(DISPATCH_QUEUE_PRIORITY_DEFAULT), 0)
        dispatch_async(defaultQueue) {
            let fileManager = NSFileManager()
            
            var error: NSError?
            let success: Bool = fileManager.setUbiquitous(true, itemAtURL: sourceURL, destinationURL: destinationURL, error: &error)
            
            if !success {
                println("couldn't move file \(sourceURL.absoluteString) to cloud at: \(destinationURL.absoluteString). Error: \(error.description)")
            }
        }
    }
    
    func copyFileToDocuments(sourceURL: NSURL) {
        copyFileFrom(sourceURL, to: documentsDirectory.URLByAppendingPathComponent(sourceURL.lastPathComponent))
    }
    
    func copyFileToGroupDocuments(sourceURL: NSURL) {
        copyFileFrom(sourceURL, to: groupDocumentsDirectory.URLByAppendingPathComponent(sourceURL.lastPathComponent))
    }
    
    func copyFileFrom(from: NSURL, to: NSURL) {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        
        coordinator.coordinateWritingItemAtURL(from, options: .ForMoving, writingItemAtURL: to, options: .ForReplacing, error: nil) { (source, destination) in
            var moveError: NSError?
            let success = NSFileManager().copyItemAtURL(source, toURL: destination, error: &moveError)
            if success {
                println("moved file: \(source.absoluteString) to: \(destination.absoluteString).")
            }
            else {
                println("couldn't move file: \(source.absoluteString) to: \(destination.absoluteString). Error: \(moveError.description)")
            }
        }
    }
    
    func deleteFileAtURL(fileURL: NSURL) {
        let fileCoordinator = NSFileCoordinator()
        var error: NSError?
        fileCoordinator.coordinateWritingItemAtURL(fileURL, options: .ForDeleting, error: &error) { writingURL in
            NSFileManager().removeItemAtURL(writingURL, error: &error)
            
            // Need the return statement here because single line closures are assumed to return values.
            // Tracking radar for fix: <rdar://problem/13175298> Allow function conversion from (A) -> B to (A) -> ()
            return
        }
        
        if error {
            println("couldn't delete file at URL \(fileURL.absoluteString). Error: \(error.description)")
        }
    }
}
