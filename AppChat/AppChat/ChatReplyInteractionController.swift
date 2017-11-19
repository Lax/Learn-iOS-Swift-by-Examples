/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The interaction controller used for interactive presentations of the ChatReplyViewController.
 */

import UIKit

class ChatReplyInteractionController : UIPercentDrivenInteractiveTransition {
    override init() {
        super.init()
        completionSpeed = 2.0
    }
}
