/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

*/

import Cocoa
import ListerKitOSX

@objc protocol ListerTodayDocumentDelegate {
    func listerTodayDocumentDidUpdateContents(document: ListerTodayDocument)
}

class ListerTodayDocument: NSDocument {
    var list: List!

    weak var delegate: ListerTodayDocumentDelegate?
    
    override class func autosavesInPlace() -> Bool {
        return true
    }
    
    override func readFromData(data: NSData, ofType typeName: String, error outError: NSErrorPointer) -> Bool {
        if let deserializedList = NSKeyedUnarchiver.unarchiveObjectWithData(data) as List {
            list = deserializedList
            return true
        }
        
        let error = NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString("Could not read file", comment: "Read error description"),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString("File was in an invalid format", comment: "Read failure reason")
        ])
        
        outError.memory = error
        
        return false
    }
    
    override func dataOfType(typeName: String, error outError: NSErrorPointer) -> NSData? {
        if let data = NSKeyedArchiver.archivedDataWithRootObject(list) {
            return data
        }
        
        let error = NSError(domain: NSCocoaErrorDomain, code: NSFileWriteUnknownError, userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString("Could not save file", comment: "Write error description"),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString("An unexpected error occured", comment: "Write failure reason")
        ])
        
        outError.memory = error
        
        return nil
    }
}
