/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
View for displaying an animated GIF.
*/

import UIKit
import ImageIO

class AnimatedImageView: UIView {
    var animatedImage: AnimatedImage? {
        didSet {
            resetAnimationState()
            updateAnimation()
            setNeedsLayout()
        }
    }
    var isPlaying: Bool = false {
        didSet {
            if isPlaying != oldValue {
                updateAnimation()
            }
        }
    }

    private var displayLink: CADisplayLink?
    private var displayedIndex: Int = 0
    private var displayView: UIView?
    private lazy var displayLinkProxy: DisplayLinkProxyObject = {
        return DisplayLinkProxyObject(listener: self)
    }()

    // Animation state
    private var hasStartedAnimating: Bool = false
    private var hasFinishedAnimating: Bool = false
    private var isInfiniteLoop: Bool = false
    private var remainingLoopCount: Int = 0
    private var elapsedTime: Double = 0.0
    private var previousTime: Double = 0.0

    deinit {
        displayLink?.invalidate()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        var viewAspect: CGFloat = 0.0
        if bounds.height > 0.0 {
            viewAspect = bounds.width / bounds.height
        }
        var imageAspect: CGFloat = 0.0
        if let imageSize = animatedImage?.size {
            if imageSize.height > 0.0 {
                imageAspect = imageSize.width / imageSize.height
            }
        }

        var viewFrame = CGRect(x: 0.0, y: 0.0, width: bounds.width, height: bounds.height)
        if imageAspect < viewAspect {
            viewFrame.size.width = bounds.height * imageAspect
            viewFrame.origin.x = (bounds.width / 2.0) - (0.5 * viewFrame.size.width)
        } else if imageAspect > 0.0 {
            viewFrame.size.height = bounds.width / imageAspect
            viewFrame.origin.y = (bounds.height / 2.0) - (0.5 * viewFrame.size.height)
        }

        if animatedImage != nil {
            if displayView == nil {
                let newView = UIView(frame: CGRect.zero)
                addSubview(newView)
                displayView = newView
                updateImage()
            }
        } else {
            displayView?.removeFromSuperview()
            displayView = nil
        }

        displayView?.frame = viewFrame
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateAnimation()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        updateAnimation()
    }

    override var alpha: CGFloat {
        didSet {
            updateAnimation()
        }
    }

    override var isHidden: Bool {
        didSet {
            updateAnimation()
        }
    }

    func shouldAnimate() -> Bool {
        let isShown = window != nil && superview != nil && !isHidden && alpha > 0.0
        return isShown && animatedImage != nil && isPlaying && !hasFinishedAnimating
    }

    func resetAnimationState() {
        displayedIndex = 0
        hasStartedAnimating = false
        hasFinishedAnimating = false
        isInfiniteLoop = animatedImage?.frameCount == 0
        if let count = animatedImage?.loopCount {
            remainingLoopCount = count
        } else {
            remainingLoopCount = 0
        }
        elapsedTime = 0.0
        previousTime = 0.0
    }

    func updateAnimation() {
        if shouldAnimate() {
            displayLink = CADisplayLink(target: self.displayLinkProxy, selector: #selector(DisplayLinkProxyObject.proxyTimerFired))
            displayLink?.add(to: RunLoop.main, forMode: .commonModes)
            displayLink?.preferredFramesPerSecond = 60
        } else {
            displayLink?.invalidate()
            displayLink = nil
        }
    }

    func updateImage() {
        if let image = animatedImage?.imageAtIndex(index: displayedIndex) {
            displayView?.layer.contents = image
        }
    }

    func timerFired(link: CADisplayLink) {
        if !shouldAnimate() {
            return
        }

        guard let image = animatedImage else { return }

        let timestamp = link.timestamp

        // If this is the first callback, set things up
        if !hasStartedAnimating {
            elapsedTime = 0.0
            previousTime = timestamp
            hasStartedAnimating = true
        }

        let currentDelayTime = image.delayAtIndex(index: displayedIndex)
        elapsedTime += timestamp - previousTime
        previousTime = timestamp

        // Aaccount for big gaps in playback by just resuming from now
        // e.g. user presses home button and comes back after a while.
        // Allow for the possibility of the current delay time being relatively long
        if elapsedTime >= max(10.0, currentDelayTime + 1.0) {
            elapsedTime = 0.0
        }

        var changedFrame = false
        while elapsedTime >= currentDelayTime {
            elapsedTime -= currentDelayTime
            displayedIndex += 1
            changedFrame = true
            if displayedIndex >= image.frameCount {
                // Time to loop. Start infinite loops over, otherwise decrement loop count and stop if done
                if isInfiniteLoop {
                    displayedIndex = 0
                } else {
                    remainingLoopCount -= 1
                    if remainingLoopCount == 0 {
                        hasFinishedAnimating = true
                        DispatchQueue.main.async {
                            self.updateAnimation()
                        }
                    } else {
                        displayedIndex = 0
                    }
                }
            }
        }

        if changedFrame {
            updateImage()
        }
    }

}

// Use a proxy object to break the CADisplayLink retain cycle
class DisplayLinkProxyObject {
    weak var myListener: AnimatedImageView?
    init(listener: AnimatedImageView) {
        myListener = listener
    }

    @objc
    func proxyTimerFired(link: CADisplayLink) {
        myListener?.timerFired(link: link)
    }
}
