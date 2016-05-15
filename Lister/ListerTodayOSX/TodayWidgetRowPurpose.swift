/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `TodayWidgetRowPurpose` enum and `TodayWidgetRowPurposeBox` class provide a way to represent the reason why a row is being displayed. The `TodayWidgetRowPurposeBox` class boxes an `TodayWidgetRowPurpose` enum to be represented as an object. The `userInfo` property of `TodayWidgetRowPurposeBox` is meant for binding to different properties (e.g. color) that is defined at initialization of the instance.
*/

import Cocoa

/// An enumeration of the different kinds of rows that can be displayed in Lister's OS X Today widget.
enum TodayWidgetRowPurpose {
    case OpenLister
    case RequiresCloud
    case NoItemsInList
}

/**
    A wrapper around a `TodayWidgetRowPurpose` that is used to bind to different objects in the
    `TodayViewController` widget list view controller's row row views.
*/
class TodayWidgetRowPurposeBox: NSObject {
    let purpose: TodayWidgetRowPurpose
    let userInfo: AnyObject?

    init(purpose: TodayWidgetRowPurpose, userInfo: AnyObject? = nil) {
        self.purpose = purpose
        self.userInfo = userInfo
    }
}
