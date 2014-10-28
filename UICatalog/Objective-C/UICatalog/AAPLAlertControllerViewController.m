/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The view controller that demonstrates how to use UIAlertController.
  
*/

#import "AAPLAlertControllerViewController.h"

// Corresponds to the section index of the table view (whether we want to show an alert or action sheet style).
typedef NS_ENUM(NSInteger, AAPLAlertControllerSection) {
    AAPLAlertControllerSectionAlert = 0,
    AAPLAlertControllerSectionActionSheet
};

// Corresponds to the row in the alert style section.
typedef NS_ENUM(NSInteger, AAPLAlertControllerAlertRow) {
    AAPLAlertControllerAlertRowSimple = 0,
    AAPLAlertControllerAlertRowOkayCancel,
    AAPLAlertControllerAlertRowOther,
    AAPLAlertControllerAlertRowTextEntry,
    AAPLAlertControllerAlertRowTextEntrySecure
};

// Corresponds to the row in the action sheet style section.
typedef NS_ENUM(NSInteger, AAPLAlertControllerActionSheetRow) {
    AAPLAlertControllerActionSheetRowOkayCancel = 0,
    AAPLAlertControllerActionSheetRowOther
};

@interface AAPLAlertControllerViewController() <UITextFieldDelegate>

// Maintains a reference to the alert action that should be toggled when the text field changes (for the secure text entry alert).
@property (nonatomic, weak) UIAlertAction *secureTextAlertAction;

@end


#pragma mark -

@implementation AAPLAlertControllerViewController

#pragma mark - UIAlertControllerStyleAlert Style Alerts

// Show an alert with an "Okay" button.
- (void)showSimpleAlert {
    NSString *title = NSLocalizedString(@"A Short Title Is Best", nil);
    NSString *message = NSLocalizedString(@"A message should be a short, complete sentence.", nil);
    NSString *cancelButtonTitle = NSLocalizedString(@"OK", nil);

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    // Create the action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        NSLog(@"The simple alert's cancel action occured.");
    }];

    // Add the action.
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// Show an alert with an "Okay" and "Cancel" button.
- (void)showOkayCancelAlert {
    NSString *title = NSLocalizedString(@"A Short Title Is Best", nil);
    NSString *message = NSLocalizedString(@"A message should be a short, complete sentence.", nil);
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", nil);
    NSString *otherButtonTitle = NSLocalizedString(@"OK", nil);

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    // Create the actions.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        NSLog(@"The \"Okay/Cancel\" alert's cancel action occured.");
    }];
    
    UIAlertAction *otherAction = [UIAlertAction actionWithTitle:otherButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSLog(@"The \"Okay/Cancel\" alert's other action occured.");
    }];
    
    // Add the actions.
    [alertController addAction:cancelAction];
    [alertController addAction:otherAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// Show an alert with two custom buttons.
- (void)showOtherAlert {
    NSString *title = NSLocalizedString(@"A Short Title Is Best", nil);
    NSString *message = NSLocalizedString(@"A message should be a short, complete sentence.", nil);
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", nil);
    NSString *otherButtonTitleOne = NSLocalizedString(@"Choice One", nil);
    NSString *otherButtonTitleTwo = NSLocalizedString(@"Choice Two", nil);

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    // Create the actions.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        NSLog(@"The \"Other\" alert's cancel action occured.");
    }];
    
    UIAlertAction *otherButtonOneAction = [UIAlertAction actionWithTitle:otherButtonTitleOne style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSLog(@"The \"Other\" alert's other button one action occured.");
    }];
    
    UIAlertAction *otherButtonTwoAction = [UIAlertAction actionWithTitle:otherButtonTitleTwo style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSLog(@"The \"Other\" alert's other button two action occured.");
    }];
    
    // Add the actions.
    [alertController addAction:cancelAction];
    [alertController addAction:otherButtonOneAction];
    [alertController addAction:otherButtonTwoAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// Show a text entry alert with two custom buttons.
- (void)showTextEntryAlert {
    NSString *title = NSLocalizedString(@"A Short Title Is Best", nil);
    NSString *message = NSLocalizedString(@"A message should be a short, complete sentence.", nil);
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", nil);
    NSString *otherButtonTitle = NSLocalizedString(@"OK", nil);

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    // Add the text field for text entry.
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        // If you need to customize the text field, you can do so here.
    }];
    
    // Create the actions.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        NSLog(@"The \"Text Entry\" alert's cancel action occured.");
    }];
    
    UIAlertAction *otherAction = [UIAlertAction actionWithTitle:otherButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSLog(@"The \"Text Entry\" alert's other action occured.");
    }];

    // Add the actions.
    [alertController addAction:cancelAction];
    [alertController addAction:otherAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// Show a secure text entry alert with two custom buttons.
- (void)showSecureTextEntryAlert {
    NSString *title = NSLocalizedString(@"A Short Title Is Best", nil);
    NSString *message = NSLocalizedString(@"A message should be a short, complete sentence.", nil);
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", nil);
    NSString *otherButtonTitle = NSLocalizedString(@"OK", nil);

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    // Add the text field for the secure text entry.
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        // Listen for changes to the text field's text so that we can toggle the current
        // action's enabled property based on whether the user has entered a sufficiently
        // secure entry.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTextFieldTextDidChangeNotification:) name:UITextFieldTextDidChangeNotification object:textField];

        textField.secureTextEntry = YES;
    }];

    // Create the actions.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        NSLog(@"The \"Secure Text Entry\" alert's cancel action occured.");

        // Stop listening for text changed notifications.
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:alertController.textFields.firstObject];
    }];

    UIAlertAction *otherAction = [UIAlertAction actionWithTitle:otherButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSLog(@"The \"Secure Text Entry\" alert's other action occured.");

        // Stop listening for text changed notifications.
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:alertController.textFields.firstObject];
    }];
    
    // The text field initially has no text in the text field, so we'll disable it.
    otherAction.enabled = NO;

    // Hold onto the secure text alert action to toggle the enabled/disabled state when the text changed.
    self.secureTextAlertAction = otherAction;

    // Add the actions.
    [alertController addAction:cancelAction];
    [alertController addAction:otherAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - UIAlertControllerStyleActionSheet Style Alerts

// Show a dialog with an "Okay" and "Cancel" button.
- (void)showOkayCancelActionSheet:(NSIndexPath *)selectedPath {
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", nil);
    NSString *destructiveButtonTitle = NSLocalizedString(@"OK", nil);
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // Create the actions.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        NSLog(@"The \"Okay/Cancel\" alert action sheet's cancel action occured.");
    }];
    
    UIAlertAction *destructiveAction = [UIAlertAction actionWithTitle:destructiveButtonTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        NSLog(@"The \"Okay/Cancel\" alert action sheet's destructive action occured.");
    }];
    
    // Add the actions.
    [alertController addAction:cancelAction];
    [alertController addAction:destructiveAction];
    
    // Configure the alert controller's popover presentation controller if it has one.
    UIPopoverPresentationController *popoverPresentationController = [alertController popoverPresentationController];
    if (popoverPresentationController) {
        UITableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:selectedPath];
        popoverPresentationController.sourceRect = selectedCell.frame;
        popoverPresentationController.sourceView = self.view;
        popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
    }
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// Show a dialog with two custom buttons.
- (void)showOtherActionSheet:(NSIndexPath *)selectedPath {
    NSString *destructiveButtonTitle = NSLocalizedString(@"Destructive Choice", nil);
    NSString *otherButtonTitle = NSLocalizedString(@"Safe Choice", nil);
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // Create the actions.
    UIAlertAction *destructiveAction = [UIAlertAction actionWithTitle:destructiveButtonTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        NSLog(@"The \"Other\" alert action sheet's destructive action occured.");
    }];
    
    UIAlertAction *otherAction = [UIAlertAction actionWithTitle:otherButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSLog(@"The \"Other\" alert action sheet's other action occured.");
    }];
    
    // Add the actions.
    [alertController addAction:destructiveAction];
    [alertController addAction:otherAction];
    
    // Configure the alert controller's popover presentation controller if it has one.
    UIPopoverPresentationController *popoverPresentationController = [alertController popoverPresentationController];
    if (popoverPresentationController) {
        UITableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:selectedPath];
        popoverPresentationController.sourceRect = selectedCell.frame;
        popoverPresentationController.sourceView = self.view;
        popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
    }

    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITextFieldTextDidChangeNotification

- (void)handleTextFieldTextDidChangeNotification:(NSNotification *)notification {
    UITextField *textField = notification.object;

    // Enforce a minimum length of >= 5 characters for secure text alerts.
    self.secureTextAlertAction.enabled = textField.text.length >= 5;
}

#pragma mark - UITableViewDelegate

// Determine the action to perform based on the selected cell.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AAPLAlertControllerSection section = indexPath.section;
    
    if (AAPLAlertControllerSectionAlert == section) {
        AAPLAlertControllerAlertRow row = indexPath.row;
        
        switch (row) {
            case AAPLAlertControllerAlertRowSimple:
                [self showSimpleAlert];
                break;
            case AAPLAlertControllerAlertRowOkayCancel:
                [self showOkayCancelAlert];
                break;
            case AAPLAlertControllerAlertRowOther:
                [self showOtherAlert];
                break;
            case AAPLAlertControllerAlertRowTextEntry:
                [self showTextEntryAlert];
                break;
            case AAPLAlertControllerAlertRowTextEntrySecure:
                [self showSecureTextEntryAlert];
                break;
            default:
                break;
        }
    }
    else if (AAPLAlertControllerSectionActionSheet == section) {
        AAPLAlertControllerActionSheetRow row = indexPath.row;

        switch (row) {
            case AAPLAlertControllerActionSheetRowOkayCancel:
                [self showOkayCancelActionSheet:indexPath];
                break;
            case AAPLAlertControllerActionSheetRowOther:
                [self showOtherActionSheet:indexPath];
                break;
            default:
                break;
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
