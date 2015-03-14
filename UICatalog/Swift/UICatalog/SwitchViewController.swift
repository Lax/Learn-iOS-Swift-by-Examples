/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to use UISwitch.
*/

import UIKit

class SwitchViewController: UITableViewController {
    // MARK: Properties

    @IBOutlet weak var defaultSwitch: UISwitch!
    
    @IBOutlet weak var tintedSwitch: UISwitch!

    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureDefaultSwitch()
        configureTintedSwitch()
    }

    // MARK: Configuration

    func configureDefaultSwitch() {
        defaultSwitch.setOn(true, animated: false)

        defaultSwitch.addTarget(self, action: "switchValueDidChange:", forControlEvents: .ValueChanged)
    }

    func configureTintedSwitch() {
        tintedSwitch.tintColor = UIColor.applicationBlueColor()
        tintedSwitch.onTintColor = UIColor.applicationGreenColor()
        tintedSwitch.thumbTintColor = UIColor.applicationPurpleColor()

        tintedSwitch.addTarget(self, action: "switchValueDidChange:", forControlEvents: .ValueChanged)
    }

    // MARK: Actions

    func switchValueDidChange(aSwitch: UISwitch) {
        NSLog("A switch changed its value: \(aSwitch).")
    }
}
