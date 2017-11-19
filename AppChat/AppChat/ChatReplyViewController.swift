/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The view controller that displays an arc of reply buttons for the user to select from.
 */

import UIKit

private enum NormalizedThresholds {
    static let xMinCenter = 0.4
    static let xMaxCenter = 0.6
    
    static let yTop = 0.25
    static let yBottom = 0.75
}

protocol ChatReplyDelegate: NSObjectProtocol {
    /// Send a reply message with the given string.
    func send(reply: String) -> Void
}

class ChatReplyViewController : UIViewController {
    weak var delegate: ChatReplyDelegate?
    
    private let customTransitionDelegate = ChatReplyTransitionDelegate()
    
    var presentationIsInteractive: Bool = false {
        didSet {
            customTransitionDelegate.presentationIsInteractive = presentationIsInteractive
        }
    }
    var interactiveTransitionProgress: CGFloat = 0.0 {
        didSet {
            customTransitionDelegate.currentTransitionProgress = interactiveTransitionProgress
        }
    }
    func completeCurrentInteractiveTransition() {
        customTransitionDelegate.completeCurrentInteractiveTransition()
    }
    func cancelCurrentInteractiveTransition() {
        customTransitionDelegate.cancelCurrentInteractiveTransition()
    }
    
    private let replyButtons: [ChatReplyButton]
    private let dismissButton = ChatReplyButton(title: "✖︎")
    private var dismissButtonXConstraint: NSLayoutConstraint?
    private var dismissButtonYConstraint: NSLayoutConstraint?
    
    /// Whether the arc of reply buttons are expanded.
    var isExpanded: Bool = false {
        didSet {
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }
    
    /// How far the arc of reply buttons are overexpanded. Normalized from 0.0 to 1.0.
    var overexpansion: CGFloat = 0.0 {
        didSet {
            overexpansion = clamp(value: overexpansion, minimum: 0.0, maximum: 1.0)
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }
    
    /// The position of the touch during the preview interaction, in this view controller's view's coordinate space.
    var previewTouchPosition: CGPoint? {
        didSet {
            let touchedReplyButton = replyButton(at: previewTouchPosition)
            touchedReplyButton?.isHighlighted = true
            let untouchedReplyButtons = replyButtons.filter { (replyButton) -> Bool in
                return replyButton != touchedReplyButton
            }
            for untouchedReplyButton in untouchedReplyButtons {
                untouchedReplyButton.isHighlighted = false
            }
        }
    }
    
    /// Choose the reply button currently being touched (if any), as if it were tapped.
    func chooseTouchedReplyButton() {
        let touchedReplyButton = replyButton(at: previewTouchPosition)
        touchedReplyButton?.handleTap()
        touchedReplyButton?.isHighlighted = false
    }
    
    private func replyButton(at point: CGPoint?) -> ChatReplyButton? {
        guard let point = point else { return nil }
        return replyButtons.first { (replyButton) -> Bool in
            let pointInReplyButton = replyButton.convert(point, from: view)
            return replyButton.point(inside: pointInReplyButton, with: nil)
        }
    }
    
    /// The point from where this view controller was presented, with normalized x and y values from 0.0 to 1.0.
    var normalizedSourcePoint: CGPoint? {
        didSet {
            if let point = normalizedSourcePoint {
                // Don't let the point get too close to the edges by performing some clamping.
                var x = clamp(value: point.x, minimum: 0.0, maximum: 1.0)
                var y = clamp(value: point.y, minimum: 0.0, maximum: 1.0)
                if x > CGFloat(NormalizedThresholds.xMinCenter) && x < CGFloat(NormalizedThresholds.xMaxCenter) {
                    // The point lies within the horizontal center.
                    y = clamp(value: y, minimum: 0.15, maximum: 0.95)
                }
                else if y < CGFloat(NormalizedThresholds.yTop) || y > CGFloat(NormalizedThresholds.yBottom) {
                    // The point lies close to the top or bottom edge.
                    x = clamp(value: x, minimum: 0.3, maximum: 0.7)
                    y = clamp(value: y, minimum: 0.15, maximum: 0.85)
                }
                else {
                    // The point lies somewhere in the middle vertically, but close to the left or right edge.
                    x = clamp(value: x, minimum: 0.1, maximum: 0.9)
                    y = clamp(value: y, minimum: 0.15, maximum: 0.85)
                }
                normalizedSourcePoint = CGPoint(x: x, y: y)
            }
            updateDismissButtonConstraints(createIfNeeded: false)
        }
    }
    
    /// Returns a rotation in radians to apply to the arc of buttons centered around the given point within the rect. This keeps the arc away from the edge of the screen.
    private func rotationAmount(forPoint point: CGPoint, in rect: CGRect) -> Double {
        guard rect.width > 0 && rect.height > 0 else { return 0 }
        
        let normalizedX = clamp(value: Double(point.x / rect.width), minimum: 0.0, maximum: 1.0)
        let normalizedY = clamp(value: Double(point.y / rect.height), minimum: 0.0, maximum: 1.0)
        var baseRotation = 0.0
        var adjustment = 0.0
        
        if normalizedY < NormalizedThresholds.yTop {
            baseRotation = M_PI
            adjustment = -M_PI_4
        }
        else if normalizedY > NormalizedThresholds.yBottom {
            adjustment = M_PI_4
        }
        else {
            adjustment = M_PI_2
        }
        
        if normalizedX < NormalizedThresholds.xMinCenter {
            baseRotation += adjustment
        }
        else if normalizedX > NormalizedThresholds.xMaxCenter {
            baseRotation -= adjustment
        }
        
        return baseRotation
    }
    
    init() {
        replyButtons = [ChatReplyButton(title: "❤️"),
                        ChatReplyButton(title: "😄"),
                        ChatReplyButton(title: "👍"),
                        ChatReplyButton(title: "😯"),
                        ChatReplyButton(title: "😢"),
                        ChatReplyButton(title: "😈")]
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = customTransitionDelegate
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dismissGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        view.addGestureRecognizer(dismissGestureRecognizer)
        
        for replyButton in replyButtons {
            replyButton.action = {[unowned self] (button: UIButton) in
                let delegate = self.delegate
                self.dismiss(animated: true) {
                    delegate?.send(reply: button.currentTitle!)
                }
            }
            view.addSubview(replyButton)
        }
        
        dismissButton.action = {[unowned self] (button) in
            self.dismiss(animated: true)
        }
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dismissButton)
        
        updateDismissButtonConstraints(createIfNeeded: true)
    }
    
    private func updateDismissButtonConstraints(createIfNeeded: Bool) {
        if createIfNeeded || dismissButtonXConstraint != nil {
            dismissButtonXConstraint?.isActive = false
            let dismissButtonXMultiplier = (normalizedSourcePoint?.x ?? 0) * 2.0
            dismissButtonXConstraint = NSLayoutConstraint(item: dismissButton, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: dismissButtonXMultiplier, constant: 0)
            dismissButtonXConstraint?.isActive = true
        }
        
        if createIfNeeded || dismissButtonYConstraint != nil {
            dismissButtonYConstraint?.isActive = false
            let dismissButtonYMultiplier = (normalizedSourcePoint?.y ?? 0) * 2.0
            dismissButtonYConstraint = NSLayoutConstraint(item: dismissButton, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: dismissButtonYMultiplier, constant: 0)
            dismissButtonYConstraint?.isActive = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let arcSize = min(view.bounds.width, view.bounds.height) / 3.5
        let overexpansionDistance = overexpansion * (arcSize / 10.0)
        let arcRadius = arcSize + overexpansionDistance
        
        func arcVectorFromCenter(for normalizedPosition: Double) -> CGVector {
            let dx = CGFloat(sin(normalizedPosition * M_PI - M_PI_2)) * arcRadius
            let dy = CGFloat(sin(normalizedPosition * M_PI + M_PI)) * arcRadius
            return CGVector(dx: dx, dy: dy)
        }
        
        let buttonAlpha: CGFloat = isExpanded ? 1.0 : 0.0
        dismissButton.alpha = buttonAlpha
        for replyButton in replyButtons {
            var replyButtonCenter = dismissButton.center
            if isExpanded {
                let index = replyButtons.index(of: replyButton)!
                let normalizedPosition = Double(index) / Double(replyButtons.count - 1)
                let centerOffset = arcVectorFromCenter(for: normalizedPosition)
                let rotation = rotationAmount(forPoint: dismissButton.center, in: dismissButton.superview!.bounds)
                let rotatedOffset = rotate(vector: centerOffset, by: rotation)
                replyButtonCenter.x += rotatedOffset.dx
                replyButtonCenter.y += rotatedOffset.dy
            }
            replyButton.center = replyButtonCenter
            replyButton.alpha = buttonAlpha
        }
    }
    
    func viewTapped() {
        dismiss(animated: true)
    }
}
