/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An enumeration that converts between rotations (in radians) and 16-point compass point orientations (with east as zero). Used when determining which animation to use for an entity's current orientation.
*/

import CoreGraphics

/// The different directions that an animated character can be facing.
enum CompassDirection: Int {
    case East = 0, EastByNorthEast, NorthEast, NorthByNorthEast
    case North, NorthByNorthWest, NorthWest, WestByNorthWest
    case West, WestBySouthWest, SouthWest, SouthBySouthWest
    case South, SouthBySouthEast, SouthEast, EastBySouthEast
    
    /// Convenience array of all available directions.
    static let allDirections: [CompassDirection] =
        [
            .East, .EastByNorthEast, .NorthEast, .NorthByNorthEast,
            .North, .NorthByNorthWest, .NorthWest, .WestByNorthWest,
            .West, .WestBySouthWest, .SouthWest, .SouthBySouthWest,
            .South, .SouthBySouthEast, .SouthEast, .EastBySouthEast
        ]
    
    /// The angle of rotation that the orientation represents.
    var zRotation: CGFloat {
        // Calculate the number of radians between each direction.
        let stepSize = CGFloat(M_PI * 2.0) / CGFloat(CompassDirection.allDirections.count)
        
        return CGFloat(self.rawValue) * stepSize
    }
    
    /// Creates a new `FacingDirection` for a given `zRotation` in radians.
    init(zRotation: CGFloat) {
        let twoPi = M_PI * 2
        
        // Normalize the node's rotation.
        let rotation = (Double(zRotation) + twoPi) % twoPi
        
        // Convert the rotation of the node to a percentage of a circle.
        let orientation = rotation / twoPi
        
        // Scale the percentage to a value between 0 and 15.
        let rawFacingValue = round(orientation * 16.0) % 16.0
        
        // Select the appropriate `CompassDirection` based on its members' raw values, which also run from 0 to 15.
        self = CompassDirection(rawValue: Int(rawFacingValue))!
    }
    
    init(string: String) {
        switch string {
            case "North":
                self = .North
                
            case "NorthEast":
                self = .NorthEast
                
            case "East":
                self = .East
                
            case "SouthEast":
                self = .SouthEast
                
            case "South":
                self = .South
                
            case "SouthWest":
                self = .SouthWest
                
            case "West":
                self = .West
                
            case "NorthWest":
                self = .NorthWest
                
            default:
                fatalError("Unknown or unsupported string - \(string)")
        }
    }
}
