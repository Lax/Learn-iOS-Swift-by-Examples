/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The \c AAPLListDocumentsViewController displays a list of available documents for users to open.
            
*/

@import UIKit;
@import ListerKit;

@interface AAPLListDocumentsViewController : UITableViewController

@property (nonatomic, strong) AAPLListController *listController;

@end
