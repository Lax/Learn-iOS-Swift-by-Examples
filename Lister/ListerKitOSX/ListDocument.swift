/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ListDocument` class is an `NSDocument` subclass that represents a list. It manages the serialization / deserialization of the list object, presentation of window controllers, a list presenter, and more.
*/

import Cocoa

public class ListDocument: NSDocument {
    // MARK: Types
    
    private struct StoryboardConstants {
        static let listWindowControllerStoryboardIdentifier = "ListWindowControllerStoryboardIdentifier"
    }
    
    // MARK: Properties

    private var makesCustomWindowControllers = true

    public var listPresenter: ListPresenterType? {
        didSet {
            if let unarchivedList = unarchivedList {
                listPresenter?.setList(unarchivedList)
            }
        }
    }

    public var unarchivedList: List?

    // MARK: Initializers

    public convenience init(contentsOfURL URL: NSURL, makesCustomWindowControllers: Bool) throws {
        try self.init(contentsOfURL: URL, ofType: AppConfiguration.listerFileExtension)

        self.makesCustomWindowControllers = makesCustomWindowControllers
    }
    
    // MARK: Auto Save and Versions

    override public class func autosavesInPlace() -> Bool {
        return true
    }
    
    // MARK: NSDocument Overrides

    /**
        Create window controllers from a storyboard, if desired (based on `makesWindowControllers`).
        The window controller that's used is the initial controller set in the storyboard.
    */
    override public func makeWindowControllers() {
        super.makeWindowControllers()
        
        if makesCustomWindowControllers {
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            
            let windowController = storyboard.instantiateControllerWithIdentifier(StoryboardConstants.listWindowControllerStoryboardIdentifier) as! NSWindowController

            addWindowController(windowController)
        }
    }

    override public func defaultDraftName() -> String {
        return AppConfiguration.defaultListerDraftName
    }
    
    // MARK: Serialization / Deserialization
    
    override public func readFromData(data: NSData, ofType typeName: String) throws {
        unarchivedList = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? List

        if let unarchivedList = unarchivedList {
            listPresenter?.setList(unarchivedList)
            
            return
        }
        
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("Could not read file.", comment: "Read error description"),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString("File was in an invalid format.", comment: "Read failure reason")
        ])
    }
    
    override public func dataOfType(typeName: String) throws -> NSData {
        if let archiveableList = listPresenter?.archiveableList {
            return NSKeyedArchiver.archivedDataWithRootObject(archiveableList)
        }
        
        throw NSError(domain: "ListDocumentDomain", code: -1, userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString("Could not archive list", comment: "Archive error description"),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString("No list presenter was available for the document", comment: "Archive failure reason")
        ])
    }
    
    // MARK: Handoff
    
    override public func updateUserActivityState(userActivity: NSUserActivity) {
        super.updateUserActivityState(userActivity)

        // Store the list's color in the user activity to be able to quickly present a list when it's viewed.
        userActivity.addUserInfoEntriesFromDictionary([
            AppConfiguration.UserActivity.listColorUserInfoKey: listPresenter!.color.rawValue
        ])
    }
}
