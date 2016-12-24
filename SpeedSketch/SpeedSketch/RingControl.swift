/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A custom control using Gesture Recognizers and hit testing beyond its initial bounds.
*/
import UIKit

class RingControl: UIView {
    var selectedView: RingView!
    var tapRecognizer: UITapGestureRecognizer!
    var ringViews = [RingView]()
    
    var ringRadius: CGFloat {
        return bounds.width/2.0
    }
    
    init(frame: CGRect, itemCount: Int) {
        super.init(frame:frame)
        setupRings(itemCount: itemCount)
    }
    
    func setupRings(itemCount: Int) {
        // Define some nice colors.
        let borderColorSelected = UIColor(hue:0.07, saturation:0.81, brightness:0.98, alpha:1.00).cgColor
        let borderColorNormal = UIColor.darkGray.cgColor
        let fillColorSelected = UIColor(hue:0.07, saturation:0.21, brightness:0.98, alpha:1.00)
        let fillColorNormal = UIColor.white
        
        // We define generators to return closures which we use to define
        // the different states of our item ring views. Since we add those
        // to the view, they need to capture the view unowned to avoid a 
        // retain cycle.
        let selectedGenerator = { (view: RingView) -> (()->()) in
            return { [unowned view] in
                view.layer.borderColor = borderColorSelected
                view.backgroundColor = fillColorSelected
            }
        }
        
        let normalGenerator = { (view: RingView) -> (()->()) in
            return { [unowned view] in
                view.layer.borderColor = borderColorNormal
                view.backgroundColor = fillColorNormal
            }
        }
        
        let startPosition = bounds.center
        let locationNormalGenerator = { (view: RingView) -> (()->()) in
            return { [unowned view] in
                view.center = startPosition
                if !view.selected {
                    view.alpha = 0.0
                }
            }
        }

        let locationFanGenerator = { (view: RingView, offset: CGVector) -> (()->()) in
            return { [unowned view] in
                view.center = startPosition + offset
                view.alpha = 1.0
            }
        }

        
        // tau is a full circle in radians
        let tau = CGFloat.pi * 2
        let absoluteRingSegment = tau / 4.0
        let requiredLengthPerRing = ringRadius * 2 + 5.0
        let totalRequiredCirlceSegment = requiredLengthPerRing * CGFloat(itemCount - 1)
        let fannedControlRadius = max(requiredLengthPerRing, totalRequiredCirlceSegment / absoluteRingSegment)
        let normalDistance = CGVector(dx: 0, dy: -1 * fannedControlRadius)
        
        let scale = UIScreen.main.scale

        // Setup our item views.
        for index in 0..<itemCount {
            let view = RingView(frame:self.bounds)
            view.stateClosures[.selected] = selectedGenerator(view)
            view.stateClosures[.normal] = normalGenerator(view)
            view.stateClosures[.locationFan] = locationFanGenerator(view, normalDistance.apply(transform: CGAffineTransform(rotationAngle: CGFloat(index) / CGFloat(itemCount-1) * (absoluteRingSegment))).round(toScale: scale))
            view.stateClosures[.locationOrigin] = locationNormalGenerator(view)
            self.addSubview(view)
            ringViews.append(view)

            let gr = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
            view.addGestureRecognizer(gr)
        }

        // Setup the initial selection state.
        let selectedView = ringViews[0]
        addSubview(selectedView)
        selectedView.selected = true
        self.selectedView = selectedView
        updateViews(animated: false)
    }
    
    // MARK: View interaction and animation
    
    func tap(_ recognizer: UITapGestureRecognizer) {
        guard let view = recognizer.view as! RingView? else { return }
            
        let fanState = view.fannedOut
        
        if fanState {
            select(view: view)
        } else {
            for view in ringViews {
                view.fannedOut = true
            }
        }
        
        self.updateViews(animated:true)
    }

    func cancelInteraction() {
        guard selectedView.fannedOut else { return }

        for view in ringViews {
            view.fannedOut = false
        }
        self.updateViews(animated: true)
    }
    
    func select(view: RingView) {
        for view in ringViews {
            if view.selected {
                view.selected = false
                view.selectionState?()
            }
            view.fannedOut = false
        }
        view.selected = true
        selectedView = view
        view.actionClosure?()
    }
    
    func updateViews(animated: Bool) {
        // Order the selected view in front.
        self.addSubview(selectedView)
        
        var stateTransitions = [()->()]()
        for view in ringViews {
            if let state = view.selectionState {
                stateTransitions.append(state)
            }
            if let state = view.locationState {
                stateTransitions.append(state)
            }
        }
        
        let transition = {
            for transition in stateTransitions {
                transition()
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.25, animations: transition)
        } else {
            transition()
        }
    }
    
    // MARK: Hit testing
    
    // Hit test on our ring views regardless of our own bounds.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for view in self.subviews.reversed() {
            let localPoint = view.convert(point, from: self)
            if view.point(inside: localPoint, with: event) {
                return view
            }
        }
        // Don't hit-test ourself.
        return nil
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for view in self.subviews.reversed() {
            if view.point(inside: view.convert(point, from: self), with: event) {
                return true
            }
        }
        return super.point(inside: point, with: event)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


