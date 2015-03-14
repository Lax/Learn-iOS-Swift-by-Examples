/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `List` class manages a list of items and the color of the list.
*/

import Foundation

/**
    The `List` class manages the color of a list and each `ListItem` object. `List` objects are copyable and
    archivable. `List` objects are normally associated with an object that conforms to `ListPresenterType`.
    This object manages how the list is presented, archived, and manipulated. To ensure that the `List` class
    is unarchivable from an instance that was archived in the Objective-C version of Lister, the `List` class
    declaration is annotated with @objc(AAPLList). This annotation ensures that the runtime name of the `List`
    class is the same as the `AAPLList` class defined in the Objective-C version of the app. It also allows 
    the Objective-C version of Lister to unarchive a `List` instance that was archived in the Swift version.
*/
@objc(AAPLList)
final public class List: NSObject, NSCoding, NSCopying, DebugPrintable {
    // MARK: Types
    
    /**
        String constants that are used to archive the stored properties of a `List`. These constants
        are used to help implement `NSCoding`.
    */
    private struct SerializationKeys {
        static let items = "items"
        static let color = "color"
    }
    
    /**
        The possible colors a list can have. Because a list's color is specific to a `List` object,
        it is represented by a nested type. The `Printable` representation of the enumeration is 
        the name of the value. For example, .Gray corresponds to "Gray".

        - Gray (default)
        - Blue
        - Green
        - Yellow
        - Orange
        - Red
    */
    public enum Color: Int, Printable {
        case Gray, Blue, Green, Yellow, Orange, Red
        
        // MARK: Properties

        public var name: String {
            switch self {
                case .Gray:     return "Gray"
                case .Blue:     return "Blue"
                case .Green:    return "Green"
                case .Orange:   return "Orange"
                case .Yellow:   return "Yellow"
                case .Red:      return "Red"
            }
        }

        // MARK: Printable
        
        public var description: String {
            return name
        }
    }
    
    // MARK: Properties
    
    /// The list's color. This property is stored when it is archived and read when it is unarchived.
    public var color: Color
    
    /// The list's items.
    public var items = [ListItem]()
    
    // MARK: Initializers
    
    /**
        Initializes a `List` instance with the designated color and items. The default color of a `List` is
        gray.
        
        :param: color The intended color of the list.
        :param: items The items that represent the underlying list. The `List` class copies the items
                      during initialization.
    */
    public init(color: Color = .Gray, items: [ListItem] = []) {
        self.color = color
        
        self.items = items.map { $0.copy() as ListItem }
    }

    // MARK: NSCoding
    
    public required init(coder aDecoder: NSCoder) {
        items = aDecoder.decodeObjectForKey(SerializationKeys.items) as [ListItem]
        color = Color(rawValue: aDecoder.decodeIntegerForKey(SerializationKeys.color))!
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(items, forKey: SerializationKeys.items)
        aCoder.encodeInteger(color.rawValue, forKey: SerializationKeys.color)
    }
    
    // MARK: NSCopying
    
    public func copyWithZone(zone: NSZone) -> AnyObject  {
        return List(color: color, items: items)
    }

    // MARK: Equality
    
    /**
        Overrides NSObject's isEqual(_:) instance method to return whether the list is equal to 
        another list. A `List` is considered to be equal to another `List` if its color and items
        are equal.
        
        :param: object Any object, or nil.
        
        :returns: `true` if the object is a `List` and it has the same color and items as the receiving
                  instance. `false` otherwise.
    */
    override public func isEqual(object: AnyObject?) -> Bool {
        if let list = object as? List {
            if color != list.color {
                return false
            }
            
            return items == list.items
        }
        
        return false
    }

    // MARK: DebugPrintable

    public override var debugDescription: String {
        return "{color: \(color), items: \(items)}"
    }
}
