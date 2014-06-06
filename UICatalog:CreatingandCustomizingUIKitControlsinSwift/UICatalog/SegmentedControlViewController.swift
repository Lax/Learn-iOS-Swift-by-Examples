/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A view controller that demonstrates how to use UISegmentedControl.
            
*/

import UIKit

class SegmentedControlViewController: UITableViewController {
    // MARK: Properties

    @IBOutlet var defaultSegmentedControl: UISegmentedControl
    @IBOutlet var tintedSegmentedControl: UISegmentedControl
    @IBOutlet var customSegmentsSegmentedControl: UISegmentedControl
    @IBOutlet var customBackgroundSegmentedControl: UISegmentedControl

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureDefaultSegmentedControl()
        configureTintedSegmentedControl()
        configureCustomSegmentsSegmentedControl()
        configureCustomBackgroundSegmentedControl()
    }

    // MARK: Configuration

    func configureDefaultSegmentedControl() {
        defaultSegmentedControl.momentary = true

        defaultSegmentedControl.setEnabled(false, forSegmentAtIndex: 0)

        defaultSegmentedControl.addTarget(self, action: "selectedSegmentDidChange:", forControlEvents: .ValueChanged)
    }

    func configureTintedSegmentedControl() {
        tintedSegmentedControl.tintColor = UIColor.applicationBlueColor()

        tintedSegmentedControl.selectedSegmentIndex = 1

        tintedSegmentedControl.addTarget(self, action: "selectedSegmentDidChange:", forControlEvents: .ValueChanged)
    }

    func configureCustomSegmentsSegmentedControl() {
        let imageToAccessibilityLabelMappings = [
            "checkmark_icon": NSLocalizedString("Done", comment: ""),
            "search_icon": NSLocalizedString("Search", comment: ""),
            "tools_icon": NSLocalizedString("Settings", comment: "")
        ]

        // Guarantee that the segments show up in the same order.
        let sortedSegmentImageNames = Array(imageToAccessibilityLabelMappings.keys)
        sort(sortedSegmentImageNames) { lhs, rhs in
            return lhs.localizedCaseInsensitiveCompare(rhs) == NSComparisonResult.OrderedAscending
        }

        for (idx, segmentImageName) in enumerate(sortedSegmentImageNames) {
            let image = UIImage(named: segmentImageName)

            image.accessibilityLabel = imageToAccessibilityLabelMappings[segmentImageName]

            customSegmentsSegmentedControl.setImage(image, forSegmentAtIndex: idx)
        }

        customSegmentsSegmentedControl.selectedSegmentIndex = 0

        customSegmentsSegmentedControl.addTarget(self, action: "selectedSegmentDidChange:", forControlEvents: .ValueChanged)
    }


    func configureCustomBackgroundSegmentedControl() {
        customBackgroundSegmentedControl.selectedSegmentIndex = 2

        customBackgroundSegmentedControl.setBackgroundImage(UIImage(named: "stepper_and_segment_background"), forState: .Normal, barMetrics: .Default)

        customBackgroundSegmentedControl.setBackgroundImage(UIImage(named: "stepper_and_segment_background_disabled"), forState: .Disabled, barMetrics: .Default)

        customBackgroundSegmentedControl.setBackgroundImage(UIImage(named: "stepper_and_segment_background_highlighted"), forState: .Highlighted, barMetrics: .Default)

        customBackgroundSegmentedControl.setDividerImage(UIImage(named: "stepper_and_segment_divider"), forLeftSegmentState: .Normal, rightSegmentState: .Normal, barMetrics: .Default)

        let captionFontDescriptor = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleCaption1)
        let font = UIFont(descriptor: captionFontDescriptor, size: 0)

        let normalTextAttributes = [NSForegroundColorAttributeName: UIColor.applicationPurpleColor(), NSFontAttributeName: font]
        customBackgroundSegmentedControl.setTitleTextAttributes(normalTextAttributes, forState: .Normal)

        let highlightedTextAttributes = [NSForegroundColorAttributeName: UIColor.applicationGreenColor(), NSFontAttributeName: font]
        customBackgroundSegmentedControl.setTitleTextAttributes(highlightedTextAttributes, forState: .Highlighted)

        customBackgroundSegmentedControl.addTarget(self, action: "selectedSegmentDidChange:", forControlEvents: .ValueChanged)
    }

    // MARK: Actions

    func selectedSegmentDidChange(segmentedControl: UISegmentedControl) {
        NSLog("The selected segment changed for: \(segmentedControl).")
    }
}
