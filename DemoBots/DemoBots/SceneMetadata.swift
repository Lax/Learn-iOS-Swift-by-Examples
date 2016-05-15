/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A structure to encapsulate metadata about a scene in the game.
*/

import Foundation

/// Encapsulates the metadata about a scene in the game.
struct SceneMetadata {
    // MARK: Properties
    
    /// The base file name to use when loading the scene and related resources.
    let fileName: String
    
    /// The type to use when loading this scene (`HomeEndScene` or `LevelScene`).
    let sceneType: BaseScene.Type
    
    /// The list of types with resources that should be preloaded for this scene.
    let loadableTypes: [ResourceLoadableType.Type]
    
    /// All on demand resources tags that pertain to the scene.
    let onDemandResourcesTags: Set<String>
    
    /// A flag indicating whether the scene requires on demand resources to load.
    var requiresOnDemandResources: Bool {
        #if os(OSX)
        /*
            OS X does not use on demand resources, so resources will always be
            available on disk.
        */
        return false
        #else
        /*
            Check for on demand resources, not all scenes have resources that
            need to be downloaded.
        */
        return !onDemandResourcesTags.isEmpty
        #endif
    }
    
    // MARK: Initialization
    
    /// Initializes a new `SceneMetadata` instance from a dictionary.
    init(sceneConfiguration: [String: AnyObject]) {
        fileName = sceneConfiguration["fileName"] as! String
        
        let typeIdentifier = sceneConfiguration["sceneType"] as! String
        switch typeIdentifier {
            case "LevelScene":
                sceneType = LevelScene.self
            
            case "HomeEndScene":
                sceneType = HomeEndScene.self

            default:
                fatalError("Unidentified sceneType requested.")
        }
        
        var loadableTypesForScene = [ResourceLoadableType.Type]()
        
        // The on demand resource tags for the scene (if needed).
        if let tags = sceneConfiguration["onDemandResourcesTags"] as? [String] {
            onDemandResourcesTags = Set(tags)
            
            /*
                The tags are also used to determine which enemies need their resources
                to be preloaded for a `LevelScene`.
            */
            loadableTypesForScene += tags.flatMap { tag in
                switch tag {
                    case "GroundBot":
                        return GroundBot.self
                        
                    case "FlyingBot":
                        return FlyingBot.self
                        
                    default:
                        return nil
                }
            }
        }
        else {
            onDemandResourcesTags = []
        }
        
        /*
            We will always need the `PlayerBot` and the `BeamNode` 
            if the scene is a `LevelScene`, so add these `ResourceLoadableType`s 
            by default.
        */
        if sceneType == LevelScene.self {
            loadableTypesForScene = loadableTypesForScene + [PlayerBot.self, BeamNode.self]
        }
        
        // Set up the `loadableTypes` to be prepared when the scene is requested.
        loadableTypes = loadableTypesForScene
    }
}

// MARK: Hashable

/*
    Extend `SceneMetadata` to conform to the `Hashable` protocol so that it may be
    used as a dictionary key by `SceneManger`.
*/
extension SceneMetadata: Hashable {
    var hashValue: Int {
        return fileName.hashValue
    }
}

/*
    In order to be `Hashable`, `SceneMetadata` must also be `Equatable`.
    This requirement is satisfied by providing an equality operator function
    that takes two `SceneMetadata` instances and determines if they are equal.
*/
func ==(lhs: SceneMetadata, rhs: SceneMetadata)-> Bool {
    return lhs.hashValue == rhs.hashValue
}