/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to use UIProgressView.
*/

import UIKit

/**
    The KVO context for `ProgressViewController` instances. This provides a stable
    address to use as the `context` parameter for KVO observation methods.
*/
private var progressViewKVOContext = 0

class ProgressViewController: UITableViewController {
    // MARK: - Properties
    
    @IBOutlet weak var defaultStyleProgressView: UIProgressView!
    
    @IBOutlet weak var barStyleProgressView: UIProgressView!
    
    @IBOutlet weak var tintedProgressView: UIProgressView!

    @IBOutlet var progressViews: [UIProgressView]!
    
    /**
        An `NSProgress` object who's `fractionCompleted` is observed using
        KVO to update the `UIProgressView`s' `progress` properties.
    */
    fileprivate let progress = Progress(totalUnitCount: 10)
    
    /**
        A repeating timer that, when fired, updates the `NSProgress` object's
        `completedUnitCount` property.
    */
    fileprivate var updateTimer: Timer?
    
    // MARK: - Initialization
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Register as an observer of the `NSProgress`'s `fractionCompleted` property.
        progress.addObserver(self, forKeyPath: "fractionCompleted", options: [.new], context: &progressViewKVOContext)
    }
    
    deinit {
        // Unregister as an observer of the `NSProgress`'s `fractionCompleted` property.
        progress.removeObserver(self, forKeyPath: "fractionCompleted")
    }
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureDefaultStyleProgressView()
        configureBarStyleProgressView()
        configureTintedProgressView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Reset the completed progress of the `UIProgressView`s.
        for progressView in progressViews {
            progressView.setProgress(0.0, animated: false)
        }
        
        /*
            Reset the `completedUnitCount` of the `NSProgress` object and create
            a repeating timer to increment it over time.
        */
        progress.completedUnitCount = 0
        updateTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ProgressViewController.timerDidFire), userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Stop the timer from firing.
        updateTimer?.invalidate()
    }
    
    // MARK: - Key Value Observing (KVO)
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        // Check if this is the KVO notification for our `NSProgress` object.
        if context == &progressViewKVOContext && keyPath == "fractionCompleted" && object as AnyObject? === progress {
            // Update the progress views.
            for progressView in progressViews {
                progressView.setProgress(Float(progress.fractionCompleted), animated: true)
            }
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    // MARK: - Configuration

    func configureDefaultStyleProgressView() {
        defaultStyleProgressView.progressViewStyle = .default
    }

    func configureBarStyleProgressView() {
        barStyleProgressView.progressViewStyle = .bar
    }

    func configureTintedProgressView() {
        tintedProgressView.progressViewStyle = .default

        tintedProgressView.trackTintColor = UIColor.applicationBlueColor
        tintedProgressView.progressTintColor = UIColor.applicationPurpleColor
    }

    // MARK: - Timer
    
    func timerDidFire() {
        /*
            Update the `completedUnitCount` of the `NSProgress` object if it's
            not completed. Otherwise, stop the timer.
        */
        if progress.completedUnitCount < progress.totalUnitCount {
            progress.completedUnitCount += 1
        }
        else {
            updateTimer?.invalidate()
        }
    }
}
