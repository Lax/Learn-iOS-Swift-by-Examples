/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller that demonstrates how to use UITextField.
*/

#import "AAPLTextFieldViewController.h"

@interface AAPLTextFieldViewController()<UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UITextField *tintedTextField;
@property (nonatomic, weak) IBOutlet UITextField *secureTextField;
@property (nonatomic, weak) IBOutlet UITextField *specificKeyboardTextField;
@property (nonatomic, weak) IBOutlet UITextField *customTextField;

@end


#pragma mark -

@implementation AAPLTextFieldViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureTextField];
    [self configureTintedTextField];
    [self configureSecureTextField];
    [self configureSpecificKeyboardTextField];
    [self configureCustomTextField];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Listen for changes to keyboard visibility so that we can adjust the text view accordingly.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardNotification:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardNotification:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}


#pragma mark - Configuration

- (void)configureTextField {
    self.textField.placeholder = NSLocalizedString(@"Placeholder text", nil);
    self.textField.autocorrectionType = UITextAutocorrectionTypeYes;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.clearButtonMode = UITextFieldViewModeNever;
}

- (void)configureTintedTextField {
    self.tintedTextField.tintColor = [UIColor aapl_applicationBlueColor];
    self.tintedTextField.textColor = [UIColor aapl_applicationGreenColor];

    self.tintedTextField.placeholder = NSLocalizedString(@"Placeholder text", nil);
    self.tintedTextField.returnKeyType = UIReturnKeyDone;
    self.tintedTextField.clearButtonMode = UITextFieldViewModeNever;
}

- (void)configureSecureTextField {
    self.secureTextField.secureTextEntry = YES;

    self.secureTextField.placeholder = NSLocalizedString(@"Placeholder text", nil);
    self.secureTextField.returnKeyType = UIReturnKeyDone;
    self.secureTextField.clearButtonMode = UITextFieldViewModeAlways;
}

/**
    There are many different types of keyboards that you may choose to use.
    The different types of keyboards are defined in UITextInputTraits.h.
    This example shows how to display a keyboard to help enter email addresses.
*/
- (void)configureSpecificKeyboardTextField {
    self.specificKeyboardTextField.keyboardType = UIKeyboardTypeEmailAddress;

    self.specificKeyboardTextField.placeholder = NSLocalizedString(@"Placeholder text", nil);
    self.specificKeyboardTextField.returnKeyType = UIReturnKeyDone;
}

- (void)configureCustomTextField {
    // Text fields with custom image backgrounds must have no border.
    self.customTextField.borderStyle = UITextBorderStyleNone;
    
    self.customTextField.background = [UIImage imageNamed:@"text_field_background"];
    
    // Create a purple button that, when selected, turns the custom text field's text color to purple.
    UIImage *purpleImage = [UIImage imageNamed:@"text_field_purple_right_view"];
    UIButton *purpleImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    purpleImageButton.bounds = CGRectMake(0, 0, purpleImage.size.width, purpleImage.size.height);
    purpleImageButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 5);
    [purpleImageButton setImage:purpleImage forState:UIControlStateNormal];
    [purpleImageButton addTarget:self action:@selector(customTextFieldPurpleButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    self.customTextField.rightView = purpleImageButton;
    self.customTextField.rightViewMode = UITextFieldViewModeAlways;

    // Add an empty view as the left view to ensure inset between the text and the bounding rectangle.
    UIView *leftPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 0)];
    leftPaddingView.backgroundColor = [UIColor clearColor];
    self.customTextField.leftView = leftPaddingView;
    self.customTextField.leftViewMode = UITextFieldViewModeAlways;

    self.customTextField.placeholder = NSLocalizedString(@"Placeholder text", nil);
    self.customTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.customTextField.returnKeyType = UIReturnKeyDone;
}


#pragma mark - UITextFieldDelegate (set in Interface Builder)

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}


#pragma mark - Keyboard Event Notifications

- (void)handleKeyboardNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    
    // Get information about the animation.
    NSTimeInterval animationDuration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    // Convert the keyboard frame from screen to view coordinates.
    CGRect keyboardScreenBeginFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect keyboardScreenEndFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGRect keyboardViewBeginFrame = [self.view convertRect:keyboardScreenBeginFrame fromView:self.view.window];
    CGRect keyboardViewEndFrame = [self.view convertRect:keyboardScreenEndFrame fromView:self.view.window];
    
    // Determine how far the keyboard has moved up or down.
    CGFloat originDelta = keyboardViewEndFrame.origin.y - keyboardViewBeginFrame.origin.y;
    
    // Calculate new scroll indicator and content insets for the table view.
    UIEdgeInsets newIndicatorInsets = self.tableView.scrollIndicatorInsets;
    newIndicatorInsets.bottom -= originDelta;
    
    UIEdgeInsets newContentInsets = self.tableView.contentInset;
    newContentInsets.bottom -= originDelta;
    
    // Update the insets on the table view with the new values.
    self.tableView.scrollIndicatorInsets = newIndicatorInsets;
    self.tableView.contentInset = newContentInsets;

    // Inform the view that its the layout should be updated.
    [self.view setNeedsLayout];
    
    // Animate updating the view's layout by calling `layoutIfNeeded` inside a `UIView` animation block.
    UIViewAnimationOptions animationOptions = animationCurve | UIViewAnimationOptionBeginFromCurrentState;
    [UIView animateWithDuration:animationDuration delay:0 options:animationOptions animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}


#pragma mark - Actions

- (void)customTextFieldPurpleButtonClicked {
    self.customTextField.textColor = [UIColor aapl_applicationPurpleColor];

    NSLog(@"The custom text field's purple right view button was clicked.");
}

@end
