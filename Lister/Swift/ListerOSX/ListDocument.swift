/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                An NSDocument subclass that represents a list. It manages the serialization / deserialization of the list object, presentation of window controllers, and more.
            
*/

import Cocoa

// Protocol that allows a list document to notify other objects of it's changes.
@objc protocol ListDocumentDelegate {
    func listDocumentDidChangeContents(listDocument: ListDocument)
}

class ListDocument: NSDocument {
    // MARK: Properties
    
    weak var delegate: ListDocumentDelegate?

    var makesCustomWindowControllers = true
    
    // Use a default, empty list.
    var list = List()
    
    // MARK: Initializers

    convenience init(contentsOfURL URL: NSURL, makesCustomWindowControllers: Bool, error outError: NSErrorPointer) {
        self.init(contentsOfURL: URL, ofType: AppConfiguration.listerFileExtension, error: outError)
        
        self.makesCustomWindowControllers = makesCustomWindowControllers
    }
    
    // MARK: Auto Save and Versions

    override class func autosavesInPlace() -> Bool {
        return true
    }
    
    // MARK: NSDocument Overrides

    // Create window controllers from a storyboard, if desired (based on `makesWindowControllers`).
    // The window controller that's used is the initial controller set in the storyboard.
    override func makeWindowControllers() {
        super.makeWindowControllers()
        
        if makesCustomWindowControllers {
            let storyboard = NSStoryboard(name: "Storyboard", bundle: nil)
            
            let windowController = storyboard.instantiateInitialController() as NSWindowController
            
            addWindowController(windowController)
        }
    }

    override func defaultDraftName() -> String {
        return AppConfiguration.defaultListerDraftName
    }
    
    // MARK: Serialization / Deserialization
    
    override func readFromData(data: NSData, ofType typeName: String, error outError: NSErrorPointer) -> Bool {
        if let deserializedList = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? List {
            list = deserializedList
            
            delegate?.listDocumentDidChangeContents(self)
            
            return true
        }
        
        if outError {
            outError.memory = NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("Could not read file.", comment: "Read error description"),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString("File was in an invalid format.", comment: "Read failure reason")
            ])
        }

        return false
    }
    
    override func dataOfType(typeName: String, error outError: NSErrorPointer) -> NSData? {
        if let data = NSKeyedArchiver.archivedDataWithRootObject(list) {
            return data
        }
        
        if outError {
            outError.memory = NSError(domain: NSCocoaErrorDomain, code: NSFileWriteUnknownError, userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("Could not save file.", comment: "Write error description"),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString("An unexpected error occured.", comment: "Write failure reason")
            ])
        }

        return nil
    }
}
