/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  The \c AAPLNewListDocumentController class allows users to create a new list document with a name and preferred color.
              
*/

#import "AAPLNewListDocumentController.h"
#import "AAPLListInfo.h"
@import ListerKit;

@interface AAPLNewListDocumentController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIButton *grayButton;
@property (nonatomic, weak) IBOutlet UIButton *blueButton;
@property (nonatomic, weak) IBOutlet UIButton *greenButton;
@property (nonatomic, weak) IBOutlet UIButton *yellowButton;
@property (nonatomic, weak) IBOutlet UIButton *orangeButton;
@property (nonatomic, weak) IBOutlet UIButton *redButton;

@property (nonatomic, weak) IBOutlet UIBarButtonItem *saveButton;

@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@property (nonatomic, weak) UIButton *selectedButton;
@property (nonatomic) AAPLListColor selectedColor;
@property (nonatomic, strong) NSString *selectedTitle;

@end

@implementation AAPLNewListDocumentController

#pragma mark - IBActions

- (IBAction)pickColor:(UIButton *)sender {
    // Use the button's tag to determine the color.
    self.selectedColor = (AAPLListColor)sender.tag;
    
    // Clear out the previously selected button's border.
    self.selectedButton.layer.borderWidth = 0.f;
    
    sender.layer.borderWidth = 5.f;
    sender.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.selectedButton = sender;

    self.titleLabel.textColor = AAPLColorFromListColor(self.selectedColor);
    self.toolbar.tintColor = AAPLColorFromListColor(self.selectedColor);
}

- (IBAction)saveAction:(id)sender {
    AAPLList *list = [[AAPLList alloc] init];
    list.color = self.selectedColor;
    
    [self.listController createListInfoForList:list withName:self.selectedTitle];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *updatedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self updateForProposedListName:updatedText];
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self updateForProposedListName:textField.text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];

    return YES;
}

#pragma mark - Convenience

- (void)updateForProposedListName:(NSString *)name {
    if ([self.listController canCreateListInfoWithName:name]) {
        self.saveButton.enabled = YES;
        self.selectedTitle = name;
    }
}

@end
