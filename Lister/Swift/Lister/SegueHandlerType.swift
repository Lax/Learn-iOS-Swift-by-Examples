/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Contains types / typealiases for cross-platform utility helpers for working with segues / segue identifiers in a controller.
*/

#if os(iOS)
import UIKit
public typealias StoryboardSegue = UIStoryboardSegue
public typealias ViewController = UIViewController
#elseif os(OSX)
import Cocoa
public typealias StoryboardSegue = NSStoryboardSegue
public typealias ViewController = NSWindowController
#endif

/**
    A protocol specific to the Lister sample that represents the segue identifier
    constraints in the app. Every view controller provides a segue identifier
    enum mapping. This protocol defines that structure.

    We also want to provide implementation to each view controller that conforms
    to this protocol that helps box / unbox the segue identifier strings to
    segue identifier enums. This is provided in an extension of `SegueHandlerType`.
*/
public protocol SegueHandlerType {
    /**
        Gives structure to what we expect the segue identifiers will be. We expect
        the `SegueIdentifier` mapping to be an enum case to `String` mapping.

        For example:

        enum SegueIdentifier: String {
            case ShowAccount
            case ShowHelp
            ...
        }
    */
    typealias SegueIdentifier: RawRepresentable
}

/**
    Constrain the implementation for `SegueHandlerType` conforming
    types to only work with view controller subclasses whose `SegueIdentifier`
    raw values are `String` instances. Practically speaking, the enum that provides
    the mapping between the view controller's segue identifier strings should
    be backed by a `String`. See the description for `SegueHandlerType` for an example.
*/
public extension SegueHandlerType where Self: ViewController, SegueIdentifier.RawValue == String {
    /**
        An overload of `UIViewController`'s `performSegueWithIdentifier(_:sender:)`
        method that takes in a `SegueIdentifier` enum parameter rather than a
        `String`.
    */
    func performSegueWithIdentifier(segueIdentifier: SegueIdentifier, sender: AnyObject?) {
        performSegueWithIdentifier(segueIdentifier.rawValue, sender: sender)
    }

    /**
        A convenience method to map a `StoryboardSegue` to the  segue identifier
        enum that it represents.
    */
    func segueIdentifierForSegue(segue: StoryboardSegue) -> SegueIdentifier {
        /*
            Map the segue identifier's string to an enum. It's a programmer error
            if a segue identifier string that's provided doesn't map to one of the
            raw representable values (most likely enum cases).
        */
        guard let identifier = segue.identifier,
                  segueIdentifier = SegueIdentifier(rawValue: identifier) else {
            fatalError("Couldn't handle segue identifier \(segue.identifier) for view controller of type \(self.dynamicType).")
        }

        return segueIdentifier
    }
}
