/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
View controller for the InstrumentDemo audio unit. This is the app extension's principal class,
            responsible for creating both the audio unit and its view.
            Manages the interactions between a InstrumentView and the audio unit's parameters.
*/

import UIKit
import CoreAudioKit

public class InstrumentDemoViewController: AUViewController { //, InstrumentViewDelegate {
    // MARK: Properties

	@IBOutlet var attackSlider: UISlider!
	@IBOutlet var releaseSlider: UISlider!

	@IBOutlet var attackTextField: UITextField!
	@IBOutlet var releaseTextField: UITextField!

    /*
		When this view controller is instantiated within the InstrumentDemoApp, its
        audio unit is created independently, and passed to the view controller here.
	*/
    public var audioUnit: AUv3InstrumentDemo? {
        didSet {
			/*
				We may be on a dispatch worker queue processing an XPC request at
                this time, and quite possibly the main queue is busy creating the
                view. To be thread-safe, dispatch onto the main queue.
				
				It's also possible that we are already on the main queue, so to
                protect against deadlock in that case, dispatch asynchronously.
			*/
			DispatchQueue.main.async {
				if self.isViewLoaded {
					self.connectViewWithAU()
				}
			}
        }
    }

    var attackParameter: AUParameter?
	var releaseParameter: AUParameter?
	var parameterObserverToken: AUParameterObserverToken?

	public override func viewDidLoad() {
		super.viewDidLoad()

		// Respond to changes in the instrumentView (attack and/or release changes).

        guard audioUnit != nil else { return }

        connectViewWithAU()
	}

	/*
		We can't assume anything about whether the view or the AU is created first.
		This gets called when either is being created and the other has already
        been created.
	*/
	func connectViewWithAU() {
		guard let paramTree = audioUnit?.parameterTree else { return }

		attackParameter = paramTree.value(forKey: "attack") as? AUParameter
		releaseParameter = paramTree.value(forKey: "release") as? AUParameter

		parameterObserverToken = paramTree.token(byAddingParameterObserver: { [weak self] address, _ in
            guard let strongSelf = self else { return }
			DispatchQueue.main.async {
				if address == strongSelf.attackParameter!.address {
                    strongSelf.updateAttack()
				} else if address == strongSelf.releaseParameter!.address {
                    strongSelf.updateRelease()
				}

			}
		})

        updateAttack()
        updateRelease()
	}

    func updateAttack() {
        attackTextField.text = attackParameter!.string(fromValue: nil)
        attackSlider.value = (log10(attackParameter!.value) + 3.0) * 100.0
    }

    func updateRelease() {
        releaseTextField.text = releaseParameter!.string(fromValue: nil)
        releaseSlider.value = (log10(releaseParameter!.value) + 3.0) * 100.0
    }

    // MARK: Actions

	@IBAction func changedAttack(_ sender: AnyObject?) {
        guard sender === attackSlider else { return }

        // Set the parameter's value from the slider's value.
        attackParameter!.value = pow(10.0, attackSlider.value * 0.01 - 3.0)
	}

	@IBAction func changedRelease(_ sender: AnyObject?) {
        guard sender === releaseSlider else { return }

        // Set the parameter's value from the slider's value.
        releaseParameter!.value = pow(10.0, releaseSlider.value * 0.01 - 3.0)
	}
}
