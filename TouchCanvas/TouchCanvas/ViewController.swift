/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The primary view controller that hosts a `CanvasView` for the user to interact with.
 */

import UIKit

class ViewController: UIViewController {
    // MARK: Properties

    var visualizeAzimuth = false

    let reticleView: ReticleView = {
        let view = ReticleView(frame: CGRect.null)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true

        return view
    }()

    var canvasView: CanvasView {
        return view as! CanvasView
    }

    // MARK: View Life Cycle

    override func viewDidLoad() {
        canvasView.addSubview(reticleView)
    }

    // MARK: Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        canvasView.drawTouches(touches: touches, withEvent: event)

        if visualizeAzimuth {
            for touch in touches {
                if touch.type == .stylus {
                    reticleView.isHidden = false
                    updateReticleViewWithTouch(touch: touch, event: event)
                }
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        canvasView.drawTouches(touches: touches, withEvent: event)

        if visualizeAzimuth {
            for touch in touches {
                if touch.type == .stylus {
                    updateReticleViewWithTouch(touch: touch, event: event)

                    // Use the last predicted touch to update the reticle.
                    guard let predictedTouch = event?.predictedTouches(for: touch)?.last else { return }

                    updateReticleViewWithTouch(touch: predictedTouch, event: event, isPredicted: true)
                }
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        canvasView.drawTouches(touches: touches, withEvent: event)
        canvasView.endTouches(touches: touches, cancel: false)

        if visualizeAzimuth {
            for touch in touches {
                if touch.type == .stylus {
                    reticleView.isHidden = true
                }
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        canvasView.endTouches(touches: touches, cancel: true)

        if visualizeAzimuth {
            for touch in touches {
                if touch.type == .stylus {
                    reticleView.isHidden = true
                }
            }
        }
    }

    override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {
        canvasView.updateEstimatedPropertiesForTouches(touches: touches)
    }

    // MARK: Actions

    @IBAction func clearView(sender: UIBarButtonItem) {
        canvasView.clear()
    }

    @IBAction func toggleDebugDrawing(sender: UIButton) {
        canvasView.isDebuggingEnabled = !canvasView.isDebuggingEnabled
        visualizeAzimuth = !visualizeAzimuth
        sender.isSelected = canvasView.isDebuggingEnabled
    }

    @IBAction func toggleUsePreciseLocations(sender: UIButton) {
        canvasView.usePreciseLocations = !canvasView.usePreciseLocations
        sender.isSelected = canvasView.usePreciseLocations
    }

    // MARK: Rotation

    override var shouldAutorotate: Bool {
        get { return true }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get { return [.landscapeLeft, .landscapeRight] }
    }


    // MARK: Convenience

    func updateReticleViewWithTouch(touch: UITouch?, event: UIEvent?, isPredicted: Bool = false) {
        guard let touch = touch, touch.type == .stylus else { return }

        reticleView.predictedDotLayer.isHidden = !isPredicted
        reticleView.predictedLineLayer.isHidden = !isPredicted

        let azimuthAngle = touch.azimuthAngle(in: view)
        let azimuthUnitVector = touch.azimuthUnitVector(in: view)
        let altitudeAngle = touch.altitudeAngle

        if isPredicted {
            reticleView.predictedAzimuthAngle = azimuthAngle
            reticleView.predictedAzimuthUnitVector = azimuthUnitVector
            reticleView.predictedAltitudeAngle = altitudeAngle
        }
        else {
            let location = touch.preciseLocation(in: view)
            reticleView.center = location
            reticleView.actualAzimuthAngle = azimuthAngle
            reticleView.actualAzimuthUnitVector = azimuthUnitVector
            reticleView.actualAltitudeAngle = altitudeAngle
        }
    }
}

