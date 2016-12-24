/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Types that conform to the `IntentHandler` protocol can be queried as to whether they can handle a specific type of `INIntent`.
*/

import Intents

protocol IntentHandler: class {
    
    func canHandle(_ intent: INIntent) -> Bool
    
}
