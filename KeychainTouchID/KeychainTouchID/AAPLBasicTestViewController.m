/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Test view controller parent for implementing test pages in the test application.
*/

#import "AAPLBasicTestViewController.h"
#import "AAPLTest.h"

@implementation AAPLBasicTestViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    return self;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tests.count;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
    return @"Select test";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"tableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    AAPLTest *test = self.tests[indexPath.row];
    cell.textLabel.text = test.name;
    cell.detailTextLabel.text = test.details;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AAPLTest *test = self.tests[indexPath.row];
    
    // Invoke the selector with the selected test.
    [self performSelector:test.method withObject:nil afterDelay:0.0f];
    [tableView deselectRowAtIndexPath:indexPath animated:YES ];
}

#pragma mark - Convenience

- (void)printMessage:(NSString *)message inTextView:(UITextView *)textView {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Update the result in the main queue because we may be calling from a background queue.
        textView.text = [textView.text stringByAppendingString:[NSString stringWithFormat:@"%@\n", message]];

        [textView scrollRangeToVisible:NSMakeRange([textView.text length], 0)];
    });
}

@end
