/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to use UISegmentedControl.
*/

import UIKit

class SegmentedControlViewController: UITableViewController {
    // MARK: Properties

    @IBOutlet weak var defaultSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var tintedSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var customSegmentsSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var customBackgroundSegmentedControl: UISegmentedControl!

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
        var sortedSegmentImageNames = Array(imageToAccessibilityLabelMappings.keys)
        sortedSegmentImageNames.sort { lhs, rhs in
            return lhs.localizedStandardCompare(rhs) == NSComparisonResult.OrderedAscending
        }

        for (idx, segmentImageName) in enumerate(sortedSegmentImageNames) {
            let image = UIImage(named: segmentImageName)!

            image.accessibilityLabel = imageToAccessibilityLabelMappings[segmentImageName]

            customSegmentsSegmentedControl.setImage(image, forSegmentAtIndex: idx)
        }

        customSegmentsSegmentedControl.selectedSegmentIndex = 0

        customSegmentsSegmentedControl.addTarget(self, action: "selectedSegmentDidChange:", forControlEvents: .ValueChanged)
    }


    func configureCustomBackgroundSegmentedControl() {
        customBackgroundSegmentedControl.selectedSegmentIndex = 2

        // Set the background images for each control state.
        let normalSegmentBackgroundImage = UIImage(named: "stepper_and_segment_background")
        customBackgroundSegmentedControl.setBackgroundImage(normalSegmentBackgroundImage, forState: .Normal, barMetrics: .Default)

        let disabledSegmentBackgroundImage = UIImage(named: "stepper_and_segment_background_disabled")
        customBackgroundSegmentedControl.setBackgroundImage(disabledSegmentBackgroundImage, forState: .Disabled, barMetrics: .Default)

        let highlightedSegmentBackgroundImage = UIImage(named: "stepper_and_segment_background_highlighted")
        customBackgroundSegmentedControl.setBackgroundImage(highlightedSegmentBackgroundImage, forState: .Highlighted, barMetrics: .Default)

        // Set the divider image.
        let segmentDividerImage = UIImage(named: "stepper_and_segment_divider")
        customBackgroundSegmentedControl.setDividerImage(segmentDividerImage, forLeftSegmentState: .Normal, rightSegmentState: .Normal, barMetrics: .Default)

        // Create a font to use for the attributed title (both normal and highlighted states).
        let captionFontDescriptor = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleCaption1)
        let font = UIFont(descriptor: captionFontDescriptor, size: 0)

        let normalTextAttributes = [
            NSForegroundColorAttributeName: UIColor.applicationPurpleColor(),
            NSFontAttributeName: font
        ]
        customBackgroundSegmentedControl.setTitleTextAttributes(normalTextAttributes, forState: .Normal)

        let highlightedTextAttributes = [
            NSForegroundColorAttributeName: UIColor.applicationGreenColor(),
            NSFontAttributeName: font
        ]
        customBackgroundSegmentedControl.setTitleTextAttributes(highlightedTextAttributes, forState: .Highlighted)

        customBackgroundSegmentedControl.addTarget(self, action: "selectedSegmentDidChange:", forControlEvents: .ValueChanged)
    }

    // MARK: Actions

    func selectedSegmentDidChange(segmentedControl: UISegmentedControl) {
        NSLog("The selected segment changed for: \(segmentedControl).")
    }
}
