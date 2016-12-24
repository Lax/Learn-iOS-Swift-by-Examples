/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Model class representing a single call
*/

import Foundation

final class SpeakerboxCall {

    // MARK: Metadata Properties

    let uuid: UUID
    let isOutgoing: Bool
    var handle: String?

    // MARK: Call State Properties

    var connectingDate: Date? {
        didSet {
            stateDidChange?()
            hasStartedConnectingDidChange?()
        }
    }
    var connectDate: Date? {
        didSet {
            stateDidChange?()
            hasConnectedDidChange?()
        }
    }
    var endDate: Date? {
        didSet {
            stateDidChange?()
            hasEndedDidChange?()
        }
    }
    var isOnHold = false {
        didSet {
            stateDidChange?()
        }
    }

    // MARK: State change callback blocks

    var stateDidChange: (() -> Void)?
    var hasStartedConnectingDidChange: (() -> Void)?
    var hasConnectedDidChange: (() -> Void)?
    var hasEndedDidChange: (() -> Void)?

    // MARK: Derived Properties

    var hasStartedConnecting: Bool {
        get {
            return connectingDate != nil
        }
        set {
            connectingDate = newValue ? Date() : nil
        }
    }
    var hasConnected: Bool {
        get {
            return connectDate != nil
        }
        set {
            connectDate = newValue ? Date() : nil
        }
    }
    var hasEnded: Bool {
        get {
            return endDate != nil
        }
        set {
            endDate = newValue ? Date() : nil
        }
    }
    var duration: TimeInterval {
        guard let connectDate = connectDate else {
            return 0
        }

        return Date().timeIntervalSince(connectDate)
    }

    // MARK: Initialization

    init(uuid: UUID, isOutgoing: Bool = false) {
        self.uuid = uuid
        self.isOutgoing = isOutgoing
    }

    // MARK: Actions

    func startSpeakerboxCall(completion: ((_ success: Bool) -> Void)?) {
        // Simulate the call starting successfully
        completion?(true)

        /*
            Simulate the "started connecting" and "connected" states using artificial delays, since
            the example app is not backed by a real network service
         */
        DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + 3) {
            self.hasStartedConnecting = true

            DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + 1.5) {
                self.hasConnected = true
            }
        }
    }

    func answerSpeakerboxCall() {
        /*
            Simulate the answer becoming connected immediately, since
            the example app is not backed by a real network service
         */
        hasConnected = true
    }

    func endSpeakerboxCall() {
        /*
            Simulate the end taking effect immediately, since
            the example app is not backed by a real network service
         */
        hasEnded = true
    }

}
