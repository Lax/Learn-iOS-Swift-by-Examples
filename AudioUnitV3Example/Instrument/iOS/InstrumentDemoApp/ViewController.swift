/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
View controller which registers an AUAudioUnit subclass in-process for easy development,
            connects sliders and text fields to its parameters, and embeds the audio unit's view
            into a subview. Uses SimplePlayEngine to audition the effect.
*/

import UIKit
import AudioToolbox
import InstrumentDemoFramework

class ViewController: UIViewController {
    // MARK: Properties

	@IBOutlet var playButton: UIButton!

    @IBOutlet weak var attackLabel: UILabel!
    @IBOutlet weak var releaseLabel: UILabel!

    /// Container for our custom view.
    @IBOutlet var auContainerView: UIView!

	/// The audio playback engine.
	var playEngine: SimplePlayEngine!

	/// The audio unit's filter attack frequency parameter object.
	var attackParameter: AUParameter!

	/// The audio unit's filter release parameter object.
	var releaseParameter: AUParameter!

	/// A token for our registration to observe parameter value changes.
	var parameterObserverToken: AUParameterObserverToken!

	/// Our plug-in's custom view controller. We embed its view into `viewContainer`.
	var filterDemoViewController: InstrumentDemoViewController!

    // MARK: View Life Cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		// Set up the plug-in's custom view.
		embedPlugInView()

		// Create an audio file playback engine.
		playEngine = SimplePlayEngine(componentType: kAudioUnitType_MusicDevice)

		/*
			Register the AU in-process for development/debugging.
			First, build an AudioComponentDescription matching the one in our
            .appex's Info.plist.
		*/
        // MARK: AudioComponentDescription Important!
        // Ensure that you update the AudioComponentDescription for your AudioUnit type, manufacturer and creator type.
        var componentDescription = AudioComponentDescription()
        componentDescription.componentType = kAudioUnitType_MusicDevice
        componentDescription.componentSubType = 0x73696E33 /*'sin3'*/
        componentDescription.componentManufacturer = 0x44656d6f /*'Demo'*/
        componentDescription.componentFlags = 0
        componentDescription.componentFlagsMask = 0

		/*
			Register our `AUAudioUnit` subclass, `AUv3InstrumentDemo`, to make it able
            to be instantiated via its component description.
			
			Note that this registration is local to this process.
		*/
        AUAudioUnit.registerSubclass(AUv3InstrumentDemo.self, as: componentDescription,
                                     name: "Demo: Local InstrumentDemo", version: UInt32.max)

		// Instantiate and insert our audio unit effect into the chain.
		playEngine.selectAudioUnitWithComponentDescription(componentDescription) {
			// This is an asynchronous callback when complete. Finish audio unit setup.
			self.connectParametersToControls()
		}
	}

	/// Called from `viewDidLoad(_:)` to embed the plug-in's view into the app's view.
	func embedPlugInView() {
        /*
			Locate the app extension's bundle, in the app bundle's PlugIns
			subdirectory. Load its MainInterface storyboard, and obtain the
            `InstrumentDemoViewController` from that.
        */
        let builtInPlugInsURL = Bundle.main.builtInPlugInsURL!
        let pluginURL = builtInPlugInsURL.appendingPathComponent("InstrumentDemoAppExtension.appex")
		let appExtensionBundle = Bundle(url: pluginURL)

        let storyboard = UIStoryboard(name: "MainInterface", bundle: appExtensionBundle)
		filterDemoViewController = storyboard.instantiateInitialViewController() as! InstrumentDemoViewController

        // Present the view controller's view.
        if let view = filterDemoViewController.view {
            addChildViewController(filterDemoViewController)
            view.frame = auContainerView.bounds

            auContainerView.addSubview(view)
            filterDemoViewController.didMove(toParentViewController: self)
        }
	}

	/**
        Called after instantiating our audio unit, to find the AU's parameters and
        connect them to our controls.
    */
	func connectParametersToControls() {
		// Find our parameters by their identifiers.
        guard let parameterTree = playEngine.testAudioUnit?.parameterTree else { return }

        let audioUnit = playEngine.testAudioUnit as? AUv3InstrumentDemo
        filterDemoViewController.audioUnit = audioUnit

        attackParameter = parameterTree.value(forKey: "attack") as? AUParameter
        releaseParameter = parameterTree.value(forKey: "release") as? AUParameter

        parameterObserverToken = parameterTree.token(byAddingParameterObserver: { [unowned self] address, _ in
            /*
                This is called when one of the parameter values changes.
                
                We can only update UI from the main queue.
            */
            DispatchQueue.main.async {
                if address == self.attackParameter.address {
                    self.updateAttack()
                } else if address == self.releaseParameter.address {
                    self.updateRelease()
                }
            }
        })

        updateAttack()
        updateRelease()
	}

	// Callbacks to update controls from parameters.
	func updateAttack() {
        attackLabel.text = attackParameter.string(fromValue: nil)
	}

	func updateRelease() {
        releaseLabel.text = releaseParameter.string(fromValue: nil)
	}

    // MARK: IBActions

	/// Handles Play/Stop button touches.
    @IBAction func togglePlay(_ sender: AnyObject?) {
		let isPlaying = playEngine.togglePlay()

        let titleText = isPlaying ? "Stop" : "Play"

		playButton.setTitle(titleText, for: .normal)
	}
}
