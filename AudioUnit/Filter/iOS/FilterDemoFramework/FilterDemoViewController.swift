/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
View controller for the FilterDemo audio unit. Manages the interactions between a FilterView and
            the audio unit's parameters.
*/

import UIKit
import CoreAudioKit

public class FilterDemoViewController: AUViewController, FilterViewDelegate, UITextFieldDelegate {
    // MARK: Properties

    @IBOutlet weak var filterView: FilterView!
	@IBOutlet weak var frequencyLabel: UILabel!
	@IBOutlet weak var resonanceLabel: UILabel!

    @IBOutlet weak var frequencyTextField: UITextField!
    @IBOutlet weak var resonanceTextField: UITextField!

    @IBOutlet var largeView: UIView!
    @IBOutlet var smallView: UIView!

    var smallViewActive: Bool = false

    /*
		When this view controller is instantiated within the FilterDemoApp, its
        audio unit is created independently, and passed to the view controller here.
	*/
    public var audioUnit: AUv3FilterDemo? {
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

    @objc
    public func handleSelectViewConfiguration(_ viewConfiguration: AUAudioUnitViewConfiguration) {
        // If requested configuration is already active, do nothing
        if (viewConfiguration.width > 0) && (viewConfiguration.width < 800 || viewConfiguration.height < 500) {
            if smallViewActive { return }
        } else {
            if !smallViewActive { return }
        }

        self.view.translatesAutoresizingMaskIntoConstraints = true

        let targetView = smallViewActive ? largeView : smallView
        let sourceView = smallViewActive ? smallView : largeView
        let containerView = self.view!

        DispatchQueue.main.async {
            UIView.transition(from: sourceView!, to: targetView!, duration: 0.5,
                              options: [UIViewAnimationOptions.transitionCrossDissolve,
                                        UIViewAnimationOptions.layoutSubviews], completion:nil)

            // If the transition is still in progress, add ourselves to the
            // container view and make sure the layout is right, before the transition finishes
            if targetView?.superview !== self.view {
                self.view.addSubview(targetView!)
            }

            // When the view is removed from the containerView, the constraints are lost,
            // re-add them so we fill out the container
            let views = ["targetView": targetView!]
            containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[targetView]-(0)-|",
                                                                        options: [],
                                                                        metrics: nil, views: views))
            containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[targetView]",
                                                                        options: [],
                                                                        metrics: nil, views: views))
            containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[targetView]",
                                                                        options: [],
                                                                        metrics: nil, views: views))
            containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[targetView]-(0)-|",
                                                                        options: [],
                                                                        metrics: nil, views: views))
        }
        smallViewActive = !smallViewActive
    }

    var cutoffParameter: AUParameter?
	var resonanceParameter: AUParameter?
	var parameterObserverToken: AUParameterObserverToken?

	public override func viewDidLoad() {
		super.viewDidLoad()

		// Respond to changes in the filterView (frequency and/or response changes).
        filterView.delegate = self

        self.frequencyTextField.delegate = self
        self.resonanceTextField.delegate = self

        guard audioUnit != nil else { return }

        self.view.layer.borderColor = UIColor.black.cgColor
        self.view.layer.borderWidth = 2
        self.view.layer.cornerRadius = 1
        self.view.backgroundColor = UIColor.green

        connectViewWithAU()
	}

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }

    // MARK: FilterViewDelegate

    func updateFilterViewFrequencyAndMagnitudes() {
        guard let audioUnit = audioUnit as AUv3FilterDemo! else { return }

        // Get an array of frequencies from the view.
        let frequencies = filterView.frequencyDataForDrawing()

        // Get the corresponding magnitudes from the AU.
        let magnitudes = audioUnit.magnitudes(forFrequencies: frequencies as [NSNumber]!).map { $0.doubleValue }

        filterView.setMagnitudes(magnitudes)
    }

    func filterView(_ filterView: FilterView, didChangeResonance resonance: Float) {

        resonanceParameter?.value = resonance

        updateFilterViewFrequencyAndMagnitudes()
    }

    func filterView(_ filterView: FilterView, didChangeFrequency frequency: Float) {

        cutoffParameter?.value = frequency

        updateFilterViewFrequencyAndMagnitudes()
    }

    func filterView(_ filterView: FilterView, didChangeFrequency frequency: Float, andResonance resonance: Float) {

        cutoffParameter?.value = frequency
        resonanceParameter?.value = resonance

        updateFilterViewFrequencyAndMagnitudes()
    }

    func filterViewDataDidChange(_ filterView: FilterView) {
        updateFilterViewFrequencyAndMagnitudes()
    }

    func updateLabels(resonance: String?, cutoff: String?) {
        if resonance != nil {
            resonanceLabel.text = resonance
            resonanceTextField.text = resonance
        }
        if cutoff != nil {
            frequencyLabel.text = cutoff
            frequencyTextField.text = cutoff
        }
    }

    @IBAction func frequencyUpdated(_ sender : Any) {
        guard let paramTree = audioUnit?.parameterTree else { return }
        cutoffParameter = paramTree.value(forKey: "cutoff") as? AUParameter
        cutoffParameter!.value = (frequencyTextField.text! as NSString).floatValue
        frequencyTextField.text = cutoffParameter!.string(fromValue: nil)
    }

    @IBAction func resonanceUpdated(_ sender: Any) {
        guard let paramTree = audioUnit?.parameterTree else { return }
        resonanceParameter = paramTree.value(forKey: "resonance") as? AUParameter
        resonanceParameter!.value = (resonanceTextField.text! as NSString).floatValue
        resonanceTextField.text = resonanceParameter!.string(fromValue: nil)
    }

    /*
		We can't assume anything about whether the view or the AU is created first.
		This gets called when either is being created and the other has already
        been created.
	*/
	func connectViewWithAU() {
		guard let paramTree = audioUnit?.parameterTree else { return }

        audioUnit?.filterDemoViewController = self

		cutoffParameter = paramTree.value(forKey: "cutoff") as? AUParameter
		resonanceParameter = paramTree.value(forKey: "resonance") as? AUParameter

        parameterObserverToken = paramTree.token(byAddingParameterObserver: { [weak self] address, value in
            guard let strongSelf = self else { return }

			DispatchQueue.main.async {
				if address == strongSelf.cutoffParameter!.address {
					strongSelf.filterView.frequency = value
					strongSelf.updateLabels(resonance: nil, cutoff: strongSelf.cutoffParameter!.string(fromValue: nil))
				} else if address == strongSelf.resonanceParameter!.address {
					strongSelf.filterView.resonance = value
					strongSelf.updateLabels(resonance: strongSelf.resonanceParameter!.string(fromValue: nil), cutoff: nil)
				}

				strongSelf.updateFilterViewFrequencyAndMagnitudes()
			}
		})

        filterView.frequency = cutoffParameter!.value
        filterView.resonance = resonanceParameter!.value

        updateFilterViewFrequencyAndMagnitudes()
        updateLabels(resonance: resonanceParameter!.string(fromValue: nil),
                     cutoff: cutoffParameter!.string(fromValue: nil))
	}
}
