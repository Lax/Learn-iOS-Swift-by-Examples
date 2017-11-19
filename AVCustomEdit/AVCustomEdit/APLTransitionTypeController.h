/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 UITableViewController subclass which lets the user select the type of transition for their composition.
 */

#import <UIKit/UIKit.h>

#define kDiagonalWipeTransition  0 
#define kCrossDissolveTransition 1

@protocol APLTransitionTypePickerDelegate;

@interface APLTransitionTypeController : UITableViewController

@property IBOutlet UITableViewCell *diagonalWipeCell;
@property IBOutlet UITableViewCell *crossDissolveCell;

@property NSInteger currentTransition;

@property id <APLTransitionTypePickerDelegate> delegate;

- (IBAction)transitionSelected:(id)sender;

@end

@protocol APLTransitionTypePickerDelegate <NSObject>

- (void)transitionTypeController:(APLTransitionTypeController *)controller didPickTransitionType:(int)transitionType;

@end
