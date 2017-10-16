/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UIViewController subclass that manages a QuartzPolygonView and a UI to allow for the selection of the stroke and fill mode.
 */

import UIKit



// a class extension to the UIColor class for calculating the luminance for a color.
// -- colors are sorted by luminance in the color picker.
extension UIColor {

    // Calculate the luminance for an arbitrary UIColor instance
    var luminanceForColor: CGFloat {
        get {
            let cgColor: CGColor = self.cgColor
            let components: [CGFloat] = cgColor.components!
            var luminance: CGFloat = 0.0
            switch cgColor.colorSpace!.model {

                case .monochrome:
                    // For grayscale colors, the luminance is the color value
                    luminance = components[0]

                case .rgb:
                    // For RGB colors, we calculate luminance assuming sRGB
                    // Primaries as per https://en.wikipedia.org/wiki/Relative_luminance
                    luminance = 0.2126 * components[0] + 0.7152 * components[1] + 0.0722 * components[2]

                default:
                    // We don't implement support for non-gray, non-rgb colors at this
                    // time. Because our only consumer is colorSortByLuminance, we return
                    // a larger than normal value to ensure that these types of colors are
                    // sorted to the end of the list.
                    luminance = 2.0
            }
            return luminance
        }
    }
}




class QuartzBlendingViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var quartzBlendingView: QuartzBlendingView!

    @IBOutlet weak var picker: UIPickerView!

    // These strings represent the actual blend mode constants that are passed to 
    // CGContextSetBlendMode and so should not be localized in the context of this sample.
    var blendModes = [
        // PDF Blend Modes.
        "Normal",
        "Multiply",
        "Screen",
        "Overlay",
        "Darken",
        "Lighten",
        "ColorDodge",
        "ColorBurn",
        "SoftLight",
        "HardLight",
        "Difference",
        "Exclusion",
        "Hue",
        "Saturation",
        "Color",
        "Luminosity",
        // Porter-Duff Blend Modes.
        "Clear",
        "Copy",
        "SourceIn",
        "SourceOut",
        "SourceAtop",
        "DestinationOver",
        "DestinationIn",
        "DestinationOut",
        "DestinationAtop",
        "XOR",
        "PlusDarker",
        "PlusLighter"
    ]



    var colors: [UIColor] = {
        var colorsDisplayed: [UIColor] = [
            UIColor.red,
            UIColor.green,
            UIColor.blue,
            UIColor.yellow,
            UIColor.magenta,
            UIColor.cyan,
            UIColor.orange,
            UIColor.purple,
            UIColor.brown,
            UIColor.white,
            UIColor.lightGray,
            UIColor.darkGray,
            UIColor.black
        ]
        colorsDisplayed.sort { return $0.luminanceForColor < $1.luminanceForColor }
        return colorsDisplayed
    }()



    override func viewDidLoad() {

        super.viewDidLoad()

        // Setup the view's and picker's default components.
        quartzBlendingView.sourceColor = UIColor.white
        quartzBlendingView.destinationColor = UIColor.black
        quartzBlendingView.blendMode = .normal

        if let index = colors.index(of: quartzBlendingView.destinationColor) {
            picker.selectRow(index, inComponent: 0, animated: false)
        }
        if let index = colors.index(of: quartzBlendingView.sourceColor) {
            picker.selectRow(index, inComponent: 1, animated: false)
        }
        picker.selectRow(Int(quartzBlendingView.blendMode.rawValue), inComponent: 2, animated: false)
    }



    // UIPickerViewDelegate & UIPickerViewDataSource methods



    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }



    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 2 {
            return blendModes.count
        } else {
            return colors.count
        }
    }



    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if component == 2 {
            return 200.0
        } else {
            return 40.0
        }
    }



    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        if component == 2 {
            return NSAttributedString(string: blendModes[row])
        }
        let squareString: String = String(format: "%C", 0x2588) // This is a Unicode character for a simple square block.
        let attributes = [ NSForegroundColorAttributeName : colors[row], NSBackgroundColorAttributeName : UIColor.lightGray ]
        return NSAttributedString(string: squareString, attributes:attributes)
    }



    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        quartzBlendingView.destinationColor = colors[picker.selectedRow(inComponent:0)]
        quartzBlendingView.sourceColor = colors[picker.selectedRow(inComponent:1)]
        quartzBlendingView.blendMode = CGBlendMode(rawValue: Int32(picker.selectedRow(inComponent:2)))!
    }

}









