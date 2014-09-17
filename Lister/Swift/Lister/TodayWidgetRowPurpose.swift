/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The `TodayWidgetRowPurpose` enum and `TodayWidgetRowPurposeBox` class provide a way to represent the reason why a row is being displayed. The `TodayWidgetRowPurposeBox` class boxes an `TodayWidgetRowPurpose` enum to be represented as an object. The `userInfo` property of `TodayWidgetRowPurposeBox` is meant for binding to different properties (e.g. color) that is defined at initialization of the instance.
            
*/

import Cocoa

enum TodayWidgetRowPurpose {
    case OpenLister
    case RequiresCloud
    case NoItemsInList
}

class TodayWidgetRowPurposeBox: NSObject {
    let purpose: TodayWidgetRowPurpose
    let userInfo: AnyObject?

    init(purpose: TodayWidgetRowPurpose, userInfo: AnyObject? = nil) {
        self.purpose = purpose
        self.userInfo = userInfo
    }
}
