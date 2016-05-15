/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An extension of `BaseScene` to enable it to respond to button presses.
*/

import Foundation

/// Extends `BaseScene` to respond to ButtonNode events.
extension BaseScene: ButtonNodeResponderType {
    
    /// Searches the scene for all `ButtonNode`s.
    func findAllButtonsInScene() -> [ButtonNode] {
        return ButtonIdentifier.allButtonIdentifiers.flatMap { buttonIdentifier in
            childNodeWithName("//\(buttonIdentifier.rawValue)") as? ButtonNode
        }
    }
    
    // MARK: ButtonNodeResponderType
    
    func buttonTriggered(button: ButtonNode) {
        switch button.buttonIdentifier! {
            case .Home:
                sceneManager.transitionToSceneWithSceneIdentifier(.Home)
            
            case .ProceedToNextScene:
                sceneManager.transitionToSceneWithSceneIdentifier(.NextLevel)
            
            case .Replay:
                sceneManager.transitionToSceneWithSceneIdentifier(.CurrentLevel)
            
            case .ScreenRecorderToggle:
                #if os(iOS)
                toggleScreenRecording(button)
                #endif
            
            case .ViewRecordedContent:
                #if os(iOS)
                displayRecordedContent()
                #endif
            
            default:
                fatalError("Unsupported ButtonNode type in Scene.")
        }
    }
}