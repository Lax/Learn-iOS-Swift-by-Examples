/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UIViewController subclass that manages a QuartzCapJoinWidthView and a UI to allow for the selection of the line cap, line join and line width to demonstrate.
 */

import UIKit

class QuartzCapJointWidthViewController: UIViewController {


    @IBOutlet weak var quartzCapJoinWidthView: QuartzCapJointWidthView!
    @IBOutlet weak var capSegmentedControl: UISegmentedControl!
    @IBOutlet weak var joinSegmentedControl: UISegmentedControl!
    @IBOutlet weak var lineWidthSlider: UISlider!


    override func viewDidLoad() {
        super.viewDidLoad()

        //self.capSegmentedControl.addTarget(self, action: #selector(QuartzCapJointWidthViewController.takeLineCapFrom(_:)), for:.valueChanged)

        // Do any additional setup after loading the view, typically from a nib.
        quartzCapJoinWidthView.cap = CGLineCap(rawValue: Int32(capSegmentedControl.selectedSegmentIndex))!
        quartzCapJoinWidthView.join = CGLineJoin(rawValue: Int32(joinSegmentedControl.selectedSegmentIndex))!
        quartzCapJoinWidthView.width = CGFloat(lineWidthSlider.value)
    }
    


    @IBAction func takeLineCapFrom(_ sender: UISegmentedControl) {
        quartzCapJoinWidthView.cap = CGLineCap(rawValue: Int32(sender.selectedSegmentIndex))!
    }



    @IBAction func takeLineJoinFrom(_ sender: UISegmentedControl) {
        quartzCapJoinWidthView.join = CGLineJoin(rawValue: Int32(sender.selectedSegmentIndex))!
    }



    @IBAction func takeLineWidthFrom(_ sender: UISlider) {
        quartzCapJoinWidthView.width = CGFloat(sender.value)
    }


}

