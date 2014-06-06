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

    func numberOfComponentsInPickerView(_: UIPickerView) -> Int {
        return ColorComponent.count
    }

    func pickerView(_: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return numberOfColorValuesPerComponent
    }

    // MARK: UIPickerViewDelegate

    func pickerView(_: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString {
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

    func pickerView(_: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
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

    func pickerView(_: UIPickerView, accessibilityLabelForComponent component: Int) -> NSString {
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
