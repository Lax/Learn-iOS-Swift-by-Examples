/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 UITableViewController subclass which lets the user select the type of transition for their composition.
 */

import UIKit
import Foundation

protocol APLTransitionTypePickerDelegate: class {
    
    func transitionTypeController(_ controller: APLTransitionTypeController, transitionType: Int)
    func transitionTypeControllerDismiss()
}

/*
 The transition type: diagonal wipe or cross dissolve.
 These values correspond to the underlying UITableViewCell.tag values in the "Set Transition" Table View in
 the Storyboard.
 */
enum TransitionType: Int {
    case diagonalWipe = 0
    case crossDissolve = 1
}

class APLTransitionTypeController: UITableViewController {

    /// UITableViewCell corresponding to the diagonal wipe transition selection.
    @IBOutlet var diagonalWipeCell: UITableViewCell!
    /// UITableViewCell corresponding to the cross disslove transition selection.
    @IBOutlet var crossDissolveCell: UITableViewCell!

    /// Currently selected transition.
    var currentTransition: Int

    /// The APLTransitionTypePickerDelegate that will respond to user interaction events.
    weak var delegate: APLTransitionTypePickerDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        currentTransition = TransitionType.diagonalWipe.rawValue

        super.init(coder: aDecoder)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let selectedCell = tableView.cellForRow(at: indexPath) else { return }
        selectedCell.accessoryType = .checkmark
        
        guard let transitionTypeControllerDelegate = self.delegate else { return }

        switch selectedCell.tag {
                
            case TransitionType.diagonalWipe.rawValue:
                if let crossDissolveCell = self.crossDissolveCell {
                    crossDissolveCell.accessoryType = .none
                }
                
                transitionTypeControllerDelegate.transitionTypeController(self, transitionType: TransitionType.diagonalWipe.rawValue)

                self.currentTransition = TransitionType.diagonalWipe.rawValue

            case TransitionType.crossDissolve.rawValue:
                if let diagonalWipeCell = self.diagonalWipeCell {
                    diagonalWipeCell.accessoryType = .none
                }
                
                transitionTypeControllerDelegate.transitionTypeController(self, transitionType: TransitionType.crossDissolve.rawValue)

                self.currentTransition = TransitionType.crossDissolve.rawValue

            default:
                print("A supported transition type was not selected.")
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func transitionSelected() {
        guard let transitionTypeControllerDelegate = self.delegate else { return }

        transitionTypeControllerDelegate.transitionTypeControllerDismiss()
    }
}

