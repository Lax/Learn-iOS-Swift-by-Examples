/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `GKComponent` and associated delegate that manage and respond to a `GKRuleSystem` for an entity.
*/

import GameplayKit

protocol RulesComponentDelegate: class {
    // Called whenever the rules component finishes evaluating its rules.
    func rulesComponent(rulesComponent: RulesComponent, didFinishEvaluatingRuleSystem ruleSystem: GKRuleSystem)
}

class RulesComponent: GKComponent {
    // MARK: Properties
    
    weak var delegate: RulesComponentDelegate?
    
    var ruleSystem: GKRuleSystem
    
    /// The amount of time that has passed since the `TaskBot` last evaluated its rules.
    private var timeSinceRulesUpdate: NSTimeInterval = 0.0
    
    // MARK: Initializers
    
    override init() {
        ruleSystem = GKRuleSystem()
    }
    
    init(rules: [GKRule]) {
        ruleSystem = GKRuleSystem()
        ruleSystem.addRulesFromArray(rules)
    }
    
    // MARK: GKComponent Life Cycle
    
    override func updateWithDeltaTime(seconds: NSTimeInterval) {
        timeSinceRulesUpdate += seconds
        
        if timeSinceRulesUpdate < GameplayConfiguration.TaskBot.rulesUpdateWaitDuration { return }
        
        timeSinceRulesUpdate = 0.0
        
        if let taskBot = entity as? TaskBot,
            level = taskBot.componentForClass(RenderComponent)?.node.scene as? LevelScene,
            entitySnapshot = level.entitySnapshotForEntity(taskBot) where !taskBot.isGood {

            ruleSystem.reset()
            
            ruleSystem.state["snapshot"] = entitySnapshot
        
            ruleSystem.evaluate()
            
            delegate?.rulesComponent(self, didFinishEvaluatingRuleSystem: ruleSystem)
        }
    }
}
