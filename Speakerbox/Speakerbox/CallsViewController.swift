/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	View controller which displays list of calls
*/

import UIKit

final class CallsViewController: UITableViewController {

    var callManager: SpeakerboxCallManager?

    var callDurationTimer: Timer?
    lazy var callDurationFormatter = CallDurationFormatter()

    // MARK: Actions

    @IBAction func unwindForDialCallSegue(_ segue: UIStoryboardSegue) {
        let dialOptionsViewController = segue.source as! DialOptionsViewController

        if let handle = dialOptionsViewController.handle {
            let video = dialOptionsViewController.video
            callManager?.startCall(handle: handle, video: video)
        }
    }

    @IBAction func unwindForSimulateIncomingCallSegue(_ segue: UIStoryboardSegue) {
        let simulateIncomingCallViewController = segue.source as! SimulateIncomingCallViewController

        guard let handle = simulateIncomingCallViewController.handle else { return }
        let video = simulateIncomingCallViewController.video
        let delay = simulateIncomingCallViewController.delay

        /*
            Since the app may be suspended while waiting for the delayed action to begin,
            start a background task.
         */
        let backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + delay) {
            AppDelegate.shared.displayIncomingCall(uuid: UUID(), handle: handle, hasVideo: video) { _ in
                UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            }
        }
    }

    // MARK: Helpers

    private func updateCallsDependentUI(animated: Bool) {
        updateCallDurationTimer()
    }

    private func call(at indexPath: IndexPath) -> SpeakerboxCall? {
        return callManager?.calls[indexPath.row]
    }

    // MARK: Call Duration Timer

    private func updateCallDurationTimer() {
        let callCount = callManager?.calls.count ?? 0

        if callCount > 0 && callDurationTimer == nil {
            callDurationTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(callDurationTimerFired), userInfo: nil, repeats: true)
        } else if callCount == 0 && callDurationTimer != nil {
            callDurationTimer?.invalidate()
            callDurationTimer = nil
        }
    }

    func callDurationTimerFired() {
        updateCallDurationForVisibleCells()
    }

    private func updateCallDurationForVisibleCells() {
        /*
            Modify all the visible cells directly, since -[UITableView reloadData] resets a lot
            of things on the table view like selection & editing states
         */
        let visibleCells = tableView.visibleCells as! [CallSummaryTableViewCell]
        guard let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows else { return }

        for index in 0..<visibleCells.count {
            let cell = visibleCells[index]
            let indexPath = indexPathsForVisibleRows[index]

            guard let call = call(at: indexPath) else { return }
            cell.durationLabel?.text = durationLabelText(forCall: call)
        }
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        callManager = AppDelegate.shared.callManager
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(handleCallsChangedNotification(notification:)), name: SpeakerboxCallManager.CallsChangedNotification, object: nil)

        updateCallsDependentUI(animated: animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: SpeakerboxCallManager.CallsChangedNotification, object: nil)

        callDurationTimer?.invalidate()
        callDurationTimer = nil
    }

    // MARK: UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return callManager?.calls.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CallSummary") as! CallSummaryTableViewCell

        guard let call = call(at: indexPath) else {
            return cell
        }

        cell.handleLabel?.text = call.handle

        let accessoryLabelsTextColor = call.isOnHold ? UIColor.gray : cell.tintColor

        if call.hasConnected {
            cell.callStatusTextLabel?.text = call.isOnHold ? NSLocalizedString("CALL_STATUS_HELD", comment: "Call status label for on hold") : NSLocalizedString("CALL_STATUS_ACTIVE", comment: "Call status label for active")
        } else if call.hasStartedConnecting {
            cell.callStatusTextLabel?.text = NSLocalizedString("CALL_STATUS_CONNECTING", comment: "Call status label for on hold")
        } else {
            cell.callStatusTextLabel?.text = call.isOutgoing ? NSLocalizedString("CALL_STATUS_SENDING", comment: "Call status label for sending") : NSLocalizedString("CALL_STATUS_RINGING", comment: "Call status label for ringing")
        }

        cell.callStatusTextLabel?.textColor = accessoryLabelsTextColor

        cell.durationLabel?.text = durationLabelText(forCall: call)
        cell.durationLabel?.font = cell.durationLabel?.font.addingMonospacedNumberAttributes
        cell.durationLabel?.textColor = accessoryLabelsTextColor

        return cell
    }

    private func durationLabelText(forCall call: SpeakerboxCall) -> String? {
        return call.hasConnected ? callDurationFormatter.format(timeInterval: call.duration) : nil
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let call = call(at: indexPath) else {
            return
        }

        call.isOnHold = !call.isOnHold
        callManager?.setHeld(call: call, onHold: call.isOnHold)

        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return NSLocalizedString("TABLE_CELL_EDIT_ACTION_END", comment: "End button in call summary table view cell")
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let call = call(at: indexPath) {
                print("Requesting to end call: \(call)")
                callManager?.end(call: call)
            } else {
                print("No call found at indexPath: \(indexPath)")
            }
        }
    }

    // MARK: CXCallObserverDelegate

    func handleCallsChangedNotification(notification: NSNotification) {
        tableView.reloadData()
        updateCallsDependentUI(animated: true)
    }

}
