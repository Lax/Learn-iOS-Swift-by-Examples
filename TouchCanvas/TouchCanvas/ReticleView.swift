/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The `ReticleView` allows visualization of the azimuth and altitude related properties of a `UITouch` via an indicator similar to the sighting devices such as a telescope.
 */

import UIKit

class ReticleView: UIView {
    // MARK: Properties

    var actualAzimuthAngle: CGFloat = 0.0 {
        didSet {
            setNeedsLayout()
        }
    }
    var actualAzimuthUnitVector = CGVector(dx: 0, dy: 0) {
        didSet {
            setNeedsLayout()
        }
    }
    var actualAltitudeAngle: CGFloat = 0.0 {
        didSet {
            setNeedsLayout()
        }
    }

    var predictedAzimuthAngle: CGFloat = 0.0 {
        didSet {
            setNeedsLayout()
        }
    }
    var predictedAzimuthUnitVector = CGVector(dx: 0, dy: 0) {
        didSet {
            setNeedsLayout()
        }
    }
    var predictedAltitudeAngle: CGFloat = 0.0 {
        didSet {
            setNeedsLayout()
        }
    }

    let reticleLayer = CALayer()
    let radius: CGFloat = 80
    var reticleImage: UIImage!
    let reticleColor = UIColor(hue: 0.516, saturation: 0.38, brightness: 0.85, alpha: 0.4)

    let dotRadius: CGFloat = 8
    let lineWidth: CGFloat = 2

    var predictedDotLayer = CALayer()
    var predictedLineLayer = CALayer()
    let predictedIndicatorColor = UIColor(hue: 0.53, saturation: 0.86, brightness: 0.91, alpha: 1.0)

    var dotLayer = CALayer()
    var lineLayer = CALayer()
    let indicatorColor = UIColor(hue: 0.0, saturation: 0.86, brightness: 0.91, alpha: 1.0)

    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        // Set the contentScaleFactor.
        contentScaleFactor = UIScreen.main.scale

        reticleLayer.contentsGravity = kCAGravityCenter
        reticleLayer.position = layer.position
        layer.addSublayer(reticleLayer)

        configureDotLayer(layer: predictedDotLayer, withColor: predictedIndicatorColor)
        predictedDotLayer.isHidden = true
        configureLineLayer(layer: predictedLineLayer, withColor: predictedIndicatorColor)
        predictedLineLayer.isHidden = true

        configureDotLayer(layer: dotLayer, withColor: indicatorColor)
        configureLineLayer(layer: lineLayer, withColor: indicatorColor)

        reticleLayer.addSublayer(predictedDotLayer)
        reticleLayer.addSublayer(predictedLineLayer)
        reticleLayer.addSublayer(dotLayer)
        reticleLayer.addSublayer(lineLayer)

        renderReticleImage()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UIView Overrides

    override var intrinsicContentSize: CGSize {
        get { return reticleImage.size }

    }

    override func layoutSubviews() {
        super.layoutSubviews()

        CATransaction.setDisableActions(true)

        reticleLayer.position = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
        layoutIndicator()

        CATransaction.setDisableActions(false)
    }

    // MARK: Convenience

    func renderReticleImage() {
        let imageRadius = ceil(radius * 1.2)
        let imageSize = CGSize(width: imageRadius * 2, height: imageRadius * 2)
        UIGraphicsBeginImageContextWithOptions(imageSize, false, contentScaleFactor)
        let ctx: CGContext = UIGraphicsGetCurrentContext()!
        ctx.translateBy(x:imageRadius, y:imageRadius)
        ctx.setLineWidth(2.0)
        ctx.setStrokeColor(reticleColor.cgColor)
        ctx.strokeEllipse(in: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2))

        // Draw targeting lines.
        let path = CGMutablePath.init()
        var transform = CGAffineTransform.identity


        for _ in 0..<4 {
            path.move(to: CGPoint(x: radius * 0.5, y: 0), transform: transform)
            path.addLine(to: CGPoint(x: radius * 1.15, y: 0), transform: transform)
            transform = transform.rotated(by: CGFloat.pi)
        }
        ctx.addPath(path)
        ctx.strokePath()

        reticleImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        reticleLayer.contents = reticleImage.cgImage
        reticleLayer.bounds = CGRect(x: 0, y: 0, width: imageRadius * 2, height: imageRadius * 2)
        reticleLayer.contentsScale = contentScaleFactor
    }

    func layoutIndicator() {
        // Predicted.
        layoutIndicatorForAzimuthAngle(azimuthAngle: predictedAzimuthAngle, azimuthUnitVector: predictedAzimuthUnitVector, altitudeAngle: predictedAltitudeAngle, lineLayer: predictedLineLayer, dotLayer: predictedDotLayer)

        // Actual.
        layoutIndicatorForAzimuthAngle(azimuthAngle: actualAzimuthAngle, azimuthUnitVector: actualAzimuthUnitVector, altitudeAngle: actualAltitudeAngle, lineLayer: lineLayer, dotLayer: dotLayer)
    }

    func layoutIndicatorForAzimuthAngle(azimuthAngle: CGFloat, azimuthUnitVector: CGVector, altitudeAngle: CGFloat, lineLayer targetLineLayer: CALayer, dotLayer targetDotLayer: CALayer) {
        let reticleBounds = reticleLayer.bounds

        let centeringTransform = CGAffineTransform.init(translationX: reticleBounds.width / 2, y:reticleBounds.height / 2)

        var rotationTransform = CGAffineTransform.init(rotationAngle:azimuthAngle)

        // Draw the indicator opposite the azimuth by rotating pi radians, for easy visualization.
        rotationTransform = rotationTransform.rotated(by: CGFloat.pi)

        /*
         Make the length of the indicator's line representative of the `altitudeAngle`. When the angle is
         zero radians (parallel to the screen surface) the line will be at its longest. At `M_PI`/2 radians,
         only the dot on top of the indicator will be visible directly beneath the touch location.
         */
        let altitudeRadius = (1.0 - altitudeAngle / CGFloat.pi) * radius

        var lineTransform = CGAffineTransform.init(scaleX: altitudeRadius, y: 1)
        lineTransform = lineTransform.concatenating(rotationTransform)
        lineTransform = lineTransform.concatenating(centeringTransform)
        targetLineLayer.setAffineTransform(lineTransform)

        var dotTransform = CGAffineTransform.init(translationX: -azimuthUnitVector.dx * altitudeRadius, y: -azimuthUnitVector.dy * altitudeRadius)
        dotTransform = dotTransform.concatenating(centeringTransform)

        targetDotLayer.setAffineTransform(dotTransform)
    }

    func configureDotLayer(layer targetLayer: CALayer, withColor color: UIColor) {
        targetLayer.backgroundColor = color.cgColor
        targetLayer.bounds = CGRect(x: 0, y: 0, width: dotRadius * 2, height: dotRadius * 2)
        targetLayer.cornerRadius = dotRadius
        targetLayer.position = CGPoint.zero
    }

    func configureLineLayer(layer targetLayer: CALayer, withColor color: UIColor) {
        targetLayer.backgroundColor = color.cgColor
        targetLayer.bounds = CGRect(x: 0, y: 0, width: 1, height: lineWidth)
        targetLayer.anchorPoint = CGPoint(x: 0, y: 0.5)
        targetLayer.position = CGPoint.zero
    }
}

