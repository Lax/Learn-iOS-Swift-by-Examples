/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    These are the base protocol classes for dealing with elements in our document browser.
*/
import Foundation

/// The base protocol for all collection view objects to display in our UI.
protocol ModelObject: class {
    var displayName: String { get }
    
    var subtitle: String { get }
    
    var URL: NSURL { get }
}

/**
    Represents an animation as computed on the query's results set. Each animation 
    can add, remove, update or move a row.
*/
enum DocumentBrowserAnimation {
    case Reload
    case Delete(index: Int)
    case Add(index: Int)
    case Update(index: Int)
    case Move(fromIndex: Int, toIndex: Int)
}

/**
    We need to implement the `Equatable` protocol on our animation objects so we
    can match them later.
*/
extension DocumentBrowserAnimation: Equatable { }

func ==(lhs: DocumentBrowserAnimation, rhs: DocumentBrowserAnimation) -> Bool {
    switch (lhs, rhs) {
        case (.Reload, .Reload):
            return true
            
        case let (.Delete(left), .Delete(right)) where left == right:
            return true
            
        case let (.Add(left), .Add(right)) where left == right:
            return true
            
        case let (.Update(left), .Update(right)) where left == right:
            return true
            
        case let (.Move(leftFrom, leftTo), .Move(rightFrom, rightTo)) where leftFrom == rightFrom && leftTo == rightTo:
            return true
            
        default:
            return false
    }
}

/*
    We implement the `CustomDebugStringConvertible` protocol for pretty printing 
    purposes while debugging.
*/
extension DocumentBrowserAnimation: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
            case .Reload:
                return "Reload"
                
            case .Delete(let i):
                return "Delete(\(i))"
                
            case .Add(let i):
                return "Add(\(i))"
                
            case .Update(let i):
                return "Update(\(i))"
                
            case .Move(let f, let t):
                return "Move(\(f)->\(t))"
        }
    }
}
