/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Extension to allow creating a CallKit CXStartCallAction from an NSUserActivity which the app was launched with
*/

import Foundation
import Intents

extension NSUserActivity: StartCallConvertible {

    var startCallHandle: String? {
        guard
          let interaction = interaction,
          let startCallIntent = interaction.intent as? SupportedStartCallIntent,
          let contact = startCallIntent.contacts?.first
        else {
            return nil
        }

        return contact.personHandle?.value
    }

    var video: Bool? {
        guard
          let interaction = interaction,
          let startCallIntent = interaction.intent as? SupportedStartCallIntent
        else {
            return nil
        }

        return startCallIntent is INStartVideoCallIntent
    }
    
}

protocol SupportedStartCallIntent {
    var contacts: [INPerson]? { get }
}

extension INStartAudioCallIntent: SupportedStartCallIntent {}
extension INStartVideoCallIntent: SupportedStartCallIntent {}
