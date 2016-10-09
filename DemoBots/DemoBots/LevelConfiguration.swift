/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A structure that encapsulates the initial configuration of a level in the game, including the initial states and positions of `TaskBot`s. This information is loaded from a property list.
*/

import Foundation

/// Encapsulates the starting configuration of a level in the game.
struct LevelConfiguration {
    // MARK: Types
    
    /// Encapsulates the starting configuration of a single `GroundBot` or `FlyingBot`.
    struct TaskBotConfiguration {
        // MARK: Properties

        /// The different types of `TaskBot` that can exist in a level.
        enum Locomotion {
            case ground
            case flying
        }
        
        let locomotion: Locomotion
        
        /// The initial orientation of this `TaskBot` when the level is first loaded.
        let initialOrientation: CompassDirection
        
        /// The names of the nodes for this `TaskBot`'s patrol path when it is "good" and not hunting.
        let goodPathNodeNames: [String]

        /// The names of the nodes for this `TaskBot`'s patrol path when it is "bad" and not hunting.
        let badPathNodeNames: [String]
        
        /// Whether the bot should be in its "bad" state when the level begins.
        let startsBad: Bool
        
        // MARK: Initialization

        init(botConfigurationInfo: [String: AnyObject]) {
            switch botConfigurationInfo["locomotion"] as! String {
                case "ground":
                    locomotion = .ground
                    
                case "flying":
                    locomotion = .flying
                    
                default:
                    fatalError("Unknown locomotion found while parsing `taskBot` data")
            }
            
            initialOrientation = CompassDirection(string: botConfigurationInfo["initialOrientation"] as! String)
            goodPathNodeNames = botConfigurationInfo["goodPathNodeNames"] as! [String]
            badPathNodeNames = botConfigurationInfo["badPathNodeNames"] as! [String]
            startsBad = botConfigurationInfo["startsBad"] as! Bool
        }

    }
    
    // MARK: Properties
    
    /// Cached data loaded from the level's data file.
    private let configurationInfo: [String: AnyObject]
    
    /// The initial orientation of the `PlayerBot` when the level is first loaded.
    let initialPlayerBotOrientation: CompassDirection

    /// The configuration settings for `TaskBots` on this level.
    let taskBotConfigurations: [TaskBotConfiguration]
    
    /// The file name identifier for this level. Used for loading files and assets.
    let fileName: String
    
    /**
        Returns the name of the next level, if any. The final level doesn't have a
        next level name, so this property is optional.
    */
    var nextLevelName: String? {
        return configurationInfo["nextLevel"] as! String?
    }
    
    /// The time limit (in seconds) for this level.
    var timeLimit: TimeInterval {
        return configurationInfo["timeLimit"] as! TimeInterval
    }
    
    /// The factor used to normalize distances between characters for 'fuzzy' logic.
    var proximityFactor: Float {
        return configurationInfo["proximityFactor"] as! Float
    }

    // MARK: Initialization

    init(fileName: String) {
        self.fileName = fileName
        
        let url = Bundle.main.url(forResource: fileName, withExtension: "plist")

        configurationInfo = NSDictionary(contentsOf: url!) as! [String: AnyObject]
        
        // Extract the data for every `TaskBot` in this level as an array of `TaskBotConfiguration` values.
        let botConfigurations = configurationInfo["taskBotConfigurations"] as! [[String: AnyObject]]
        
        // Map the array of `TaskBot` configuration dictionaries to an array of `TaskBotConfiguration` instances.
        taskBotConfigurations = botConfigurations.map { TaskBotConfiguration(botConfigurationInfo: $0) }
        
        initialPlayerBotOrientation = CompassDirection(string: configurationInfo["initialPlayerBotOrientation"] as! String)
    }
}
