/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the Shape View which handles displaying / user interaction when editing an individual shape document.
*/

import UIKit
import SceneKit

/**
    The `ShapeView` class interceps touch events so we know when the document has 
    been edited so we should save the changes to disk.
*/
class ShapeView: SCNView {
    // MARK: Properties

    var document: ShapeDocument? {
        didSet {
            guard let document = document else { return }

            document.setSceneOnRenderer(self)
            
            self.backgroundColor = document.backgroundColor
        }
    }

    // MARK: Initialization
    
    override func awakeFromNib() {
        autoenablesDefaultLighting = true
        allowsCameraControl = true
    }

    // MARK: Override

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /*
            The user finished interacting with the shape for now, so notify the
            document that changes happened so that it writes the new document
            state to disk.
        */
        guard let pointOfView = pointOfView else { return }

        document?.updateCameraState(pointOfView)
    }
}
