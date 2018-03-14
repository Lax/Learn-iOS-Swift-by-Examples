/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The `SKNode` based menu.
 */

import SpriteKit

protocol MenuDelegate: NSObjectProtocol {
    
    func fStopChanged(_ value: CGFloat)
    func focusDistanceChanged(_ value: CGFloat)
    func debugMenuSelectCameraAtIndex(_ index: Int)
}

class Menu: SKNode {
    weak var delegate: MenuDelegate?

    var cameraButtons = [Button]()
    var dofSliders = [Slider]()
    var isMenuHidden: Bool = false
    
    let buttonMargin = CGFloat(250)
    let menuY = CGFloat(40)
    let duration = 0.3
    
    init(size: CGSize) {
        super.init()
        
        // Track mouse event
        isUserInteractionEnabled = true
        
        // Camera buttons
        do {
            let buttonLabels = ["Camera 1", "Camera 2", "Camera 3"]
            cameraButtons = buttonLabels.map { return Button(text:$0) }
            
            for (i, button) in cameraButtons.enumerated() {
                let x: CGFloat = button.width / 2 + (i > 0 ? cameraButtons[i - 1].position.x + cameraButtons[i - 1].width / 2 + 10: buttonMargin)
                let y: CGFloat = size.height - menuY
                button.position = CGPoint(x: x, y: y)
                button.setClickedTarget(self, action: #selector(self.menuChanged))
                addChild(button)
            }
        }
        // Depth of Field
        do {
            let buttonLabels = ["fStop", "Focus"]
            dofSliders = buttonLabels.map { return Slider(width: 300, height: 10, text:$0) }
            
            for (i, slider) in dofSliders.enumerated() {
                slider.position = CGPoint(x: buttonMargin, y: CGFloat(size.height - CGFloat(i) * 30.0 - 70.0))
                slider.alpha = 0.0
                self.addChild(slider)
            }
            dofSliders[0].setClickedTarget(self, action: #selector(self.cameraFStopChanged))
            dofSliders[1].setClickedTarget(self, action: #selector(self.cameraFocusDistanceChanged))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func menuChanged(_ sender: Any) {
        hideSlidersMenu()
        if let index = cameraButtons.index(of: sender as! Button) {
            self.delegate?.debugMenuSelectCameraAtIndex(index)
            if index == 2 {
                showSlidersMenu()
            }
        }
    }
    
    override var isHidden: Bool {
        get {
            return isMenuHidden
        }
        set {
            if newValue {
                hide()
            } else {
                show()
            }
        }
    }
    
    func show() {
        for button in cameraButtons {
            button.alpha = 0.0
            button.run(SKAction.fadeIn(withDuration: duration))
        }
        isMenuHidden = false
    }
    
    func hide() {
        for button in cameraButtons {
            button.alpha = 1.0
            button.run(SKAction.fadeOut(withDuration: duration))
        }
        hideSlidersMenu()
        isMenuHidden = true
    }

    func hideSlidersMenu() {
        for slider in dofSliders {
            slider.run(SKAction.fadeOut(withDuration: duration))
        }
    }

    func showSlidersMenu() {
        for slider in dofSliders {
            slider.run(SKAction.fadeIn(withDuration: duration))
        }
        dofSliders[0].value = 0.1
        dofSliders[1].value = 0.5
        perform(#selector(self.cameraFStopChanged), with: dofSliders[0])
        perform(#selector(self.cameraFocusDistanceChanged), with: dofSliders[1])
    }

    @IBAction func cameraFStopChanged(_ sender: Any) {
        if let method = delegate?.fStopChanged {
            method(dofSliders[0].value + 0.2)
        }
    }

    @IBAction func cameraFocusDistanceChanged(_ sender: Any) {
        if let method = delegate?.focusDistanceChanged {
            method(dofSliders[1].value * 20.0 + 3.0)
        }
    }
}

