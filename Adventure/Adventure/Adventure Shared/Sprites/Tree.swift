/*
  Copyright (C) 2015 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  Defines the Tree sprite.
*/

import SpriteKit

final class Tree: ParallaxSprite, SharedAssetProvider {
    // MARK: Types
    
    struct Shared {
        // These templates will be populated when `loadSharedAssets()` is called on the class.
        static var smallTemplate: Tree!
        static var largeTemplate: Tree!
    }
    
    // MARK: Properties
    
    var fadeAlpha = false

    // MARK: NSCopying
    
    override func copyWithZone(zone: NSZone) -> AnyObject {
        var tree = super.copyWithZone(zone) as! Tree
        tree.fadeAlpha = fadeAlpha
        return tree
    }

    // MARK: Scene Processing Support

    func updateAlphaWithScene(scene: AdventureScene) {
        if !fadeAlpha {
            return
        }
        
        /*
            Players should be able to see through trees if any of the current heros is near enough to a tree.
            Therefore, iterate through all of the heroes and base the distance for adjusting the tree's alpha
            on the player closest to the tree.
        */
        let currentPosition = self.scene!.convertPoint(position, fromNode: parent!)
        let distance = scene.heroes.reduce(CGFloat.max) { minimumDistance, hero in
            let heroPosition = hero.scene!.convertPoint(hero.position, fromNode: hero.parent!)
            let distanceToHero = currentPosition.distanceToPoint(heroPosition)
            if distanceToHero < minimumDistance {
                return distanceToHero
            }
            
            return minimumDistance
        }

        alpha = alphaForDistance(distance)
    }

    func alphaForDistance(distance: CGFloat) -> CGFloat {
        let opaqueDistance: CGFloat = 400.0

        if distance > opaqueDistance {
            return 1.0
        } else {
            var multiplier = distance / opaqueDistance
            return 0.1 + multiplier * multiplier * 0.9
        }
    }
    
    // MARK: Asset Pre-loading
    
    class func loadSharedAssets() {
        // Load Trees
        let atlas = SKTextureAtlas(named: "Environment")
        var sprites = [
            SKSpriteNode(texture: atlas.textureNamed("small_tree_base.png")),
            SKSpriteNode(texture: atlas.textureNamed("small_tree_middle.png")),
            SKSpriteNode(texture: atlas.textureNamed("small_tree_top.png"))
        ]
        Shared.smallTemplate = Tree(sprites: sprites, usingOffset: 25.0)
        Shared.smallTemplate.name = "smallTree"
        
        sprites = [
            SKSpriteNode(texture: atlas.textureNamed("big_tree_base.png")),
            SKSpriteNode(texture: atlas.textureNamed("big_tree_middle.png")),
            SKSpriteNode(texture: atlas.textureNamed("big_tree_top.png"))
        ]
        Shared.largeTemplate = Tree(sprites: sprites, usingOffset: 150.0)
        Shared.largeTemplate.name = "bigTree"
        Shared.largeTemplate.fadeAlpha = true
    }
}
