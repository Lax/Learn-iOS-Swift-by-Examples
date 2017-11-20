/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
View controller managing selection of an audio unit and presets,
            opening/closing an audio unit's view, and starting/stopping audio playback.
*/

import UIKit
import AVFoundation
import CoreAudioKit

class HostViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: Properties

    @IBOutlet var effectInstrumentSegmentedControl: UISegmentedControl!
	@IBOutlet var playButton: UIButton!
	@IBOutlet var audioUnitTableView: UITableView!
	@IBOutlet var presetTableView: UITableView!
	@IBOutlet var viewContainer: UIView!
    @IBOutlet var noViewLabel: UILabel!
    @IBOutlet var switchViewButton: UIButton!

    var viewConfigurations = [AUAudioUnitViewConfiguration]()
    var currentViewConfigurationIndex = 0
    var childViewController: UIViewController?

    var audioUnitView: UIView? {
        return childViewController?.view
    }

	var playEngine: SimplePlayEngine!

    // MARK: View Life Cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		playEngine = SimplePlayEngine(componentType: kAudioUnitType_Effect) {
			self.audioUnitTableView.reloadData()
		}

		switchViewButton.isEnabled = false
	}

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if tableView === audioUnitTableView {
			return playEngine.availableAudioUnits.count + 1
		}

        if tableView === presetTableView {
			return playEngine.presetList.count
		}

        return 0
	}

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        if tableView === audioUnitTableView {
            if (indexPath as NSIndexPath).row > 0 &&
               (indexPath as NSIndexPath).row <= playEngine.availableAudioUnits.count {
                let component = playEngine.availableAudioUnits[(indexPath as NSIndexPath).row - 1]

                cell.textLabel!.text = "\(component.name) (\(component.manufacturerName))"
            } else {
                if playEngine.isEffect() {
                    cell.textLabel!.text = "(No effect)"
                } else {
                    cell.textLabel!.text = "(No instrument)"
                }
            }

            return cell
        }

        if tableView === presetTableView {
            cell.textLabel!.text = playEngine.presetList[(indexPath as NSIndexPath).row].name

            return cell
        }

        fatalError("This index path doesn't make sense for this table view.")
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let row = (indexPath as NSIndexPath).row

		if tableView === audioUnitTableView {
            let component: AVAudioUnitComponent?

			if row > 0 {
				component = playEngine.availableAudioUnits[row - 1]
			} else {
                component = nil
            }

            playEngine.selectAudioUnitComponent(component, completionHandler: {
                DispatchQueue.main.async {
                    self.presetTableView.reloadData()
                    guard let audioUnit = self.playEngine.testAudioUnit else {
                        self.switchViewButton.isEnabled = false
                        return
                    }

                    // width: 0 height:0  is always supported. It is the default, largest view.
                    self.viewConfigurations = [AUAudioUnitViewConfiguration(width: 400,
                                                                            height: 100,
                                                                            hostHasController: false),
                                          AUAudioUnitViewConfiguration(width: 0,
                                                                       height: 0,
                                                                       hostHasController: false)]

                    let enabled = audioUnit.supportedViewConfigurations(self.viewConfigurations).count == 2
                    self.switchViewButton.isEnabled = enabled
                }
            })

            removeChildController()
            noViewLabel.isHidden = true
		} else if tableView == presetTableView {
			playEngine.selectPresetIndex(row)
		}
	}

    // MARK: - IBActions

    @IBAction func selectInstrumentOrEffect(_ sender: AnyObject?) {
        let isInstrument = effectInstrumentSegmentedControl.selectedSegmentIndex == 0 ? false : true

        audioUnitTableView.selectRow(at: IndexPath(row: 0, section: 0),
                                     animated: false,
                                     scrollPosition: UITableViewScrollPosition.top)

        removeChildController()

        if isInstrument {
            // set the engine to show instrument types and refresh au list
            playEngine.setInstrument()
        } else {
            // set the engine to show effect types and refresh au list
            playEngine.setEffect()
        }

        noViewLabel.isHidden = true

        playButton.setTitle("Play", for: UIControlState.normal)
        self.audioUnitTableView.reloadData()
        self.presetTableView.reloadData()
    }

    @IBAction func togglePlay(_ sender: AnyObject?) {
		let isPlaying = playEngine.togglePlay()

        let titleText = isPlaying ? "Stop" : "Play"

		playButton.setTitle(titleText, for: UIControlState.normal)
	}

    @discardableResult
    func removeChildController() -> Bool {
        if let childViewController = childViewController, let audioUnitView = audioUnitView {
            childViewController.willMove(toParentViewController: nil)

            audioUnitView.removeFromSuperview()

            childViewController.removeFromParentViewController()

            self.childViewController = nil

            return true
        }

        return false
    }

	@IBAction func toggleView(_ sender: AnyObject?) {
        /*
            This method is called when the view button is pressed.
        
            If there is no view shown, and the AudioUnit has a UI, the view
            controller is loaded from the AU and presented as a child view
            controller.
        
            If a pre-existing view is being shown, it is removed.
         */

        let removedChildController = removeChildController()

        guard !removedChildController else { return }

        /*
            Request the view controller asynchronously from the audio unit. This
            only happens if the audio unit is non-nil.
        */
        playEngine.testAudioUnit?.requestViewController { [weak self] viewController in
            guard let strongSelf = self else { return }

            // Only update the view if the view controller has one.
            guard let viewController = viewController, let view = viewController.view else {
                /*
                    Show placeholder text that tells the user the audio unit has
                    no view.
                */
                strongSelf.noViewLabel.isHidden = false
                return
            }

            strongSelf.addChildViewController(viewController)
            view.frame = strongSelf.viewContainer.bounds

            strongSelf.viewContainer.addSubview(view)
            strongSelf.childViewController = viewController

            viewController.didMove(toParentViewController: self)

            strongSelf.noViewLabel.isHidden = true
        }
	}

    @IBAction func switchViewMode(_ sender: AnyObject?) {
        guard let audioUnit = playEngine.testAudioUnit else {
            return
        }
        audioUnit.select(viewConfigurations[currentViewConfigurationIndex])
        currentViewConfigurationIndex = (currentViewConfigurationIndex + 1) % viewConfigurations.count
    }
}
