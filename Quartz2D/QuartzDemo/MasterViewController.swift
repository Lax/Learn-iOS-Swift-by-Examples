/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 UITableViewController for the QuartzDemo app.  Adapted from the 'Master-Detail Application' template in Xcode 8.3.2.
 */

import UIKit

class MasterViewController: UITableViewController {

    var objects = [Any]()
    static var first: Bool = true


    override func viewDidLoad() {
        super.viewDidLoad()
        
        // start with the lines view loaded
        if MasterViewController.first {
            performSegue(withIdentifier: "Lines", sender: self)
            MasterViewController.first = false
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)


    }


}

