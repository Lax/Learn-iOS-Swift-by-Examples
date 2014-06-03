/*
        File: PickerViewController.swift
    Abstract: 
                A view controller that demonstrates how to use UIPickerView.
            
     Version: 1.0
    
    Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
    Inc. ("Apple") in consideration of your agreement to the following
    terms, and your use, installation, modification or redistribution of
    this Apple software constitutes acceptance of these terms.  If you do
    not agree with these terms, please do not use, install, modify or
    redistribute this Apple software.
    
    In consideration of your agreement to abide by the following terms, and
    subject to these terms, Apple grants you a personal, non-exclusive
    license, under Apple's copyrights in this original Apple software (the
    "Apple Software"), to use, reproduce, modify and redistribute the Apple
    Software, with or without modifications, in source and/or binary forms;
    provided that if you redistribute the Apple Software in its entirety and
    without modifications, you must retain this notice and the following
    text and disclaimers in all such redistributions of the Apple Software.
    Neither the name, trademarks, service marks or logos of Apple Inc. may
    be used to endorse or promote products derived from the Apple Software
    without specific prior written permission from Apple.  Except as
    expressly stated in this notice, no other rights or licenses, express or
    implied, are granted by Apple herein, including but not limited to any
    patent rights that may be infringed by your derivative works or by other
    works in which the Apple Software may be incorporated.
    
    The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
    MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
    THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
    OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
    
    IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
    OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
    MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
    AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
    STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
    
    Copyright (C) 2014 Apple Inc. All Rights Reserved.

*/

import UIKit

class PickerViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UIPickerViewAccessibilityDelegate {
    // MARK: Types
    enum ColorComponent: Int {
        case Red = 0, Green, Blue
        
        static var count: Int {
            return ColorComponent.Blue.toRaw() + 1
        }
    }

    struct RGB {
        static let max: CGFloat = 255.0
        static let min: CGFloat = 0.0
        static let offset: CGFloat = 5.0
    }

    // MARK: Properties
    @IBOutlet var pickerView: UIPickerView
    @IBOutlet var colorSwatchView: UIView

    var numberOfColorValuesPerComponent: Int {
        return (Int(RGB.max) / Int(RGB.offset)) + 1
    }

    var redColor: CGFloat = RGB.min {
        didSet {
            updateColorSwatchViewBackgroundColor()
        }
    }

    var greenColor: CGFloat = RGB.min {
        didSet {
            updateColorSwatchViewBackgroundColor()
        }
    }

    var blueColor: CGFloat = RGB.min {
        didSet {
            updateColorSwatchViewBackgroundColor()
        }
    }

    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Show that a given row is selected. This is off by default.
        pickerView.showsSelectionIndicator = true

        configurePickerView()
    }

    // MARK: Convenience
    func updateColorSwatchViewBackgroundColor() {
        colorSwatchView.backgroundColor = UIColor(red: redColor, green: greenColor, blue: blueColor, alpha: 1)
    }

    // MARK: Configuration
    func configurePickerView() {
        // Set the default selected rows (the desired rows to initially select will vary from app to app).
        let selectedRows: Dictionary<ColorComponent, Int> = [.Red: 13, .Green: 41, .Blue: 24]

        for (colorComponent, selectedRow) in selectedRows {
            // Note that the delegate method on UIPickerViewDelegate is not triggered when manually
            // calling UIPickerView.selectRow(:inComponent:animated:). To do this, we fire off delegate
            // method manually.
            pickerView.selectRow(selectedRow, inComponent: colorComponent.toRaw(), animated: true)
            pickerView(pickerView, didSelectRow: selectedRow, inComponent: colorComponent.toRaw())
        }
    }

    // MARK: UIPickerViewDataSource
    func numberOfComponentsInPickerView(UIPickerView) -> Int {
        return ColorComponent.count
    }

    func pickerView(UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return numberOfColorValuesPerComponent
    }

    // MARK: UIPickerViewDelegate
    func pickerView(UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString {
        let colorValue = CGFloat(row) * RGB.offset

        let value = CGFloat(colorValue) / RGB.max
        var redColorComponent = RGB.min
        var greenColorComponent = RGB.min
        var blueColorComponent = RGB.min

        switch ColorComponent.fromRaw(component)! {
            case .Red:
                redColorComponent = value
            case .Green:
                greenColorComponent = value
            case .Blue:
                blueColorComponent = value
            default:
                NSLog("Invalid row/component combination for picker view.")
        }

        let foregroundColor = UIColor(red: redColorComponent, green: greenColorComponent, blue: blueColorComponent, alpha: 1)

        // Set the foreground color for the entire attributed string.
        let attributes = [NSForegroundColorAttributeName: foregroundColor]
        let title = NSMutableAttributedString(string: "\(Int(colorValue))", attributes: attributes)

        return title
    }

    func pickerView(UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let colorComponentValue = RGB.offset * CGFloat(row) / RGB.max

        switch ColorComponent.fromRaw(component)! {
            case .Red:
                redColor = colorComponentValue
            case .Green:
                greenColor = colorComponentValue
            case .Blue:
                blueColor = colorComponentValue
        }
    }

    // MARK: UIPickerViewAccessibilityDelegate
    func pickerView(UIPickerView, accessibilityLabelForComponent component: Int) -> NSString {
        switch ColorComponent.fromRaw(component)! {
            case .Red:
                return NSLocalizedString("Red color component value", comment: "")
            case .Green:
                return NSLocalizedString("Green color component value", comment: "")
            case .Blue:
                return NSLocalizedString("Blue color component value", comment: "")
        }
    }
}
