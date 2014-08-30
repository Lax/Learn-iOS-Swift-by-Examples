/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
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

// There are many different types of keyboards that you may choose to use.
// The different types of keyboards are defined in UITextInputTraits.h.
// This example shows how to display a keyboard to help enter email addresses.
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


#pragma mark - Actions

- (void)customTextFieldPurpleButtonClicked {
    self.customTextField.textColor = [UIColor aapl_applicationPurpleColor];

    NSLog(@"The custom text field's purple right view button was clicked.");
}

@end
