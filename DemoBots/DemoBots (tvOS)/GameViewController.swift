/*
Copyright (C) 2016 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A `GCEventViewController` subclass that allows the user to exit the app via the menu button by setting `controllerUserInteractionEnabled` to `true` when transitioning to the `HomeEndScene`.
*/

import SpriteKit
import GameController

class GameViewController: GCEventViewController, SceneManagerDelegate {
    // MARK: Properties
    
    /// A manager for coordinating scene resources and presentation.
    var sceneManager: SceneManager!
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // `GameInput` will be updated with notifications from paired game controllers.
        let gameInput = GameInput()
        
        // Load the initial home scene.
        let skView = view as! SKView
        sceneManager = SceneManager(presentingView: skView, gameInput: gameInput)
        sceneManager.delegate = self
        
        sceneManager.transitionToScene(identifier: .home)
    }
    
    // MARK: SceneManagerDelegate
    
    func sceneManager(_ sceneManager: SceneManager, didTransitionTo scene: SKScene) {
        /*
            When transitioning to the `HomeEndScene` set
            `controllerUserInteractionEnabled` to `true` to allow the
            user to exit the app with the menu button. 
        
            Otherwise, setting `controllerUserInteractionEnabled` to false 
            will not direct game controller events through the UIEvent & UIResponder chain.
        
            @see GCEventViewController
        */
        controllerUserInteractionEnabled = (scene is HomeEndScene)
    }
}
