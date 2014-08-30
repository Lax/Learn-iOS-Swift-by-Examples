/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines AI for spawning new goblins.
      
*/

import SpriteKit

class SpawnAI: ArtificialIntelligence {
    init(character: Character, target: Character?) {
        super.init(character: character, target: target)
    }

    // loop Update
    override func updateWithTimeSinceLastUpdate(interval: NSTimeInterval) {
        let cave = character as Cave

        if cave.health <= 0.0 {
            return
        }

        let scene = cave.characterScene

        // minimum hero distance
        var nearestHeroDistance: CGFloat = 2048.0
        var nearestHeroPosition = CGPointZero

        let cavePosition = cave.position

        for hero in scene.heroes {
            var heroPosition = hero.position
            var distance = cavePosition.distanceTo(heroPosition)
            if distance < nearestHeroDistance {
                nearestHeroDistance = distance
                nearestHeroPosition = heroPosition
            }
        }

        var distScale = nearestHeroDistance / nearestHeroDistance

        // generate goblins more quickly if the closest hero is getting closer.
        cave.timeUntilNextGenerate -= CGFloat(interval)

        // either time to generate or the hero is so close we need to respond ASAP!
        var goblinCount = cave.activeGoblins.count

        if (goblinCount < 1 || cave.timeUntilNextGenerate <= 0.0 || (distScale < 0.35 && cave.timeUntilNextGenerate > 5.0)) {
            if goblinCount < 1 || (goblinCount < 4 && nearestHeroPosition != CGPointZero &&
               scene.canSee(nearestHeroPosition, from: cavePosition)) {
                cave.generate()
            }
        }
    }
}
