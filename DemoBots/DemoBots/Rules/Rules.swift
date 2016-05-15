/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This file introduces the rules used by the `TaskBot` rule system to determine an appropriate action for the `TaskBot`. The rules fall into three distinct sets:
                Percentage of bad `TaskBot`s in the level (low, medium, high):
                    `BadTaskBotPercentageLowRule`
                    `BadTaskBotPercentageMediumRule`
                    `BadTaskBotPercentageHighRule`
                How close the `TaskBot` is to the `PlayerBot` (near, medium, far):
                    `PlayerBotNearRule`
                    `PlayerBotMediumRule`
                    `PlayerBotFarRule`
                How close the `TaskBot` is to its nearest "good" `TaskBot` (near, medium, far):
                    `TaskBotNearRule`
                    `TaskBotMediumRule`
                    `TaskBotFarRule`
*/

import GameplayKit

enum Fact: String {
    // Fuzzy rules pertaining to the proportion of "bad" bots in the level.
    case BadTaskBotPercentageLow = "BadTaskBotPercentageLow"
    case BadTaskBotPercentageMedium = "BadTaskBotPercentageMedium"
    case BadTaskBotPercentageHigh = "BadTaskBotPercentageHigh"

    // Fuzzy rules pertaining to this `TaskBot`'s proximity to the `PlayerBot`.
    case PlayerBotNear = "PlayerBotNear"
    case PlayerBotMedium = "PlayerBotMedium"
    case PlayerBotFar = "PlayerBotFar"

    // Fuzzy rules pertaining to this `TaskBot`'s proximity to the nearest "good" `TaskBot`.
    case GoodTaskBotNear = "GoodTaskBotNear"
    case GoodTaskBotMedium = "GoodTaskBotMedium"
    case GoodTaskBotFar = "GoodTaskBotFar"
}

/// Asserts whether the number of "bad" `TaskBot`s is considered "low".
class BadTaskBotPercentageLowRule: FuzzyTaskBotRule {
    // MARK: Properties
    
    override func grade() -> Float {
        return max(0.0, 1.0 - 3.0 * snapshot.badBotPercentage)
    }
    
    // MARK: Initializers
    
    init() { super.init(fact: .BadTaskBotPercentageLow) }
}

/// Asserts whether the number of "bad" `TaskBot`s is considered "medium".
class BadTaskBotPercentageMediumRule: FuzzyTaskBotRule {
    // MARK: Properties
    
    override func grade() -> Float {
        if snapshot.badBotPercentage <= 1.0 / 3.0 {
            return min(1.0, 3.0 * snapshot.badBotPercentage)
        }
        else {
            return max(0.0, 1.0 - (3.0 * snapshot.badBotPercentage - 1.0))
        }
    }
    
    // MARK: Initializers
    
    init() { super.init(fact: .BadTaskBotPercentageMedium) }
}

/// Asserts whether the number of "bad" `TaskBot`s is considered "high".
class BadTaskBotPercentageHighRule: FuzzyTaskBotRule {
    // MARK: Properties
    
    override func grade() -> Float {
        return min(1.0, max(0.0, (3.0 * snapshot.badBotPercentage - 1)))
    }
    
    // MARK: Initializers
    
    init() { super.init(fact: .BadTaskBotPercentageHigh) }
}

/// Asserts whether the `PlayerBot` is considered to be "near" to this `TaskBot`.
class PlayerBotNearRule: FuzzyTaskBotRule {
    // MARK: Properties

    override func grade() -> Float {
        guard let distance = snapshot.playerBotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return (oneThird - distance) / oneThird
    }

    // MARK: Initializers
    
    init() { super.init(fact: .PlayerBotNear) }
}

/// Asserts whether the `PlayerBot` is considered to be at a "medium" distance from this `TaskBot`.
class PlayerBotMediumRule: FuzzyTaskBotRule {
    // MARK: Properties

    override func grade() -> Float {
        guard let distance = snapshot.playerBotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return 1 - (fabs(distance - oneThird) / oneThird)
    }
    
    // MARK: Initializers
    
    init() { super.init(fact: .PlayerBotMedium) }
}

/// Asserts whether the `PlayerBot` is considered to be "far" from this `TaskBot`.
class PlayerBotFarRule: FuzzyTaskBotRule {
    // MARK: Properties
    
    override func grade() -> Float {
        guard let distance = snapshot.playerBotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return (distance - oneThird) / oneThird
    }
    
    // MARK: Initializers
    
    init() { super.init(fact: .PlayerBotFar) }
}

// MARK: TaskBot Proximity Rules

/// Asserts whether the nearest "good" `TaskBot` is considered to be "near" to this `TaskBot`.
class GoodTaskBotNearRule: FuzzyTaskBotRule {
    // MARK: Properties

    override func grade() -> Float {
        guard let distance = snapshot.nearestGoodTaskBotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return (oneThird - distance) / oneThird
    }

    // MARK: Initializers
    
    init() { super.init(fact: .GoodTaskBotNear) }
}

/// Asserts whether the nearest "good" `TaskBot` is considered to be at a "medium" distance from this `TaskBot`.
class GoodTaskBotMediumRule: FuzzyTaskBotRule {
    // MARK: Properties
    
    override func grade() -> Float {
        guard let distance = snapshot.nearestGoodTaskBotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return 1 - (fabs(distance - oneThird) / oneThird)
    }

    // MARK: Initializers
    
    init() { super.init(fact: .GoodTaskBotMedium) }
}

/// Asserts whether the nearest "good" `TaskBot` is considered to be "far" from this `TaskBot`.
class GoodTaskBotFarRule: FuzzyTaskBotRule {
    // MARK: Properties
    
    override func grade() -> Float {
        guard let distance = snapshot.nearestGoodTaskBotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return (distance - oneThird) / oneThird
    }
    
    // MARK: Initializers
    
    init() { super.init(fact: .GoodTaskBotFar) }
}
