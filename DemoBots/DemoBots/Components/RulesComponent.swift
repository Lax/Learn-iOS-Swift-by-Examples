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
    private var timeSinceRulesUpdate: TimeInterval = 0.0
    
    // MARK: Initializers
    
    override init() {
        ruleSystem = GKRuleSystem()
        super.init()
    }
    
    init(rules: [GKRule]) {
        ruleSystem = GKRuleSystem()
        ruleSystem.add(rules)
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: GKComponent Life Cycle
    
    override func update(deltaTime seconds: TimeInterval) {
        timeSinceRulesUpdate += seconds
        
        if timeSinceRulesUpdate < GameplayConfiguration.TaskBot.rulesUpdateWaitDuration { return }
        
        timeSinceRulesUpdate = 0.0
        
        if let taskBot = entity as? TaskBot,
            let level = taskBot.component(ofType: RenderComponent.self)?.node.scene as? LevelScene,
            let entitySnapshot = level.entitySnapshotForEntity(entity: taskBot),
            !taskBot.isGood {

            ruleSystem.reset()
            
            ruleSystem.state["snapshot"] = entitySnapshot
        
            ruleSystem.evaluate()
            
            delegate?.rulesComponent(rulesComponent: self, didFinishEvaluatingRuleSystem: ruleSystem)
        }
    }
}
