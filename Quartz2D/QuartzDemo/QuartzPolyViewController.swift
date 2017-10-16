/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UIViewController subclass that manages a QuartzPolygonView and a UI to allow for the selection of the stroke and fill mode.
 */

import UIKit

class QuartzPolyViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {


    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var quartzPolygonView: QuartzPolygonView!


    // These strings represent the actual drawing mode constants that are 
    // passed to CGContextDrawpath and as such should not be localized in
    // the context of this sample.
    let drawModes = [
        "Fill",         //0
        "EOFill",       //1
        "Stroke",       //2
        "FillStroke",   //3
        "EOFillStroke"  //4
    ]


    override func viewDidLoad() {
        super.viewDidLoad()
        // scrolls to the selected row.
        picker.selectRow(Int(quartzPolygonView.drawingMode.rawValue), inComponent: 0, animated: false)
    }



    // UIPickerViewDelegate & UIPickerViewDataSource methods


    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }



    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return drawModes.count
    }



    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return drawModes[row]
    }



    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        quartzPolygonView.drawingMode = CGPathDrawingMode(rawValue: Int32(picker.selectedRow(inComponent: 0)))!
    }

}









