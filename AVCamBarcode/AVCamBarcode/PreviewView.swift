/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
Application preview view.
*/

import UIKit
import AVFoundation

class PreviewView: UIView, UIGestureRecognizerDelegate {
	// MARK: Types
	private enum ControlCorner {
		case none
		case topLeft
		case topRight
		case bottomLeft
		case bottomRight
	}
	
	// MARK: Initialization
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		commonInit()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		commonInit()
	}
	
	private func commonInit() {
		maskLayer.fillRule = kCAFillRuleEvenOdd
		maskLayer.fillColor = UIColor.black.cgColor
		maskLayer.opacity = 0.6
		layer.addSublayer(maskLayer)
		
		regionOfInterestOutline.path = UIBezierPath(rect: regionOfInterest).cgPath
		regionOfInterestOutline.fillColor = UIColor.clear.cgColor
		regionOfInterestOutline.strokeColor = UIColor.yellow.cgColor
		layer.addSublayer(regionOfInterestOutline)
		
		let controlRect = CGRect(x: 0, y: 0, width: regionOfInterestControlDiameter, height: regionOfInterestControlDiameter)
		
		topLeftControl.path = UIBezierPath(ovalIn: controlRect).cgPath
		topLeftControl.fillColor = UIColor.white.cgColor
		layer.addSublayer(topLeftControl)
		
		topRightControl.path = UIBezierPath(ovalIn: controlRect).cgPath
		topRightControl.fillColor = UIColor.white.cgColor
		layer.addSublayer(topRightControl)
		
		bottomLeftControl.path = UIBezierPath(ovalIn: controlRect).cgPath
		bottomLeftControl.fillColor = UIColor.white.cgColor
		layer.addSublayer(bottomLeftControl)
		
		bottomRightControl.path = UIBezierPath(ovalIn: controlRect).cgPath
		bottomRightControl.fillColor = UIColor.white.cgColor
		layer.addSublayer(bottomRightControl)
		
		/*
			Add the region of interest gesture recognizer to the region of interest
			view so that the region of interest can be resized and moved. If you
			would like to have a fixed region of interest that cannot be resized
			or moved, do not add the following gesture recognizer. You will simply
			need to set the region of interest once.
		*/
		resizeRegionOfInterestGestureRecognizer.delegate = self
		addGestureRecognizer(resizeRegionOfInterestGestureRecognizer)
	}
	
	// MARK: AV capture properties
	
	var videoPreviewLayer: AVCaptureVideoPreviewLayer {
		guard let layer = layer as? AVCaptureVideoPreviewLayer else {
			fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
		}
		
		return layer
	}
	
	var session: AVCaptureSession? {
		get {
			return videoPreviewLayer.session
		}
		
		set {
			videoPreviewLayer.session = newValue
		}
	}
	
	// MARK: Region of Interest
	
	private let regionOfInterestCornerTouchThreshold: CGFloat = 50
	
	/**
		The minimum region of interest's size cannot be smaller than the corner
		touch threshold as to avoid control selection conflicts when a user tries
		to resize the region of interest.
	*/
	private var minimumRegionOfInterestSize: CGFloat {
		return regionOfInterestCornerTouchThreshold
	}
	
	private let regionOfInterestControlDiameter: CGFloat = 12.0
	
	private var regionOfInterestControlRadius: CGFloat {
		return regionOfInterestControlDiameter / 2.0
	}
	
	private let maskLayer = CAShapeLayer()
	
	private let regionOfInterestOutline = CAShapeLayer()
	
	/**
		Saves a reference to the control corner that the user is using to resize
		the region of interest in `resizeRegionOfInterestWithGestureRecognizer()`.
	*/
	private var currentControlCorner: ControlCorner = .none

	/// White dot on the top left of the region of interest.
	private let topLeftControl = CAShapeLayer()
	
	/// White dot on the top right of the region of interest.
	private let topRightControl = CAShapeLayer()
	
	/// White dot on the bottom left of the region of interest.
	private let bottomLeftControl = CAShapeLayer()
	
	/// White dot on the bottom right of the region of interest.
	private let bottomRightControl = CAShapeLayer()
	
	/**
		This property is set only in `setRegionOfInterestWithProposedRegionOfInterest()`.
		When a user is resizing the region of interest in `resizeRegionOfInterestWithGestureRecognizer()`,
		the KVO notification will be triggered when the resizing is finished.
	*/
	@objc private(set) var regionOfInterest = CGRect.null
	
	/**
		Updates the region of interest with a proposed region of interest ensuring
		the new region of interest is within the bounds of the video preview. When
		a new region of interest is set, the region of interest is redrawn.
	*/
	func setRegionOfInterestWithProposedRegionOfInterest(_ proposedRegionOfInterest: CGRect) {
		// We standardize to ensure we have positive widths and heights with an origin at the top left.
		let videoPreviewRect = videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: CGRect(x: 0, y: 0, width: 1, height: 1)).standardized
		
		/*
			Intersect the video preview view with the view's frame to only get
			the visible portions of the video preview view.
		*/
		let visibleVideoPreviewRect = videoPreviewRect.intersection(frame)
		let oldRegionOfInterest = regionOfInterest
		var newRegionOfInterest = proposedRegionOfInterest.standardized
		
		// Move the region of interest in bounds.
		if currentControlCorner == .none {
			var xOffset: CGFloat = 0
			var yOffset: CGFloat = 0
			
			if !visibleVideoPreviewRect.contains(newRegionOfInterest.origin) {
				xOffset = max(visibleVideoPreviewRect.minX - newRegionOfInterest.minX, CGFloat(0))
				yOffset = max(visibleVideoPreviewRect.minY - newRegionOfInterest.minY, CGFloat(0))
			}
			
			if !visibleVideoPreviewRect.contains(CGPoint(x: visibleVideoPreviewRect.maxX, y: visibleVideoPreviewRect.maxY)) {
				xOffset = min(visibleVideoPreviewRect.maxX - newRegionOfInterest.maxX, xOffset)
				yOffset = min(visibleVideoPreviewRect.maxY - newRegionOfInterest.maxY, yOffset)
			}
			
			newRegionOfInterest = newRegionOfInterest.offsetBy(dx: xOffset, dy: yOffset)
		}
		
		// Clamp the size when the region of interest is being resized.
		newRegionOfInterest = visibleVideoPreviewRect.intersection(newRegionOfInterest)
		
		// Fix a minimum width of the region of interest.
		if proposedRegionOfInterest.size.width < minimumRegionOfInterestSize {
			switch currentControlCorner {
				case .topLeft, .bottomLeft:
					newRegionOfInterest.origin.x = oldRegionOfInterest.origin.x + oldRegionOfInterest.size.width - minimumRegionOfInterestSize
					newRegionOfInterest.size.width = minimumRegionOfInterestSize
				
				case .topRight:
					newRegionOfInterest.origin.x = oldRegionOfInterest.origin.x
					newRegionOfInterest.size.width = minimumRegionOfInterestSize
				
				default:
					newRegionOfInterest.origin = oldRegionOfInterest.origin
					newRegionOfInterest.size.width = minimumRegionOfInterestSize
			}
		}
		
		// Fix a minimum height of the region of interest.
		if proposedRegionOfInterest.size.height < minimumRegionOfInterestSize {
			switch currentControlCorner {
				case .topLeft, .topRight:
					newRegionOfInterest.origin.y = oldRegionOfInterest.origin.y + oldRegionOfInterest.size.height - minimumRegionOfInterestSize
					newRegionOfInterest.size.height = minimumRegionOfInterestSize
				
				case .bottomLeft:
					newRegionOfInterest.origin.y = oldRegionOfInterest.origin.y
					newRegionOfInterest.size.height = minimumRegionOfInterestSize
				
				default:
					newRegionOfInterest.origin = oldRegionOfInterest.origin
					newRegionOfInterest.size.height = minimumRegionOfInterestSize
			}
		}
		
		regionOfInterest = newRegionOfInterest
		setNeedsLayout()
	}
	
	var isResizingRegionOfInterest: Bool {
		return resizeRegionOfInterestGestureRecognizer.state == .changed
	}
	
	private lazy var resizeRegionOfInterestGestureRecognizer: UIPanGestureRecognizer = {
		UIPanGestureRecognizer(target: self, action: #selector(PreviewView.resizeRegionOfInterestWithGestureRecognizer(_:)))
	}()
		
	@objc
	func resizeRegionOfInterestWithGestureRecognizer(_ resizeRegionOfInterestGestureRecognizer: UIPanGestureRecognizer) {
		let touchLocation = resizeRegionOfInterestGestureRecognizer.location(in: resizeRegionOfInterestGestureRecognizer.view)
		let oldRegionOfInterest = regionOfInterest
		
		switch resizeRegionOfInterestGestureRecognizer.state {
			case .began:
				willChangeValue(forKey: "regionOfInterest")
				
				/*
					When the gesture begins, save the corner that is closest to
					the resize region of interest gesture recognizer's touch location.
				*/
				currentControlCorner = cornerOfRect(oldRegionOfInterest, closestToPointWithinTouchThreshold: touchLocation)
			
			case .changed:
				var newRegionOfInterest = oldRegionOfInterest
				
				switch currentControlCorner {
					case .none:
						// Update the new region of interest with the gesture recognizer's translation.
						let translation = resizeRegionOfInterestGestureRecognizer.translation(in: resizeRegionOfInterestGestureRecognizer.view)
						
						// Move the region of interest with the gesture recognizer's translation.
						if regionOfInterest.contains(touchLocation) {
							newRegionOfInterest.origin.x += translation.x
							newRegionOfInterest.origin.y += translation.y
						}
						
						/*
							If the touch location goes outside the preview layer,
							we will only translate the region of interest in the
							plane that is not out of bounds.
						*/
						let normalizedRect = CGRect(x: 0, y: 0, width: 1, height: 1)
						if !normalizedRect.contains(videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: touchLocation)) {
							if touchLocation.x < regionOfInterest.minX || touchLocation.x > regionOfInterest.maxX {
								newRegionOfInterest.origin.y += translation.y
							} else if touchLocation.y < regionOfInterest.minY || touchLocation.y > regionOfInterest.maxY {
								newRegionOfInterest.origin.x += translation.x
							}
						}
						
						/*
							Set the translation to be zero so that the new gesture
							recognizer's translation is in respect to the region of
							interest's new position.
						*/
						resizeRegionOfInterestGestureRecognizer.setTranslation(CGPoint.zero, in: resizeRegionOfInterestGestureRecognizer.view)
					
					case .topLeft:
						newRegionOfInterest = CGRect(x: touchLocation.x,
						                             y: touchLocation.y,
						                             width: oldRegionOfInterest.size.width + oldRegionOfInterest.origin.x - touchLocation.x,
						                             height: oldRegionOfInterest.size.height + oldRegionOfInterest.origin.y - touchLocation.y)
					
					case .topRight:
						newRegionOfInterest = CGRect(x: newRegionOfInterest.origin.x,
						                             y: touchLocation.y,
						                             width: touchLocation.x - newRegionOfInterest.origin.x,
						                             height: oldRegionOfInterest.size.height + newRegionOfInterest.origin.y - touchLocation.y)
					
					case .bottomLeft:
						newRegionOfInterest = CGRect(x: touchLocation.x,
						                             y: oldRegionOfInterest.origin.y,
						                             width: oldRegionOfInterest.size.width + oldRegionOfInterest.origin.x - touchLocation.x,
						                             height: touchLocation.y - oldRegionOfInterest.origin.y)
					
					case .bottomRight:
						newRegionOfInterest = CGRect(x: oldRegionOfInterest.origin.x,
						                             y: oldRegionOfInterest.origin.y,
						                             width: touchLocation.x - oldRegionOfInterest.origin.x,
						                             height: touchLocation.y - oldRegionOfInterest.origin.y)
				}
			
			// Update the region of intresest with a valid CGRect.
			setRegionOfInterestWithProposedRegionOfInterest(newRegionOfInterest)
			
			case .ended:
				didChangeValue(forKey: "regionOfInterest")
				
				/*
					Reset the current corner reference to none now that the resize.
					gesture recognizer has ended.
				*/
				currentControlCorner = .none
			
		default:
			return
		}
	}
	
	private func cornerOfRect(_ rect: CGRect, closestToPointWithinTouchThreshold point: CGPoint) -> ControlCorner {
		var closestDistance = CGFloat.greatestFiniteMagnitude
		var closestCorner: ControlCorner = .none
		let corners: [(ControlCorner, CGPoint)] = [(.topLeft, rect.origin),
		                                           (.topRight, CGPoint(x: rect.maxX, y: rect.minY)),
		                                           (.bottomLeft, CGPoint(x: rect.minX, y: rect.maxY)),
		                                           (.bottomRight, CGPoint(x: rect.maxX, y: rect.maxY))]
		
		for (corner, cornerPoint) in corners {
			let dX = point.x - cornerPoint.x
			let dY = point.y - cornerPoint.y
			let distance = sqrt((dX * dX) + (dY * dY))
			
			if distance < closestDistance {
				closestDistance = distance
				closestCorner = corner
			}
		}
		
		if closestDistance > regionOfInterestCornerTouchThreshold {
			closestCorner = .none
		}

		return closestCorner
	}
	
	// MARK: UIView
	
    override class var layerClass: AnyClass {
		return AVCaptureVideoPreviewLayer.self
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		// Disable CoreAnimation actions so that the positions of the sublayers immediately move to their new position.
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		
		// Create the path for the mask layer. We use the even odd fill rule so that the region of interest does not have a fill color.
		let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
		path.append(UIBezierPath(rect: regionOfInterest))
		path.usesEvenOddFillRule = true
		maskLayer.path = path.cgPath
		
		regionOfInterestOutline.path = CGPath(rect: regionOfInterest, transform: nil)
		
		let left = regionOfInterest.origin.x - regionOfInterestControlRadius
		let right = regionOfInterest.origin.x + regionOfInterest.size.width - regionOfInterestControlRadius
		let top = regionOfInterest.origin.y - regionOfInterestControlRadius
		let bottom = regionOfInterest.origin.y + regionOfInterest.size.height - regionOfInterestControlRadius
		
		topLeftControl.position = CGPoint(x: left, y: top)
		topRightControl.position = CGPoint(x: right, y: top)
		bottomLeftControl.position = CGPoint(x: left, y: bottom)
		bottomRightControl.position = CGPoint(x: right, y: bottom)
		
		CATransaction.commit()
	}

	// MARK: UIGestureRecognizerDelegate
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		// Ignore drags outside of the region of interest (plus some padding).
		if gestureRecognizer == resizeRegionOfInterestGestureRecognizer {
			let touchLocation = touch.location(in: gestureRecognizer.view)
			
			let paddedRegionOfInterest = regionOfInterest.insetBy(dx: -regionOfInterestCornerTouchThreshold, dy: -regionOfInterestCornerTouchThreshold)
			if !paddedRegionOfInterest.contains(touchLocation) {
				return false
			}
		}
		
		return true
	}
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		// Allow multiple gesture recognizers to be recognized simultaneously if and only if the touch location is not within the touch threshold.
		if gestureRecognizer == resizeRegionOfInterestGestureRecognizer {
			let touchLocation = gestureRecognizer.location(in: gestureRecognizer.view)
			
			let closestCorner = cornerOfRect(regionOfInterest, closestToPointWithinTouchThreshold: touchLocation)
			return closestCorner == .none
		}
		
		return false
	}
}
