/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The switcher view demonstrates 3D transformations which is the primary focus of the sample.
 */

import UIKit
import MapKit

class SwitcherView: UIView, UIScrollViewDelegate {
	
	// Determines whether views should react to touch input normally while in switcher mode, and 3D transformations are active.
	static let enableUserInteractionInSwitcher = true
	
	let animationDuration: TimeInterval = 0.2
	let angle: CGFloat = 55.0 // amount to rotate the views in switcher mode
	let scaleOut: CGFloat = 0.8 // amount to scale the views while in switcher mode
	
	var containerViews: [ContainerView] = [] // array containing the various views
	var scrollView: UIScrollView!
	
	var switcherViewPadding: CGFloat = 0.0 // padding between views in switcher mode
	let separatorDivisor: CGFloat = 3.0 // used during the switcher mode transition animation
	var translationDivisor: CGFloat { // used during the switcher mode transition animation
		get {
			if UIDevice.current.userInterfaceIdiom == .pad {
				return 4.46
			} else {
				return 4.13
			}
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		standardInitialize()
	}
	
	required init(coder: NSCoder) {
		super.init(coder: coder)!
		standardInitialize()
	}
	
	func standardInitialize() {
		// During switcher mode, the focus is on the 3D transforms; set a deemphasized background color accordingly.
		layer.backgroundColor = UIColor.darkGray.cgColor
		
		// Configure the scroll view used while switching views
		switcherViewPadding = bounds.size.height / separatorDivisor
		scrollView = UIScrollView(frame: bounds)
		scrollView.isUserInteractionEnabled = true
		scrollView.minimumZoomScale = 1.0
		scrollView.maximumZoomScale = 1.0
		scrollView.isScrollEnabled = true
		scrollView.contentSize = CGSize(width: bounds.size.width, height: bounds.size.height)
		scrollView.delegate = self
		addSubview(scrollView)
		
		// Fill the switcher view with a few different options: a couple image views, a map view, and a web view.
		addContainerView(ContainerView(frame: bounds,
		                               parentView: self,
		                               imageName: "image1.jpg"))
		addContainerView(ContainerView(frame: bounds,
		                               parentView: self,
		                               customView: MKMapView(frame: self.bounds)))
		addContainerView(ContainerView(frame: bounds,
		                               parentView: self,
		                               imageName: "image2.jpg"))
		addContainerView(ContainerView(frame: bounds,
		                               parentView: self,
		                               urlString: "http://www.apple.com"))
		addContainerView(ContainerView(frame: bounds,
		                               parentView: self,
		                               imageName: "image3.jpg"))
	}
	
	// Helper function to convert degrees (user friendly input) to radians (the argument for CATransorm3D rotations)
	func radians(degrees: CGFloat) -> CGFloat {
		return degrees * CGFloat.pi / 180.0
	}
	
	/**
	Container views are regular views that show various example content while facilitating the purpose of demonstrating
	3D tranformations - the primary objective of this sample.
	*/
	func addContainerView(_ view: ContainerView) {
		view.layer.shadowPath = UIBezierPath(rect: view.bounds).cgPath
		view.layer.shadowColor = UIColor.black.cgColor
		view.frame = CGRect(x: 0.0,
		                    y: CGFloat(scrollView.subviews.count) * switcherViewPadding,
		                    width: frame.size.width,
		                    height: frame.size.height)
		scrollView.addSubview(view)
		view.index = containerViews.count
		containerViews.append(view)
		view.layer.transform = getTransform(translatedToY: 0,
		                                    isScale: true,
		                                    isRotate: true)
		scrollView.contentSize = CGSize(width: scrollView.contentSize.width,
		                                height: scrollView.contentSize.height + switcherViewPadding)
	}
	
	/**
	Create and configure a new CATransform3D.
	Parameters:
	tranlatedToY - most views are translated during the switcher view transition animation.
	The cards above the tapped card are moved upward, and the cards below are moved downward.
	scale - the views undergo a scale animation being sized down in the switcher view to increase visibility
	rotate - the views are tappered in switcher mode to give 3D perspected and rotation is how that's implemented
	*/
	func getTransform(translatedToY: CGFloat, isScale: Bool, isRotate: Bool) -> CATransform3D {
		var transform = CATransform3DIdentity
		// m34 enables 3D on the transform. The divisor determines the distance in the z-direction.
		transform.m34 = 1.0 / -2000.0
		if isRotate {
			transform = CATransform3DRotate(transform, -radians(degrees: angle), 1.0, 0.0, 0.0)
		}
		if isScale {
			transform = CATransform3DScale(transform, scaleOut, scaleOut, scaleOut)
		}
		if translatedToY != 0.0 {
			transform = CATransform3DTranslate(transform, 0.0, translatedToY, 0.0)
		}
		return transform
	}
	
	/**
	Performs the transform animation.
	When a CAAnimation is active, the model layer is hidden and its presentationLayer is shown which visualizes the animation.
	Upon animation completion, the presentationLayer is hidden and the model layer is present in the animation's final state.
	This is standard Core Animation behavior.
	*/
	func animate(transform: CATransform3D, view: UIView) {
		let basicAnim = CABasicAnimation(keyPath: "transform")
		// From value is the view's current 3D transform
		basicAnim.fromValue = view.layer.transform
		// To value is the argument new transform
		basicAnim.toValue = transform
		basicAnim.duration = animationDuration
		view.layer.add(basicAnim, forKey: nil)
		// Set the model layer to the final value. This change won't be visible until the animation done above completes
		// disable actions so the following transform change does not trigger an implicit animation
		CATransaction.setDisableActions(true)
		view.layer.transform = transform
		CATransaction.setDisableActions(false)
	}

	func animate(view: ContainerView, isFullScreen: Bool) {
		// the transforms are different depending on whether the tapped view is currently full screen or in switcher mode
		if isFullScreen {
			// cards above. Tapped view is at view.index, so end iteration at view.index-1
			for i in 0..<view.index {
				animate(transform: getTransform(translatedToY: -bounds.size.height,
				                                isScale: true,
				                                isRotate: false),
				        view: containerViews[i])
			}
			// tapped card
			animate(transform: getTransform(
				translatedToY: scrollView.contentOffset.y - (view.frame.origin.y - view.bounds.size.height / translationDivisor),
				isScale: false,
				isRotate: false),
			        view: view)
			// cards below. Tapped view is at view.index, so start iteration at view.index+1
			for i in (view.index + 1)..<containerViews.count {
				animate(transform: getTransform(translatedToY: 2.0 * bounds.size.height,
				                                isScale: true,
				                                isRotate: true),
				        view: containerViews[i])
			}
		} else {
			// cards above. Tapped view is at view.index, so end iteration at view.index-1
			for i in 0..<view.index {
				animate(transform: getTransform(translatedToY: 0.0,
				                                isScale: true,
				                                isRotate: true),
				        view: containerViews[i])
			}
			// tapped card
			animate(transform: getTransform(translatedToY: 0.0,
			                                isScale: true,
			                                isRotate: true),
			        view: view)
			// cards below. Tapped view is at view.index, so start iteration at view.index+1
			for i in (view.index + 1)..<containerViews.count {
				animate(transform: getTransform(translatedToY: 0.0,
				                                isScale: true,
				                                isRotate: true),
				        view: containerViews[i])
			}
		}
	}
}



