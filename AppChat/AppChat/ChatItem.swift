/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The struct that represents a received chat.
 */

import UIKit

typealias ChatItemIdentifier = String

struct ChatItem {
    var identifier: ChatItemIdentifier
    var sender: Friend
    var date: Date
    var image: UIImage
    var saved: Bool
}
