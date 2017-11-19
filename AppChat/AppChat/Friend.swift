/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The struct that represents another user.
 */

import UIKit

typealias FriendIdentifier = String

struct Friend {
    var identifier: FriendIdentifier
    var name: String
    var profilePhoto: UIImage
}
