/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Application Delegate for ImageMessages
  Registers for notifications and will notify the AAPLTableViewController when it receives an update
  
 */

@import UIKit;

@class AAPLTableViewController;

@interface AAPLAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (weak) IBOutlet AAPLTableViewController *tableController;

@end

