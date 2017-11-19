/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A class that provides simulated data for the rest of the app.
 */

import UIKit

class ChatItemManager {
    static let sharedInstance = ChatItemManager()
    
    private(set) var receivedChatItems = [ChatItem]()
    private(set) var friends = [Friend]()
    private(set) var topFriends = [Friend]()
    
    init() {
        self.createSampleData()
    }
    
    func friend(for identifier: FriendIdentifier) -> Friend? {
        return friends.first { (friend: Friend) -> Bool in
            return friend.identifier == identifier
        }
    }
    
    func send(reply: String, to recipient: Friend) {
        // Since AppChat isn't a real chat app yet, we'll just present an alert to simulate sending a reply.
        let format = NSLocalizedString("Reply sent to %@!", comment: "Chat reply sent message format string, the user's name is substituted for the format specifier")
        let message = String(format: format, recipient.name)
        let alert = UIAlertController(title: reply, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK string"), style: .default)
        alert.addAction(okAction)
        UIApplication.shared.present(alert: alert)
    }
    
    func block(user: Friend) {
        // Since AppChat isn't a real chat app yet, we'll just present an alert to simulate blocking a user.
        let title = NSLocalizedString("User Blocked", comment: "User blocked title")
        let messageFormat = NSLocalizedString("The user %@ has been blocked.", comment: "User blocked format string, the user's name is substituted for the format specifier")
        let alert = UIAlertController(title: title, message: String(format: messageFormat, user.name), preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK string"), style: .default)
        alert.addAction(okAction)
        UIApplication.shared.present(alert: alert)
    }
    
    func toggleSaved(chatItem: ChatItem) {
        // Since AppChat isn't a real chat app yet, we'll just present an alert to simulate saving or unsaving a chat.
        let title: String
        let message: String
        if chatItem.saved {
            title = NSLocalizedString("Chat Unsaved", comment: "Chat saved title")
            message = NSLocalizedString("The chat will no longer be saved to your device.", comment: "Chat unsaved message")
        }
        else {
            title = NSLocalizedString("Chat Saved", comment: "Chat saved title")
            message = NSLocalizedString("The chat has been saved to your device.", comment: "Chat unsaved message")
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK string"), style: .default)
        alert.addAction(okAction)
        UIApplication.shared.present(alert: alert)
    }
    
    func createSampleData() {
        let nickJones = Friend(identifier: "0", name: "Nick Jones", profilePhoto: UIImage(named: "ProfilePhoto-NickJones.jpg")!)
        let lexiTorres = Friend(identifier: "1", name: "Lexi Torres", profilePhoto: UIImage(named: "ProfilePhoto-LexiTorres.jpg")!)
        let nataliaMaric = Friend(identifier: "2", name: "Natalia Maric", profilePhoto: UIImage(named: "ProfilePhoto-NataliaMaric.jpg")!)
        let peterUrso = Friend(identifier: "3", name: "Peter Urso", profilePhoto: UIImage(named: "ProfilePhoto-PeterUrso.jpg")!)
        let tamsinVantress = Friend(identifier: "4", name: "Tamsin Vantress", profilePhoto: UIImage(named: "ProfilePhoto-TamsinVantress.jpg")!)
        
        friends = [nickJones, lexiTorres, nataliaMaric, peterUrso, tamsinVantress]
        topFriends = [lexiTorres, nataliaMaric, peterUrso]
        
        let chat1 = ChatItem(identifier: "8", sender: tamsinVantress, date: getDate(secondsAgo: 10), image: UIImage(named: "ChatImage-1.jpg")!, saved: false)
        let chat2 = ChatItem(identifier: "7", sender: lexiTorres, date: getDate(minutesAgo: 2), image: UIImage(named: "ChatImage-2.jpg")!, saved: false)
        let chat3 = ChatItem(identifier: "6", sender: nataliaMaric, date: getDate(minutesAgo: 5), image: UIImage(named: "ChatImage-3.jpg")!, saved: false)
        let chat4 = ChatItem(identifier: "5", sender: nickJones, date: getDate(minutesAgo: 42), image: UIImage(named: "ChatImage-4.jpg")!, saved: true)
        let chat5 = ChatItem(identifier: "4", sender: peterUrso, date: getDate(hoursAgo: 1), image: UIImage(named: "ChatImage-5.jpg")!, saved: false)
        let chat6 = ChatItem(identifier: "3", sender: nataliaMaric, date: getDate(hoursAgo: 4), image: UIImage(named: "ChatImage-6.jpg")!, saved: true)
        let chat7 = ChatItem(identifier: "2", sender: tamsinVantress, date: getDate(hoursAgo: 14), image: UIImage(named: "ChatImage-7.jpg")!, saved: true)
        let chat8 = ChatItem(identifier: "1", sender: nataliaMaric, date: getDate(daysAgo: 1), image: UIImage(named: "ChatImage-8.jpg")!, saved: true)
        let chat9 = ChatItem(identifier: "0", sender: peterUrso, date: getDate(daysAgo: 3), image: UIImage(named: "ChatImage-9.jpg")!, saved: true)
        
        receivedChatItems = [chat1, chat2, chat3, chat4, chat5, chat6, chat7, chat8, chat9]
    }
}
