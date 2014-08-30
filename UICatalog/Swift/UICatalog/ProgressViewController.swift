/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A view controller that demonstrates how to use UIProgressView.
            
*/

import UIKit

class ProgressViewController: UITableViewController {
    // MARK: Types

    struct Constants {
        static let maxProgress = 100
    }
    
    // MARK: Properties
    
    @IBOutlet weak var defaultStyleProgressView: UIProgressView!
    
    @IBOutlet weak var barStyleProgressView: UIProgressView!
    
    @IBOutlet weak var tintedProgressView: UIProgressView!

    let operationQueue = NSOperationQueue()

    var completedProgress: Int = 0 {
        didSet(oldValue) {
            let fractionalProgress = Float(completedProgress) / Float(Constants.maxProgress)

            let animated = oldValue != 0
            
            for progressView in [defaultStyleProgressView, barStyleProgressView, tintedProgressView] {
                progressView.setProgress(fractionalProgress, animated: animated)
            }
        }
    }

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureDefaultStyleProgressView()
        configureBarStyleProgressView()
        configureTintedProgressView()

        // As progress is received from another subsystem (i.e. NSProgress, NSURLSessionTaskDelegate, etc.), update the progressView's progress.
        simulateProgress()
    }

    // MARK: Configuration

    func configureDefaultStyleProgressView() {
        defaultStyleProgressView.progressViewStyle = .Default
    }

    func configureBarStyleProgressView() {
        barStyleProgressView.progressViewStyle = .Bar
    }

    func configureTintedProgressView() {
        tintedProgressView.progressViewStyle = .Default

        tintedProgressView.trackTintColor = UIColor.applicationBlueColor()
        tintedProgressView.progressTintColor = UIColor.applicationPurpleColor()
    }

    // MARK: Progress Simulation

    func simulateProgress() {
        // In this example we will simulate progress with a "sleep operation".
        for _ in 0...Constants.maxProgress {
            operationQueue.addOperationWithBlock {
                // Delay the system for a random number of seconds.
                // This code is not intended for production purposes. The "sleep" call is meant to simulate work done in another subsystem.
                sleep(arc4random_uniform(10))

                NSOperationQueue.mainQueue().addOperationWithBlock {
                    self.completedProgress++
                    return
                }
            }
        }
    }
}
