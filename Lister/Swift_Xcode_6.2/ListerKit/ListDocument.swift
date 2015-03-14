/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ListDocument` class is a `UIDocument` subclass that represents a list. `ListDocument` manages the serialization / deserialization of the list object in addition to a list presenter.
*/

import UIKit

/// Protocol that allows a list document to notify other objects of it being deleted.
@objc public protocol ListDocumentDelegate {
    func listDocumentWasDeleted(listDocument: ListDocument)
}

public class ListDocument: UIDocument {
    // MARK: Properties

    public weak var delegate: ListDocumentDelegate?
    
    // Use a default, empty list.
    public var listPresenter: ListPresenterType?

    // MARK: Initializers
    
    public init(fileURL URL: NSURL, listPresenter: ListPresenterType? = nil) {
        self.listPresenter = listPresenter

        super.init(fileURL: URL)
    }

    // MARK: Serialization / Deserialization
    
    override public func loadFromContents(contents: AnyObject, ofType typeName: String, error outError: NSErrorPointer) -> Bool {
        if let unarchivedList = NSKeyedUnarchiver.unarchiveObjectWithData(contents as NSData) as? List {
            /*
                This method is called on the queue that the `openWithCompletionHandler(_:)` method was called
                on (typically, the main queue). List presenter operations are main queue only, so explicitly
                call on the main queue.
            */
            dispatch_async(dispatch_get_main_queue()) {
                self.listPresenter?.setList(unarchivedList)
                
                return
            }

            return true
        }
        
        if outError != nil {
            outError.memory = NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("Could not read file", comment: "Read error description"),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString("File was in an invalid format", comment: "Read failure reason")
            ])
        }
        
        return false
    }

    override public func contentsForType(typeName: String, error outError: NSErrorPointer) -> AnyObject? {
        if let archiveableList = listPresenter?.archiveableList {
            return NSKeyedArchiver.archivedDataWithRootObject(archiveableList)
        }

        return nil
    }
    
    // MARK: Deletion

    override public func accommodatePresentedItemDeletionWithCompletionHandler(completionHandler: NSError? -> Void) {
        super.accommodatePresentedItemDeletionWithCompletionHandler(completionHandler)
        
        delegate?.listDocumentWasDeleted(self)
    }
    
    // MARK: Handoff
    
    override public func updateUserActivityState(userActivity: NSUserActivity) {
        super.updateUserActivityState(userActivity)
        
        if let rawColorValue = listPresenter?.color.rawValue {
            userActivity.addUserInfoEntriesFromDictionary([
                AppConfiguration.UserActivity.listColorUserInfoKey: rawColorValue
            ])
        }
    }
}
