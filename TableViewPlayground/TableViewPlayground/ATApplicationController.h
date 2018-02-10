/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The main demo application controller. This class is the delegate for the main NSApp instance. This class manages the windows that are open, and allows the user to create a new one with the 'Available Sample Windows' table view. Bindings are used in the 'Available Sample Windows' table for the content. The TableView is bound to the tableContents, which is an array of NSDictionary objects that contain the information to disply.
 */

@import Cocoa;

@interface ATApplicationController : NSObject

@end
