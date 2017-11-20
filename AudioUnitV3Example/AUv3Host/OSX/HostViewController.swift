/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
View controller managing selection of an audio unit and presets,
            opening/closing an audio unit's view, and starting/stopping audio playback.
*/

import Cocoa
import AVFoundation
import CoreAudioKit

class HostViewController: NSViewController, NSWindowDelegate {
    @IBOutlet weak var instrumentEffectsSelector: NSSegmentedControl!
    @IBOutlet weak var playButton: NSButton!
    @IBOutlet weak var effectTable: NSTableView!

    @IBOutlet weak var showCustomViewButton: NSButton!
    @IBOutlet weak var switchViewModeButton: NSButton!

    @IBOutlet weak var auViewContainer: NSView!

    @IBOutlet weak var verticalLine: NSBox!

    @IBOutlet weak var horizontalViewSizeConstraint: NSLayoutConstraint!
    @IBOutlet weak var verticalViewSizeConstraint: NSLayoutConstraint!

    @IBOutlet weak var verticalLineLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var verticalLineTrailingConstraint: NSLayoutConstraint!

    var viewConfigurations = [AUAudioUnitViewConfiguration]()
    var currentViewConfigurationIndex = 0

    let kAUViewSizeDefaultWidth: CGFloat = 484.0
    let kAUViewSizeDefaultHeight: CGFloat = 400.0

    var isDisplayingCustomView: Bool = false

    var auView: NSView?
    var playEngine: SimplePlayEngine!

    override func viewDidLoad() {
        super.viewDidLoad()

        horizontalViewSizeConstraint.constant = 0
        verticalLineLeadingConstraint.constant = 0
        verticalLineTrailingConstraint.constant = 0

        switchViewModeButton.isEnabled = false

        playEngine = SimplePlayEngine(componentType: kAudioUnitType_Effect) {
            self.effectTable.reloadData()
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.wantsLayer = true
        self.view.window?.delegate = self
    }

    // MARK: Actions

    @IBAction func togglePlay(_ sender: AnyObject?) {
        let isPlaying = playEngine.togglePlay()

        playButton.title = isPlaying ? "Stop" : "Play"
    }

    @IBAction func selectInstrumentOrEffect(_ sender: AnyObject?) {
        let isInstrument = instrumentEffectsSelector.selectedSegment == 0 ? false : true
        if isInstrument {
            playEngine.setInstrument()
        } else {
            playEngine.setEffect()
        }

        playButton.title = "Play"
        effectTable.reloadData()

        if self.effectTable.selectedRow <= 0 {
            self.showCustomViewButton.isEnabled = false
        } else {
            self.showCustomViewButton.isEnabled = true
        }

        closeAUView()
    }

    @IBAction func toggleLoadInProcessOption(sender: NSMenuItem) {
        switch sender.state {
        case .on:
            sender.state = .off
            playEngine.instantiationOptions = .loadInProcess
        default:
            sender.state = .on
            playEngine.instantiationOptions = .loadOutOfProcess
        }
    }

    // MARK: - AUView
    func setupViewController() {
        /*
         Request the view controller asynchronously from the audio unit. This
         only happens if the audio unit is non-nil.
         */
        playEngine.testAudioUnit?.requestViewController { [weak self] viewController in
            guard let strongSelf = self else { return }

            guard let viewController = viewController else { return }

            strongSelf.showCustomViewButton.title = "Hide Custom View"

            strongSelf.verticalLine.isHidden = false
            strongSelf.verticalLineLeadingConstraint.constant = 8
            strongSelf.verticalLineTrailingConstraint.constant = 8

            let view = viewController.view
            view.translatesAutoresizingMaskIntoConstraints = false
            view.postsFrameChangedNotifications = true

            var viewSize: NSSize = view.frame.size

            viewSize.width = max(view.frame.width, self!.kAUViewSizeDefaultWidth)
            viewSize.height = max(view.frame.height, self!.kAUViewSizeDefaultHeight)

            strongSelf.horizontalViewSizeConstraint.constant = viewSize.width
            strongSelf.verticalViewSizeConstraint.constant = viewSize.height

            let superview = strongSelf.auViewContainer

            superview?.addSubview(view)

            let preferredSize = viewController.preferredContentSize

            let views = ["view": view] //, "superview": superview]
            let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
                                                                       options: [],
                                                                       metrics: nil, views: views)
            superview?.addConstraints(horizontalConstraints)

            // If a view has no preferred size, or a large preferred size, add a leading and trailing constraint.
            // Otherwise, just a trailing constraint
            if preferredSize.height == 0 || preferredSize.height > strongSelf.kAUViewSizeDefaultHeight {
                let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
                                                                         options: [],
                                                                         metrics: nil, views: views)
                superview?.addConstraints(verticalConstraints)
            } else {
                let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]",
                                                                         options: [],
                                                                         metrics: nil, views: views)
                superview?.addConstraints(verticalConstraints)
            }

            NotificationCenter.default.addObserver(strongSelf,
                                                   selector: #selector(HostViewController.auViewSizeChanged(_:)),
                                                   name: NSView.frameDidChangeNotification, object: nil)

            strongSelf.auView = view
            strongSelf.auView?.needsDisplay = true
            strongSelf.auViewContainer.needsDisplay = true
            strongSelf.isDisplayingCustomView = true
        }
    }
    @IBAction func openViewAction(_ sender: AnyObject?) {
        if isDisplayingCustomView {
            if auView != nil {
                closeAUView()
                return
            }
        } else {
            setupViewController()
        }
    }

    @objc func auViewSizeChanged(_ notification: NSNotification) {
        if let view = notification.object as? NSView, view === auView {
            self.horizontalViewSizeConstraint.constant = view.frame.size.width

            if view.frame.size.height >= self.kAUViewSizeDefaultHeight {
                self.verticalViewSizeConstraint.constant = view.frame.size.height
            }
        }
    }

    func closeAUView() {
        if !isDisplayingCustomView { return }

        isDisplayingCustomView = false

        auView?.removeFromSuperview()
        auView = nil

        horizontalViewSizeConstraint.constant = 0
        verticalLineLeadingConstraint.constant = 0
        verticalLineTrailingConstraint.constant = 0

        verticalLine.isHidden = true

        showCustomViewButton.title = "Show View"

        NotificationCenter.default.removeObserver(self, name: NSView.frameDidChangeNotification, object: nil)
    }

    // MARK: - TableView

    func numberOfRowsInTableView(_ aTableView: NSTableView) -> Int {
        if aTableView === effectTable {
            return playEngine.availableAudioUnits.count + 1
        }
        return 0
    }

    func tableView(_ tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard tableView === effectTable else { return nil }
        let result = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MyView"), owner: self) as? NSTableCellView
        if row > 0 && row <= playEngine.availableAudioUnits.count {
            let component = playEngine.availableAudioUnits[row - 1]
            result?.textField!.stringValue = "\(component.name) (\(component.manufacturerName))"
        } else {
            if playEngine.isEffect() {
                result?.textField!.stringValue = "(No effect)"
            } else {
                result?.textField!.stringValue = "(No instrument)"
            }
        }

        return result
    }

    func tableViewSelectionDidChange(_ aNotification: NSNotification) {
        guard let tableView = aNotification.object as? NSTableView else { return }

        if tableView === effectTable {
            self.closeAUView()
            let row = tableView.selectedRow
            let component: AVAudioUnitComponent?

            if row > 0 {
                component = playEngine.availableAudioUnits[row - 1]
                showCustomViewButton.isEnabled = true
            } else {
                component = nil
                showCustomViewButton.isEnabled = false
            }

            playEngine.selectAudioUnitComponent(component, completionHandler: {
                guard let audioUnit = self.playEngine.testAudioUnit else {
                    return
                }

                self.viewConfigurations = [AUAudioUnitViewConfiguration(width: 400,
                                                                        height: 100,
                                                                        hostHasController: false),
                                           // Could also be width: 0 height: 0 in this particular case,
                                           // since this is the largest view.
                                           AUAudioUnitViewConfiguration(width: 800,
                                                                        height: 500,
                                                                        hostHasController: false)]

                let enabled = audioUnit.supportedViewConfigurations(self.viewConfigurations).count >= 2
                self.switchViewModeButton.isEnabled = enabled
            })
        }
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        playEngine.stopPlaying()
    }

    @IBAction func switchViewMode(_ sender: AnyObject?) {
        guard let audioUnit = playEngine.testAudioUnit else {
            return
        }
        let viewConfiguration = viewConfigurations[currentViewConfigurationIndex]
        audioUnit.select(viewConfiguration)
        currentViewConfigurationIndex = (currentViewConfigurationIndex + 1) % viewConfigurations.count

        if !isDisplayingCustomView { return }

        // Adapt the width, but we don't want the list of AU's to get smaller, so leave the height as is
        self.horizontalViewSizeConstraint.constant = viewConfiguration.width
    }

}
