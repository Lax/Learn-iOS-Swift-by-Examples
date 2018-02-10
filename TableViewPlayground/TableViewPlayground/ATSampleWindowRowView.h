/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 ATSampleWindowRowView implementation. This class is used because the NIB has an ATSampleWindowRowView placed in it with a special key of NSTableViewRowViewKey. NSTableView first looks for a view with that key for the row view, if the delegate method tableView:rowViewForRow: is not used.
 */

@import Cocoa;

@interface ATSampleWindowRowView : NSTableRowView

@end
