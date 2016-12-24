/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `UIViewController` subclass that stores references to game-wide input sources and managers.
*/

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    // MARK: Properties
    
    let scene = GameScene(fileNamed: "GameScene")!
    
    // MARK: Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let skView = view as! SKView
        
        // Set the scale mode to scale to fit the window.
        scene.scaleMode = .aspectFit
        
        skView.presentScene(scene)
        
        // SpriteKit applies additional optimizations to improve rendering performance.
        skView.ignoresSiblingOrder = true
    }
    
    /**
        Detects taps. If a tap is detected, the the game
        advances by creating a new maze or solving the existing maze.
    */
    @IBAction func handleTap(_: AnyObject) {
        scene.createOrSolveMaze()
    }
}
