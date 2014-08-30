/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The ListItem class represents the text and completion state of a single item in the list.
            
*/

import Foundation

// To ensure that the ListItem class can be serialized from both Swift and Objective-C, we need to make sure that
// the runtime name of the ListItem class is the same in both contexts. To do these in Swift, we use the @objc marker
// on the class with the desired runtime name.
@objc(AAPLListItem) class ListItem: NSObject, NSCoding, NSCopying, Equatable {
    // MARK: Types

    // Serialization keys that are using to implement NSCoding.
    struct SerializationKey {
        static let text = "text"
        static let uuid = "uuid"
        static let completed = "completed"
    }

    // MARK: Properties

    var text: String
    var isComplete: Bool

    // Used for ListItem equality.
    var UUID: NSUUID
    
    // MARK: Initialization

    init(text: String, completed: Bool, UUID: NSUUID) {
        self.text = text
        self.isComplete = completed
        self.UUID = UUID
    }
    
    convenience init(text: String) {
        self.init(text: text, completed: false, UUID: NSUUID())
    }
    
    // MARK: NSCopying

    func copyWithZone(zone: NSZone) -> AnyObject  {
        return ListItem(text: text, completed: isComplete, UUID: UUID)
    }
    
    // MARK: NSCoding

    init(coder aDecoder: NSCoder) {
        text = aDecoder.decodeObjectForKey(SerializationKey.text) as String
        UUID = aDecoder.decodeObjectForKey(SerializationKey.uuid) as NSUUID
        isComplete = aDecoder.decodeBoolForKey(SerializationKey.completed)
    }
    
    func encodeWithCoder(encoder: NSCoder) {
        encoder.encodeObject(text, forKey: SerializationKey.text)
        encoder.encodeObject(UUID, forKey: SerializationKey.uuid)
        encoder.encodeBool(isComplete, forKey: SerializationKey.completed)
    }

    // Reset the UUID if the object needs to be re-tracked.
    func refreshIdentity() {
        UUID = NSUUID()
    }
    
    // MARK: Overrides
    
    override func isEqual(object: AnyObject!) -> Bool {
        if let list = object as? ListItem {
            return self == list
        }
        
        return false
    }
}

// An operator overload to equate to ListItem objects.
func ==(lhs: ListItem, rhs: ListItem) -> Bool {
    return lhs.UUID == rhs.UUID
}
