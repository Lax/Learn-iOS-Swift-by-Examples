/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Home screen quick action creation and handling.
 */

import UIKit
import ContactsUI

enum ShortcutItemType: String {
    case newChat
    case sendChatTo
    
    private static let prefix: String = {
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        return bundleIdentifier + "."
    }()
    
    init?(prefixedString: String) {
        guard let prefixRange = prefixedString.range(of: ShortcutItemType.prefix) else { return nil }
        var rawTypeString = prefixedString
        rawTypeString.removeSubrange(prefixRange)
        self.init(rawValue: rawTypeString)
    }
    
    var prefixedString: String {
        return type(of: self).prefix + self.rawValue
    }
}

struct ShortcutItemUserInfo {
    static let friendIdentifierKey = "friendIdentifier"
    var friendIdentifier: FriendIdentifier?
    
    init(friendIdentifier: FriendIdentifier? = nil) {
        self.friendIdentifier = friendIdentifier
    }
    
    init(dictionaryRepresentation: [String : NSSecureCoding]?) {
        guard let dictionary = dictionaryRepresentation else { return }
        self.friendIdentifier = (dictionary[ShortcutItemUserInfo.friendIdentifierKey] as! NSString) as FriendIdentifier
    }
    
    var dictionaryRepresentation: [String : NSSecureCoding] {
        var dictionary: [String : NSSecureCoding] = [:]
        if let friendIdentifier = friendIdentifier {
            dictionary[ShortcutItemUserInfo.friendIdentifierKey] = friendIdentifier as NSString
        }
        return dictionary
    }
}

struct ShortcutItemHandler {
    static private func grantedAccessToContacts() -> Bool {
        return CNContactStore.authorizationStatus(for: .contacts) == .authorized
    }
    
    static private func requestAccessToContactsIfNeeded(_ application: UIApplication) {
        guard CNContactStore.authorizationStatus(for: .contacts) == .notDetermined else { return }
        
        CNContactStore().requestAccess(for: .contacts) { (granted: Bool, error: Error?) in
            if granted {
                DispatchQueue.main.async {
                    updateDynamicShortcutItems(for: application)
                }
            }
        }
    }
    
    /// Updates the registered dynamic shortcut items for the app.
    static func updateDynamicShortcutItems(for application: UIApplication) {
        requestAccessToContactsIfNeeded(application)
        
        var shortcutItems = [UIApplicationShortcutItem]()
        
        let top3Friends = ChatItemManager.sharedInstance.topFriends.prefix(3)
        for friend in top3Friends {
            let type = ShortcutItemType.sendChatTo
            let title = friend.name
            let subtitle = NSLocalizedString("Send a chat", comment: "Send a chat to a specific friend")
            
            // If we can find a matching contact for the friend use that for the icon, otherwise use the default Message system icon.
            var icon = UIApplicationShortcutIcon(type: .message)
            if grantedAccessToContacts() {
                let predicate = CNContact.predicateForContacts(matchingName: friend.name)
                let contacts = try? CNContactStore().unifiedContacts(matching: predicate, keysToFetch: [])
                if let contact = contacts?.first {
                    icon = UIApplicationShortcutIcon(contact: contact)
                }
            }
            
            let userInfo = ShortcutItemUserInfo(friendIdentifier: friend.identifier)
            let shortcutItem = UIApplicationShortcutItem(type: type.prefixedString, localizedTitle: title, localizedSubtitle: subtitle, icon: icon, userInfo:userInfo.dictionaryRepresentation)
            shortcutItems.append(shortcutItem)
        }
        
        application.shortcutItems = shortcutItems
    }
    
    /// Attempt to handle the shortcut item by navigating to the appropriate view controller. Returns whether the shortcut item was handled.
    static func handle(_ shortcutItem: UIApplicationShortcutItem, with rootViewController: UIViewController) -> Bool {
        guard NewChatDelegate.isCameraAvailable() else { return false }
        guard let shortcutItemType = ShortcutItemType(prefixedString: shortcutItem.type) else { return false }
        
        let friend: Friend?
        
        switch shortcutItemType {
        case .newChat:
            friend = nil
        case .sendChatTo:
            let userInfo = ShortcutItemUserInfo(dictionaryRepresentation: shortcutItem.userInfo)
            if let friendIdentifier = userInfo.friendIdentifier {
                friend = ChatItemManager.sharedInstance.friend(for: friendIdentifier)
            }
            else {
                friend = nil
            }
        }
        
        guard let navigationController = rootViewController as? UINavigationController else { return false }
        navigationController.popToRootViewController(animated: false)
        guard let chatTableViewController = navigationController.topViewController as? ChatTableViewController else { return false }
        
        chatTableViewController.view.isHidden = true
        chatTableViewController.presentNewChatController(for: friend, animated: false) {
            chatTableViewController.view.isHidden = false
        }
        return true
    }
}
