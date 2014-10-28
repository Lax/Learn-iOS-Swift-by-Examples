/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A view controller that demonstrates how to use UIPickerView.
            
*/

import UIKit

class PickerViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UIPickerViewAccessibilityDelegate {
    // MARK: Types

    enum ColorComponent: Int {
        case Red = 0, Green, Blue
        
        static var count: Int {
            return ColorComponent.Blue.rawValue + 1
        }
    }

    struct RGB {
        static let max: CGFloat = 255.0
        static let min: CGFloat = 0.0
        static let offset: CGFloat = 5.0
    }

    // MARK: Properties

    @IBOutlet weak var pickerView: UIPickerView!
    
    @IBOutlet weak var colorSwatchView: UIView!

    lazy var numberOfColorValuesPerComponent: Int = (Int(RGB.max) / Int(RGB.offset)) + 1

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

        configurePickerView()
    }

    // MARK: Convenience
    
    func updateColorSwatchViewBackgroundColor() {
        colorSwatchView.backgroundColor = UIColor(red: redColor, green: greenColor, blue: blueColor, alpha: 1)
    }

    // MARK: Configuration
    
    func configurePickerView() {
        // Show that a given row is selected. This is off by default.
        pickerView.showsSelectionIndicator = true

        // Set the default selected rows (the desired rows to initially select will vary from app to app).
        let selectedRows: [ColorComponent: Int] = [.Red: 13, .Green: 41, .Blue: 24]

        for (colorComponent, selectedRow) in selectedRows {
            // Note that the delegate method on UIPickerViewDelegate is not triggered when manually
            // calling UIPickerView.selectRow(_:inComponent:animated:). To do this, we fire off delegate
            // method manually.
            pickerView.selectRow(selectedRow, inComponent: colorComponent.rawValue, animated: true)
            pickerView(pickerView, didSelectRow: selectedRow, inComponent: colorComponent.rawValue)
        }
    }

    // MARK: UIPickerViewDataSource

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return ColorComponent.count
    }

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return numberOfColorValuesPerComponent
    }

    // MARK: UIPickerViewDelegate

    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString {
        let colorValue = CGFloat(row) * RGB.offset

        let value = CGFloat(colorValue) / RGB.max
        var redColorComponent = RGB.min
        var greenColorComponent = RGB.min
        var blueColorComponent = RGB.min

        switch ColorComponent(rawValue: component)! {
            case .Red:
                redColorComponent = value
            case .Green:
                greenColorComponent = value
            case .Blue:
                blueColorComponent = value
        }

        let foregroundColor = UIColor(red: redColorComponent, green: greenColorComponent, blue: blueColorComponent, alpha: 1)

        // Set the foreground color for the entire attributed string.
        let attributes = [
            NSForegroundColorAttributeName: foregroundColor
        ]

        let title = NSMutableAttributedString(string: "\(Int(colorValue))", attributes: attributes)

        return title
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let colorComponentValue = RGB.offset * CGFloat(row) / RGB.max

        switch ColorComponent(rawValue: component)! {
            case .Red:
                redColor = colorComponentValue
            case .Green:
                greenColor = colorComponentValue
            case .Blue:
                blueColor = colorComponentValue
        }
    }

    // MARK: UIPickerViewAccessibilityDelegate

    func pickerView(pickerView: UIPickerView, accessibilityLabelForComponent component: Int) -> String {
        switch ColorComponent(rawValue: component)! {
            case .Red:
                return NSLocalizedString("Red color component value", comment: "")
            case .Green:
                return NSLocalizedString("Green color component value", comment: "")
            case .Blue:
                return NSLocalizedString("Blue color component value", comment: "")
        }
    }
}
