/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Implements LocalAuthentication framework demo.
*/

#import "AAPLLocalAuthenticationTestsViewController.h"

@import LocalAuthentication;

@implementation AAPLLocalAuthenticationTestsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Prepare the actions which can be tested in this class.
    self.tests = @[
       [[AAPLTest alloc] initWithName:@"Touch ID preflight" details:@"Using canEvaluatePolicy:" selector:@selector(canEvaluatePolicy)],
       [[AAPLTest alloc] initWithName:@"Touch ID authentication" details:@"Using evaluatePolicy:" selector:@selector(evaluatePolicy)],
       [[AAPLTest alloc] initWithName:@"Touch ID authentication with custom text" details:@"Using evaluatePolicy:" selector:@selector(evaluatePolicy2)]
    ];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.textView scrollRangeToVisible:NSMakeRange(self.textView.text.length, 0)];
}

-(void)viewDidLayoutSubviews
{
    // Set the proper size for the table view based on its content.
    CGFloat height = MIN(self.view.bounds.size.height, self.tableView.contentSize.height);
    self.dynamicViewHeight.constant = height;
    [self.view layoutIfNeeded];
}

#pragma mark - Tests

- (void)canEvaluatePolicy {
    LAContext *context = [[LAContext alloc] init];
    __block  NSString *message;
    NSError *error;
    BOOL success;
    
    // test if we can evaluate the policy, this test will tell us if Touch ID is available and enrolled
    success = [context canEvaluatePolicy: LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    if (success) {
        message = [NSString stringWithFormat:@"Touch ID is available"];
    }
    else {
        message = [NSString stringWithFormat:@"Touch ID is not available"];
    }
    
    [super printMessage:message inTextView:self.textView];
}

- (void)evaluatePolicy {
    LAContext *context = [[LAContext alloc] init];
    __block  NSString *message;
    
    // Show the authentication UI with our reason string.
    [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"Unlock access to locked feature" reply:^(BOOL success, NSError *authenticationError) {
         if (success) {
             message = @"evaluatePolicy: succes";
         }
         else {
             message = [NSString stringWithFormat:@"evaluatePolicy: %@", authenticationError.localizedDescription];
         }

         [self printMessage:message inTextView:self.textView];
     }];
}

- (void)evaluatePolicy2 {
    LAContext *context = [[LAContext alloc] init];
    __block NSString *message;
    
    // Set text for the localized fallback button.
    context.localizedFallbackTitle = @"Enter PIN";
    
    // Show the authentication UI with our reason string.
    [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"Unlock access to locked feature" reply:^(BOOL success, NSError *authenticationError) {
         if (success) {
             message = @"evaluatePolicy: succes";
         }
         else {
             message = [NSString stringWithFormat:@"evaluatePolicy: %@", authenticationError.localizedDescription];
         }
         
         [self printMessage:message inTextView:self.textView];
     }];
}

@end
