/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The `ListDocument` class is an NSDocument subclass that represents a list. It manages the serialization / deserialization of the list object, presentation of window controllers, and more.
            
*/

import Cocoa

/// Protocol that allows a list document to notify other objects of it's changes.
@objc public protocol ListDocumentDelegate {
    func listDocumentDidChangeContents(listDocument: ListDocument)
}

public class ListDocument: NSDocument {
    // MARK: Types
    
    private struct StoryboardConstants {
        static let listWindowControllerStoryboardIdentifier = "ListWindowControllerStoryboardIdentifier"
    }
    
    // MARK: Properties
    
    public weak var delegate: ListDocumentDelegate?

    private var makesCustomWindowControllers = true
    
    // Use a default, empty list.
    public var list = List()
    
    // MARK: Initializers

    public convenience init?(contentsOfURL URL: NSURL, makesCustomWindowControllers: Bool, error outError: NSErrorPointer) {
        self.init(contentsOfURL: URL, ofType: AppConfiguration.listerFileExtension, error: outError)
        
        self.makesCustomWindowControllers = makesCustomWindowControllers
    }
    
    // MARK: Auto Save and Versions

    override public class func autosavesInPlace() -> Bool {
        return true
    }
    
    // MARK: NSDocument Overrides

    /// Create window controllers from a storyboard, if desired (based on `makesWindowControllers`).
    /// The window controller that's used is the initial controller set in the storyboard.
    override public func makeWindowControllers() {
        super.makeWindowControllers()
        
        if makesCustomWindowControllers {
            let storyboard = NSStoryboard(name: "Main", bundle: nil)!
            
            let windowController = storyboard.instantiateControllerWithIdentifier(StoryboardConstants.listWindowControllerStoryboardIdentifier) as NSWindowController

            addWindowController(windowController)
        }
    }

    override public func defaultDraftName() -> String {
        return AppConfiguration.defaultListerDraftName
    }
    
    // MARK: Serialization / Deserialization
    
    override public func readFromData(data: NSData, ofType typeName: String, error outError: NSErrorPointer) -> Bool {
        if let deserializedList = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? List {
            list = deserializedList
            
            delegate?.listDocumentDidChangeContents(self)
            
            return true
        }
        
        if outError != nil {
            outError.memory = NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("Could not read file.", comment: "Read error description"),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString("File was in an invalid format.", comment: "Read failure reason")
            ])
        }

        return false
    }
    
    override public func dataOfType(typeName: String, error outError: NSErrorPointer) -> NSData? {
        return NSKeyedArchiver.archivedDataWithRootObject(list)
    }
    
    // MARK: Handoff
    
    override public func updateUserActivityState(userActivity: NSUserActivity) {
        super.updateUserActivityState(userActivity)
        userActivity.addUserInfoEntriesFromDictionary([ AppConfiguration.UserActivity.listColorUserInfoKey: list.color.rawValue ])
    }
}
