/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 UITableViewController subclass which lets the user select the type of transition for their composition.
 */

#import "APLTransitionTypeController.h"

@implementation APLTransitionTypeController

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
	[selectedCell setAccessoryType:UITableViewCellAccessoryCheckmark];
	
	switch ([selectedCell tag]) {
		case kDiagonalWipeTransition:{
			[self.crossDissolveCell setAccessoryType:UITableViewCellAccessoryNone];
			[self.delegate transitionTypeController:self didPickTransitionType:kDiagonalWipeTransition];
            self.currentTransition = kDiagonalWipeTransition;
			break;
		}
		case kCrossDissolveTransition:{
			[self.diagonalWipeCell setAccessoryType:UITableViewCellAccessoryNone];
			[self.delegate transitionTypeController:self didPickTransitionType:kCrossDissolveTransition];
            self.currentTransition = kCrossDissolveTransition;
			break;
		}
		default:
			break;
	}

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)transitionSelected:(id)sender
{
    [self.delegate transitionTypeController:self didPickTransitionType:(int)self.currentTransition];
}

@end
