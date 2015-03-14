/*
  Copyright (C) 2015 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  Defines AI for spawning new goblins.
*/

import SpriteKit

class SpawnArtificialIntelligence: ArtificialIntelligence {
    // MARK: Properties
    
    var cave: Cave {
        return character as! Cave
    }
    
    // MARK: Scene Processing Support

    override func updateWithTimeSinceLastUpdate(timeInterval: NSTimeInterval) {
        // If the cave is destroyed, no need to do anything!
        if cave.health <= 0.0 {
            return
        }

        var timeUntilNextGenerate: CGFloat = 0
        if shouldGenerateGoblin(&timeUntilNextGenerate) {
            cave.generate()
            cave.timeUntilNextGenerate = timeUntilNextGenerate
        }
        else {
            // We aren't generating in this loop, so we just decrease the time until next generation.
            cave.timeUntilNextGenerate -= CGFloat(timeInterval)
        }
    }
    
    // MARK: Internal Scene Processing Implementation
    
    // Determines whether or not goblins should be generated based on the current state
    // of the cave, its goblins, and the hero.
    func shouldGenerateGoblin(inout timeUntilNextGenerate: CGFloat) -> Bool {
        // If there are no active goblins, create one!
        if cave.activeGoblins.isEmpty {
            timeUntilNextGenerate = 4.0

            return true
        }
        
        if shouldGenerateGoblinBasedOnTimeSinceLastGeneration() {
            timeUntilNextGenerate = 4.0
            return true
        }
        
        if shouldGenerateGoblinBasedOnCaveDistanceToHero(&timeUntilNextGenerate) {
            return true
        }
        
        return false
    }
    
    func shouldGenerateGoblinBasedOnTimeSinceLastGeneration() -> Bool {
        return cave.timeUntilNextGenerate <= 0 && cave.activeGoblins.count < 5
    }
    
    func shouldGenerateGoblinBasedOnCaveDistanceToHero(inout timeUntilNextGenerate: CGFloat) -> Bool {
        let scene = cave.characterScene
        
        // Maximum hero distance
        var nearestHeroDistance = CGFloat(AdventureScene.Constants.worldSize)
        var nearestHeroPosition: CGPoint?
        
        let cavePosition = scene.convertPoint(cave.position, fromNode: cave.parent!)
        
        for hero in scene.heroes {
            let heroPosition = scene.convertPoint(hero.position, fromNode: hero.parent!)
            let distance = cavePosition.distanceToPoint(heroPosition)
            
            if distance < nearestHeroDistance {
                nearestHeroDistance = distance
                nearestHeroPosition = heroPosition
            }
        }
        
        if let nearestHeroPosition = nearestHeroPosition {
            let distanceScale = nearestHeroDistance / CGFloat(AdventureScene.Constants.worldSize)
            
            if cave.activeGoblins.count < 5 && distanceScale < 0.24 &&
               cave.timeUntilNextGenerate > 0 && scene.canSee(nearestHeroPosition, from: cavePosition) {
                // Decrease the time until next generation based on the proximity of the hero.
                timeUntilNextGenerate = distanceScale * 4
                
                return true
            }
        }
        
        return false
    }
}
