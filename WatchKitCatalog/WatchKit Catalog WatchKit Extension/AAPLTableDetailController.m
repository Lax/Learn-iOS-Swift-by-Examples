/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This controller displays a table with rows. This controller demonstrates how to insert rows after the intial set of rows has been added and displayed.
 */

#import "AAPLTableDetailController.h"
#import "AAPLTableRowController.h"

@interface AAPLTableDetailController()

@property (weak, nonatomic) IBOutlet WKInterfaceTable *interfaceTable;
@property (strong, nonatomic) NSArray *cityNames;

@end

@implementation AAPLTableDetailController

- (instancetype)init {
    self = [super init];

    if (self) {
        // Initialize variables here.
        // Configure interface objects here.
        
        [self loadTableData];
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

- (void)loadTableData {
    self.cityNames = @[@"Cupertino", @"Sunnyvale", @"Campbell", @"Morgan Hill", @"Mountain View"];
    
    [self.interfaceTable setNumberOfRows:self.cityNames.count withRowType:@"default"];
    
    [self.cityNames enumerateObjectsUsingBlock:^(NSString *citName, NSUInteger idx, BOOL *stop) {
        AAPLTableRowController *row = [self.interfaceTable rowControllerAtIndex:idx];

        [row.rowLabel setText:citName];
    }];
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
    NSArray *newCityNames = @[@"Saratoga", @"San Jose"];

    NSIndexSet *newCityIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(rowIndex + 1, newCityNames.count)];
    
    // Insert new rows into the table.
    [self.interfaceTable insertRowsAtIndexes:newCityIndexes withRowType:@"default"];
    
    // Update the rows that were just inserted with the appropriate data.
    __block NSInteger newCityNumber = 0;
    [newCityIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSString *newCityName = newCityNames[newCityNumber];
        
        AAPLTableRowController *row = [self.interfaceTable rowControllerAtIndex:idx];
        
        [row.rowLabel setText:newCityName];
        
        newCityNumber++;
    }];
}

@end
