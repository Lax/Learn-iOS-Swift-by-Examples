/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Defines the view controller for the default scene.
*/

import AVFoundation
import AVKit

class StartViewController: UIViewController {
    // MARK: Properties
    
    @IBOutlet weak var startButton: UIButton!
	let player = AVPlayer()
	
	var sourceURL: NSURL? {
        // Update `playerViewController` with new source movie.
		didSet {
			let playerItem: AVPlayerItem?

            if let sourceURL = sourceURL {
                playerItem = AVPlayerItem(URL: sourceURL)

                startButton.enabled = true
			}
			else {
				playerItem = nil
				
                startButton.enabled = false
			}
			
            player.replaceCurrentItemWithPlayerItem(playerItem)
		}
	}
	
    let defaultSourceURL = NSBundle.mainBundle().URLForResource("ElephantSeals", withExtension: "mov")!
	
    let outputURL = NSURL(fileURLWithPath: NSTemporaryDirectory() + "out.mov")
    
    static let embedSegueName = "playerViewController"
    
    // MARK: View Controller
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
        // Default to disabled, until we establish a source.
		startButton.enabled = false
        
        // Establish a source.
		sourceURL = defaultSourceURL
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == StartViewController.embedSegueName {
			// This segue fires before `viewDidLoad()` is invoked.
			let playerViewController = segue.destinationViewController as! AVPlayerViewController

            playerViewController.player = player
		}
		else {
			// Stop playback when transitioning to next scene.
			player.pause()
			
			let nextViewController = segue.destinationViewController as! ProgressViewController
            
            /*
                We cannot get here if there is no source, because `startButton`
                will be disabled.
            */
			nextViewController.sourceURL = sourceURL
			nextViewController.outputURL = outputURL
		}
	}
}
