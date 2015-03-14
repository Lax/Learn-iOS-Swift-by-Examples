/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This is the initial interface controller for the WatchKit app. It loads the initial table of the app with data and responds to Handoff launching the WatchKit app.
 */

#import "AAPLInterfaceController.h"
#import "AAPLElementRowController.h"

@interface AAPLInterfaceController()

@property (weak, nonatomic) IBOutlet WKInterfaceTable *interfaceTable;

@property (strong, nonatomic) NSArray *elementsList;

@end


@implementation AAPLInterfaceController

- (instancetype)init {
    self = [super init];
    
    if (self) {
        // Initialize variables here.
        // Configure interface objects here.
        
        // Retrieve the data. This could be accessed from the iOS app via a shared container.
        self.elementsList = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AppData" ofType:@"plist"]];
        
        [self loadTableRows];
    }

    return self;
}

- (void)willActivate {
    // This method is called when the controller is about to be visible to the wearer.
    NSLog(@"%@ will activate", self);
}

- (void)didDeactivate {
    // This method is called when the controller is no longer visible.
    NSLog(@"%@ did deactivate", self);
}

- (void)handleUserActivity:(NSDictionary *)userInfo {
    // Use data from the userInfo dictionary passed in to push to the appropriate controller with detailed info.
    [self pushControllerWithName:userInfo[@"controllerName"] context:userInfo[@"detailInfo"]];
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
    NSDictionary *rowData = self.elementsList[rowIndex];

    [self pushControllerWithName:rowData[@"controllerIdentifier"] context:nil];
}

- (void)loadTableRows {
    [self.interfaceTable setNumberOfRows:self.elementsList.count withRowType:@"default"];
    
    // Create all of the table rows.
    [self.elementsList enumerateObjectsUsingBlock:^(NSDictionary *rowData, NSUInteger idx, BOOL *stop) {
        AAPLElementRowController *elementRow = [self.interfaceTable rowControllerAtIndex:idx];
        
        [elementRow.elementLabel setText:rowData[@"label"]];
    }];
}

@end
