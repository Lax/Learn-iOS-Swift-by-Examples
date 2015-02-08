/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Useful structures for organizing and storing shared assets.
*/

import SpriteKit

// Allows adopters to advertise that they have shared assets that require loading and can load them.
protocol SharedAssetProvider {
    class func loadSharedAssets()
}

enum CharacterType {
    case Archer, Warrior, Cave, Goblin, Boss
}

// This function uses pattern matching to infer the appropriate enum value based on the type provided.
func inferCharacterType(fromType: Character.Type) -> CharacterType {
    switch fromType {
        case is Goblin.Type:
            return CharacterType.Goblin
        case is Cave.Type:
            return CharacterType.Cave
        case is Boss.Type:
            return CharacterType.Boss
        case is Warrior.Type:
            return CharacterType.Warrior
        case is Archer.Type:
            return CharacterType.Archer
        default:
            fatalError("Unknown type provided for \(__FUNCTION__).")
    }
}

// Holds shared animation textures for the various character types. Keys are provided for the inner dictionary.
struct SharedTextures {
    struct Keys {
        static var idle = "textures.idle"
        static var walk = "textures.walk"
        static var attack = "textures.attack"
        static var hit = "textures.hit"
        static var death = "textures.death"
    }
    
    static var textures = [CharacterType: [String: [SKTexture]]]()
}

// Holds shared sprites for the various character types. Keys are provided for the inner dictionary.
struct SharedSprites {
    struct Keys {
        static var projectile = "sprites.projectile"
        static var deathSplort = "sprites.deathSplort"
    }
    
    static var sprites = [CharacterType: [String: SKSpriteNode]]()
}

// Holds shared emitters for the various character types. Keys are provided for the inner dictionary.
struct SharedEmitters {
    struct Keys {
        static var damage = "emitters.damage"
        static var death = "emitters.death"
        static var projectile = "emitters.projectile"
    }
    
    static var emitters = [CharacterType: [String: SKEmitterNode]]()
}

// Holds shared actions for the various character types. Keys are provided for the inner dictionary.
struct SharedActions {
    struct Keys {
        static var damage = "actions.damage"
    }
    
    static var actions = [CharacterType: [String: SKAction]]()
}
