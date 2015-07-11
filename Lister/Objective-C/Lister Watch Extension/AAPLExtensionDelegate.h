/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLExtensionDelegate that manages app level behavior for the WatchKit extension.
*/

@import WatchKit;

@interface AAPLExtensionDelegate : NSObject <WKExtensionDelegate>

/*!
    The extension's main interface controller; who is responsible for assigning itself to this property. In
    order to enable appropriate messages to be relayed to it from the extension delegate.
 */
@property (nonatomic,strong) WKInterfaceController *mainInterfaceController;

@end
